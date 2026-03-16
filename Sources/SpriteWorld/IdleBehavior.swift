import SpriteKit
import Models

/// The possible idle activities an agent can perform when not working.
public enum IdleBehavior: CaseIterable, Sendable {
    case waterCooler
    case browseBookshelf
    case checkBulletinBoard
    case lookOutWindow
    case petTheCat
    case petTheDog
    case whiteboard
    case waterPlant
    case getCoffee
    case loungeCouch
    case radioArea
    case printerArea
    case fetchWithDog
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

    /// Whether this agent is a subagent (shorter timeouts, leaves after max idle).
    public let isSubagent: Bool

    /// Maximum total idle time before the agent should leave the office.
    /// Subagents leave after 5s; regular agents after 5 minutes.
    public var maxIdleDuration: TimeInterval {
        isSubagent ? 5 : 300
    }

    /// Accumulated total time spent idle (across all phases).
    public private(set) var totalIdleTime: TimeInterval = 0

    public private(set) var phase: Phase = .atDesk
    public private(set) var currentBehavior: IdleBehavior?

    /// How long the agent has been sitting idle at desk before roaming
    private var deskIdleTimer: TimeInterval = 0

    /// Delay before first roam — shorter for subagents
    private var deskIdleThreshold: TimeInterval

    // MARK: - Initialization

    public init(isSubagent: Bool = false) {
        self.isSubagent = isSubagent
        self.deskIdleThreshold = isSubagent
            ? TimeInterval.random(in: 2...4)
            : TimeInterval.random(in: 5...15)
    }

    /// How long the agent has been performing the current activity
    private var performTimer: TimeInterval = 0

    /// How long to perform the current activity (10-30 seconds)
    private var performDuration: TimeInterval = 0

    /// Whether a visual effect has been shown for the current activity
    private var effectShown: Bool = false

    /// The destination this agent is currently walking to or performing at.
    /// Used by other agents to avoid picking the same spot.
    public private(set) var targetDestination: CGPoint?

    /// Reference to the speech/action bubble node (if any)
    weak var actionBubble: SKNode?

    // MARK: - Public API

    /// Resets the manager when the agent stops being idle.
    public func reset() {
        phase = .atDesk
        currentBehavior = nil
        deskIdleTimer = 0
        deskIdleThreshold = isSubagent
            ? TimeInterval.random(in: 2...4)
            : TimeInterval.random(in: 5...15)
        performTimer = 0
        performDuration = 0
        totalIdleTime = 0
        effectShown = false
        targetDestination = nil
        actionBubble?.removeFromParent()
        actionBubble = nil
    }

    /// Called each frame while the agent is idle.
    /// Returns an action request if the agent needs to do something.
    public func update(deltaTime: TimeInterval, context: IdleContext) -> IdleAction? {
        switch phase {
        case .atDesk:
            deskIdleTimer += deltaTime
            totalIdleTime += deltaTime
            if totalIdleTime >= maxIdleDuration {
                return .leaveOffice
            }
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
                return .showEffect(currentBehavior ?? .waterCooler)
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
            // Keep targetDestination set — agent is performing at this spot

        case .walkingBack:
            phase = .atDesk
            deskIdleTimer = 0
            deskIdleThreshold = isSubagent
                ? TimeInterval.random(in: 2...4)
                : TimeInterval.random(in: 8...20)
            currentBehavior = nil
            targetDestination = nil
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
            deskIdleThreshold = TimeInterval.random(in: 2...4)
            return nil
        }

        phase = .walkingToActivity
        targetDestination = destination
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

        // Remove petTheDog and fetchWithDog if no dog position available
        if context.dogPosition == nil {
            candidates.removeAll { $0 == .petTheDog || $0 == .fetchWithDog }
        }

        // Remove loungeCouch if no lounge position available
        if context.loungePosition == nil {
            candidates.removeAll { $0 == .loungeCouch }
        }

        // Remove radioArea if no radio stand position available
        if context.radioStandPosition == nil {
            candidates.removeAll { $0 == .radioArea }
        }

        // Remove printerArea if no printer stand position available
        if context.printerStandPosition == nil {
            candidates.removeAll { $0 == .printerArea }
        }

        // Avoid repeating the same behavior
        if let current = currentBehavior {
            candidates.removeAll { $0 == current }
        }

        // Social distancing: remove destinations where another agent is nearby,
        // heading toward, or already performing at (within 60px)
        let allOccupied = context.otherRoamingAgentPositions + context.occupiedActivityPositions
        candidates = candidates.filter { behavior in
            guard let dest = destinationForBehavior(behavior, context: context) else { return true }
            for otherPos in allOccupied {
                if hypot(dest.x - otherPos.x, dest.y - otherPos.y) < 60 {
                    return false
                }
            }
            return true
        }

        return candidates.randomElement() ?? .waterCooler
    }

    private func destinationForBehavior(_ behavior: IdleBehavior, context: IdleContext) -> CGPoint? {
        let base: CGPoint?
        switch behavior {
        case .waterCooler:
            base = context.waterCoolerStandPosition
        case .browseBookshelf:
            base = context.bookshelfStandPosition
        case .checkBulletinBoard:
            base = context.bulletinBoardStandPosition
        case .lookOutWindow:
            base = context.windowStandPosition
        case .petTheCat:
            base = context.catPosition
        case .petTheDog:
            base = context.dogPosition
        case .whiteboard:
            base = context.whiteboardStandPosition
        case .waterPlant:
            base = context.plantPositions.randomElement()
        case .getCoffee:
            base = context.waterCoolerStandPosition
        case .loungeCouch:
            base = context.loungePosition
        case .radioArea:
            base = context.radioStandPosition
        case .printerArea:
            base = context.printerStandPosition
        case .fetchWithDog:
            base = context.dogPosition
        }

        guard let point = base else { return nil }

        // Offset destination if another agent is already near this spot,
        // walking toward it, or performing there
        let tooClose: CGFloat = 40
        var nearbyCount = 0
        let allOccupied = context.otherRoamingAgentPositions + context.occupiedActivityPositions
        for otherPos in allOccupied {
            if hypot(point.x - otherPos.x, point.y - otherPos.y) < tooClose {
                nearbyCount += 1
            }
        }

        if nearbyCount > 0 {
            // Spread agents horizontally with alternating sides
            let offset = CGFloat(nearbyCount) * 35.0 * (nearbyCount.isMultiple(of: 2) ? 1 : -1)
            return CGPoint(x: point.x + offset, y: point.y)
        }
        return point
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
    public let dogPosition: CGPoint?
    public let otherIdleAgentDeskPositions: [CGPoint]
    public let loungePosition: CGPoint?
    public let radioStandPosition: CGPoint?
    public let printerStandPosition: CGPoint?
    public let otherRoamingAgentPositions: [CGPoint]
    /// Destinations that other agents are walking toward or performing at.
    public let occupiedActivityPositions: [CGPoint]
}

/// An action the idle behavior manager requests the agent/scene to perform.
public enum IdleAction {
    /// Walk to a destination. If behavior is nil, the agent is returning to desk.
    case walkTo(CGPoint, behavior: IdleBehavior?)
    /// Show a visual effect for the current behavior.
    case showEffect(IdleBehavior)
    /// The agent should leave the office (subagent idle timeout).
    case leaveOffice
}
