import SpriteKit
import Models

/// Manages pair programming sessions — when 2 agents share the same projectName
/// and both are working, there's a chance the "visitor" walks behind the "host" to observe.
@MainActor
public class PairProgrammingManager {

    /// Whether a pair session is currently happening
    public private(set) var isPairing: Bool = false

    /// Timer for periodic checks
    private var checkTimer: TimeInterval = 0
    private let checkInterval: TimeInterval = 30.0

    /// Current pair session info
    private var currentSession: (visitorID: String, hostID: String)?

    /// Session duration timer
    private var sessionTimer: TimeInterval = 0
    private var sessionDuration: TimeInterval = 0

    public init() {}

    /// Call each frame. Returns a pair request if a new session should start.
    public func update(
        deltaTime: TimeInterval,
        agents: [AgentInfo],
        deskAssignments: [Int: String]
    ) -> (visitorID: String, hostDeskID: Int, observePosition: CGPoint)? {
        if isPairing {
            sessionTimer += deltaTime
            if sessionTimer >= sessionDuration {
                endSession()
            }
            return nil
        }

        checkTimer += deltaTime
        guard checkTimer >= checkInterval else { return nil }
        checkTimer = 0

        // Find pairs of working agents with same projectName
        let workingAgents = agents.filter { agent in
            let isWorking = [AgentState.thinking, .writingCode, .readingFiles, .runningCommand, .searching, .supervisingAgents]
                .contains(agent.state)
            return isWorking && agent.projectName != nil
        }

        // Group by projectName
        let grouped = Dictionary(grouping: workingAgents, by: { $0.projectName! })

        for (_, group) in grouped where group.count >= 2 {
            // 20% chance per eligible group
            guard Double.random(in: 0...1) < 0.2 else { continue }

            let host = group[0]
            let visitor = group[1]

            // Find host's desk
            guard let hostDeskID = deskAssignments.first(where: { $0.value == host.id })?.key else { continue }

            // Find the desk position for the host
            let layout = OfficeLayout.defaultLayout()
            guard let hostDesk = layout.desks.first(where: { $0.id == hostDeskID }) else { continue }

            // Observer stands behind host's chair
            let observePos = CGPoint(x: hostDesk.chairPosition.x, y: hostDesk.chairPosition.y - 20)

            isPairing = true
            currentSession = (visitorID: visitor.id, hostID: host.id)
            sessionTimer = 0
            sessionDuration = TimeInterval.random(in: 15...25)

            return (visitorID: visitor.id, hostDeskID: hostDeskID, observePosition: observePos)
        }

        return nil
    }

    /// Ends the current pairing session.
    public func endSession() {
        isPairing = false
        currentSession = nil
        sessionTimer = 0
    }

    /// Whether a specific agent is the visitor in a pair session.
    public func isVisitor(_ agentID: String) -> Bool {
        currentSession?.visitorID == agentID
    }
}
