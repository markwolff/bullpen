import SpriteKit
import Models

/// Manages deep thinking pacing behavior for agents that have been thinking
/// for an extended period. Unlike idle roaming, deep thinking pacing is
/// continuous (no performing phase) — the agent wanders between recreation
/// area waypoints with a 🤔 emoji floating above them.
@MainActor
public class DeepThinkingBehaviorManager {

    /// Current phase of the deep thinking pacing cycle.
    public enum Phase {
        case atDesk          // Not yet pacing
        case walkingToPoint  // Walking to a waypoint
        case pausing         // Brief pause at waypoint before picking next
    }

    /// Actions the scene should perform on behalf of the pacing agent.
    public enum DeepThinkingAction {
        case walkTo(CGPoint)
        case showThinkingEmoji
    }

    public private(set) var phase: Phase = .atDesk
    public private(set) var isPacing: Bool = false
    public private(set) var targetDestination: CGPoint?

    /// Timer for the pause phase
    private var pauseTimer: TimeInterval = 0

    /// How long to pause at a waypoint (2-4 seconds, randomized)
    private var pauseDuration: TimeInterval = 0

    /// The previous waypoint (to avoid picking it again)
    private var lastWaypoint: CGPoint?

    // MARK: - Public API

    /// Starts the pacing cycle. Returns the first action to perform.
    public func startPacing(waypoints: [CGPoint], otherAgentPositions: [CGPoint] = []) -> DeepThinkingAction {
        isPacing = true
        let point = pickWaypoint(from: waypoints, avoiding: lastWaypoint, otherAgents: otherAgentPositions)
        targetDestination = point
        phase = .walkingToPoint
        return .walkTo(point)
    }

    /// Called when the walk to the current waypoint completes.
    public func walkCompleted() {
        guard phase == .walkingToPoint else { return }
        lastWaypoint = targetDestination
        phase = .pausing
        pauseTimer = 0
        pauseDuration = TimeInterval.random(in: 2...4)
    }

    /// Called each frame while pacing. Returns an action if the agent needs to do something.
    public func update(deltaTime: TimeInterval, waypoints: [CGPoint], otherAgentPositions: [CGPoint] = []) -> DeepThinkingAction? {
        switch phase {
        case .atDesk:
            return nil
        case .walkingToPoint:
            return nil
        case .pausing:
            pauseTimer += deltaTime
            if pauseTimer >= pauseDuration {
                let point = pickWaypoint(from: waypoints, avoiding: lastWaypoint, otherAgents: otherAgentPositions)
                targetDestination = point
                phase = .walkingToPoint
                return .walkTo(point)
            }
            return nil
        }
    }

    /// Resets all state, stopping pacing.
    public func reset() {
        phase = .atDesk
        isPacing = false
        targetDestination = nil
        pauseTimer = 0
        pauseDuration = 0
        lastWaypoint = nil
    }

    // MARK: - Private

    /// Picks a random waypoint from the available list, excluding the current
    /// destination and spots too close to other agents.
    private func pickWaypoint(from waypoints: [CGPoint], avoiding current: CGPoint?, otherAgents: [CGPoint]) -> CGPoint {
        var candidates = waypoints

        // Exclude current waypoint
        if let current {
            candidates.removeAll { hypot($0.x - current.x, $0.y - current.y) < 10 }
        }

        // Exclude spots within 60px of other agents
        candidates = candidates.filter { candidate in
            for agentPos in otherAgents {
                if hypot(candidate.x - agentPos.x, candidate.y - agentPos.y) < 60 {
                    return false
                }
            }
            return true
        }

        return candidates.randomElement() ?? waypoints.randomElement() ?? CGPoint(x: 400, y: 300)
    }
}
