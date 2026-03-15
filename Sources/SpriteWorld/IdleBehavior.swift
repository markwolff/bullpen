import SpriteKit
import Models

/// The possible idle activities an agent can perform when not working.
public enum IdleBehavior: CaseIterable, Sendable {
    case waterCooler
    case browseBookshelf
    case checkBulletinBoard
    case lookOutWindow
    case petTheCat
    case whiteboard
    case visitColleague
    case stretchAtDesk
    case waterPlant
    case getCoffee
}

/// Manages idle behavior state machine for a single agent sprite.
/// When the agent goes idle, this manager picks random activities and
/// drives the agent through walk → perform → next decision cycles.
@MainActor
public class IdleBehaviorManager {

    /// Current phase of the idle behavior cycle.
    public enum Phase {
        case atDesk              // Sitting at desk, waiting to start roaming
        case walkingToActivity   // Walking to an activity location
        case performing          // Doing the activity at the location
        case walkingBack         // Returning to desk
    }

    public private(set) var phase: Phase = .atDesk
    public private(set) var currentBehavior: IdleBehavior?

    /// How long the agent has been sitting idle at desk before roaming
    private var deskIdleTimer: TimeInterval = 0

    /// Delay before first roam (5-15 seconds)
    private var deskIdleThreshold: TimeInterval = TimeInterval.random(in: 5...15)

    /// How long the agent has been performing the current activity
    private var performTimer: TimeInterval = 0

    /// How long to perform the current activity (10-30 seconds)
    private var performDuration: TimeInterval = 0

    /// Whether a visual effect has been shown for the current activity
    private var effectShown: Bool = false

    /// Reference to the speech/action bubble node (if any)
    weak var actionBubble: SKNode?

    // MARK: - Public API

    /// Resets the manager when the agent stops being idle.
    public func reset() {
        phase = .atDesk
        currentBehavior = nil
        deskIdleTimer = 0
        deskIdleThreshold = TimeInterval.random(in: 5...15)
        performTimer = 0
        performDuration = 0
        effectShown = false
        actionBubble?.removeFromParent()
        actionBubble = nil
    }

    /// Called each frame while the agent is idle.
    /// Returns an action request if the agent needs to do something.
    public func update(deltaTime: TimeInterval, context: IdleContext) -> IdleAction? {
        switch phase {
        case .atDesk:
            deskIdleTimer += deltaTime
            if deskIdleTimer >= deskIdleThreshold {
                return startActivity(context: context)
            }
            return nil

        case .walkingToActivity:
            // Walking is handled by AgentSprite.walk — we wait for completion callback
            return nil

        case .performing:
            performTimer += deltaTime

            // Show effect once at start of activity
            if !effectShown {
                effectShown = true
                return .showEffect(currentBehavior ?? .stretchAtDesk)
            }

            if performTimer >= performDuration {
                return decideNext(context: context)
            }
            return nil

        case .walkingBack:
            // Walking back is handled by AgentSprite.walk — we wait for completion callback
            return nil
        }
    }

    /// Called when a walk completes (either to activity or back to desk).
    public func walkCompleted() {
        switch phase {
        case .walkingToActivity:
            phase = .performing
            performTimer = 0
            performDuration = TimeInterval.random(in: 10...25)
            effectShown = false

        case .walkingBack:
            phase = .atDesk
            deskIdleTimer = 0
            deskIdleThreshold = TimeInterval.random(in: 8...20)
            currentBehavior = nil
            actionBubble?.removeFromParent()
            actionBubble = nil

        default:
            break
        }
    }

    // MARK: - Private

    private func startActivity(context: IdleContext) -> IdleAction? {
        let behavior = pickBehavior(context: context)
        currentBehavior = behavior

        guard let destination = destinationForBehavior(behavior, context: context) else {
            // Can't find a valid destination, try again later
            deskIdleTimer = 0
            deskIdleThreshold = TimeInterval.random(in: 3...8)
            return nil
        }

        phase = .walkingToActivity
        return .walkTo(destination, behavior: behavior)
    }

    private func decideNext(context: IdleContext) -> IdleAction? {
        actionBubble?.removeFromParent()
        actionBubble = nil

        // 60% chance to do another activity, 40% chance to return to desk
        if Double.random(in: 0...1) < 0.6 {
            return startActivity(context: context)
        } else {
            phase = .walkingBack
            return .walkTo(context.deskChairPosition, behavior: nil)
        }
    }

    private func pickBehavior(context: IdleContext) -> IdleBehavior {
        var candidates = IdleBehavior.allCases

        // Remove petTheCat if no cat position available
        if context.catPosition == nil {
            candidates.removeAll { $0 == .petTheCat }
        }

        // Remove visitColleague if no other idle agents at desks
        if context.otherIdleAgentDeskPositions.isEmpty {
            candidates.removeAll { $0 == .visitColleague }
        }

        // Avoid repeating the same behavior
        if let current = currentBehavior {
            candidates.removeAll { $0 == current }
        }

        return candidates.randomElement() ?? .stretchAtDesk
    }

    private func destinationForBehavior(_ behavior: IdleBehavior, context: IdleContext) -> CGPoint? {
        switch behavior {
        case .waterCooler:
            return context.waterCoolerStandPosition
        case .browseBookshelf:
            return context.bookshelfStandPosition
        case .checkBulletinBoard:
            return context.bulletinBoardStandPosition
        case .lookOutWindow:
            return context.windowStandPosition
        case .petTheCat:
            return context.catPosition
        case .whiteboard:
            return context.whiteboardStandPosition
        case .visitColleague:
            return context.otherIdleAgentDeskPositions.randomElement()
        case .stretchAtDesk:
            // Stand just above the desk chair
            return CGPoint(x: context.deskChairPosition.x, y: context.deskChairPosition.y + 30)
        case .waterPlant:
            return context.plantPositions.randomElement()
        case .getCoffee:
            // Walk to water cooler then back (simplified: just water cooler)
            return context.waterCoolerStandPosition
        }
    }
}

/// Context information passed to the idle behavior manager each frame.
public struct IdleContext {
    public let deskChairPosition: CGPoint
    public let waterCoolerStandPosition: CGPoint
    public let bookshelfStandPosition: CGPoint
    public let bulletinBoardStandPosition: CGPoint
    public let windowStandPosition: CGPoint
    public let whiteboardStandPosition: CGPoint
    public let plantPositions: [CGPoint]
    public let catPosition: CGPoint?
    public let otherIdleAgentDeskPositions: [CGPoint]
}

/// An action the idle behavior manager requests the agent/scene to perform.
public enum IdleAction {
    /// Walk to a destination. If behavior is nil, the agent is returning to desk.
    case walkTo(CGPoint, behavior: IdleBehavior?)
    /// Show a visual effect for the current behavior.
    case showEffect(IdleBehavior)
}
