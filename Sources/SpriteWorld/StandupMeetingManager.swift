import SpriteKit
import Models

/// Triggers standup meetings at the top of each hour when 2+ agents are active.
/// All agents walk to huddle positions, show emoji bubbles, then return to desks.
@MainActor
public class StandupMeetingManager {

    /// Whether a standup is currently in progress
    public private(set) var isMeeting: Bool = false

    /// The hour of the last meeting (to prevent re-triggering)
    private var lastMeetingHour: Int = -1

    /// Cooldown timer (55 minutes between meetings)
    private var cooldownTimer: TimeInterval = 0
    private let cooldownDuration: TimeInterval = 3300 // 55 minutes

    /// Meeting phase timer
    private var meetingTimer: TimeInterval = 0
    private var meetingDuration: TimeInterval = 0

    /// Agent IDs currently in the standup
    private var meetingAgents: [String] = []

    public init() {}

    /// Call each frame. Returns array of (agentID, huddlePosition) if a standup should start.
    public func update(
        deltaTime: TimeInterval,
        currentHour: Int,
        currentMinute: Int,
        agents: [AgentInfo],
        huddlePositions: [CGPoint]
    ) -> [(agentID: String, position: CGPoint)]? {
        cooldownTimer += deltaTime

        if isMeeting {
            meetingTimer += deltaTime
            if meetingTimer >= meetingDuration {
                endMeeting()
            }
            return nil
        }

        // Trigger at minute 0 of each hour
        guard currentMinute == 0 else { return nil }
        guard currentHour != lastMeetingHour else { return nil }
        guard cooldownTimer >= cooldownDuration else { return nil }

        let activeAgents = agents.filter { agent in
            agent.state != .finished
        }
        guard activeAgents.count >= 2 else { return nil }

        // Start meeting
        isMeeting = true
        lastMeetingHour = currentHour
        cooldownTimer = 0
        meetingTimer = 0
        meetingDuration = TimeInterval.random(in: 10...15)

        var assignments: [(agentID: String, position: CGPoint)] = []
        for (i, agent) in activeAgents.enumerated() {
            let posIndex = i % huddlePositions.count
            assignments.append((agentID: agent.id, position: huddlePositions[posIndex]))
            meetingAgents.append(agent.id)
        }

        return assignments
    }

    /// Ends the current standup meeting.
    public func endMeeting() {
        isMeeting = false
        meetingAgents.removeAll()
        meetingTimer = 0
    }

    /// Whether a specific agent is in the current standup.
    public func isInMeeting(_ agentID: String) -> Bool {
        meetingAgents.contains(agentID)
    }
}
