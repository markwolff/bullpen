import SpriteKit
import Models

/// Manages water cooler chat events — when 2+ agents are idle for >20s,
/// there's a 30% chance per 10s check that a pair will chat at the water cooler.
@MainActor
public class WaterCoolerChatManager {
    private let nowProvider: @Sendable () -> Date
    private let chanceRollProvider: @Sendable () -> Double
    private let durationProvider: @Sendable () -> TimeInterval
    private let pairOrdering: @Sendable ([AgentInfo]) -> [AgentInfo]

    /// Whether a chat is currently in progress
    public private(set) var isChatting: Bool = false

    /// Timer for periodic checks
    private var checkTimer: TimeInterval = 0
    private let checkInterval: TimeInterval = 10.0

    /// IDs of agents currently chatting
    private var chattingAgents: (String, String)?

    /// Chat duration timer
    private var chatTimer: TimeInterval = 0
    private var chatDuration: TimeInterval = 0

    public init(
        nowProvider: @escaping @Sendable () -> Date = { Date() },
        chanceRollProvider: @escaping @Sendable () -> Double = { Double.random(in: 0...1) },
        durationProvider: @escaping @Sendable () -> TimeInterval = { TimeInterval.random(in: 8...12) },
        pairOrdering: @escaping @Sendable ([AgentInfo]) -> [AgentInfo] = { $0.shuffled() }
    ) {
        self.nowProvider = nowProvider
        self.chanceRollProvider = chanceRollProvider
        self.durationProvider = durationProvider
        self.pairOrdering = pairOrdering
    }

    /// Call each frame. Returns pairs of agent IDs that should start chatting.
    public func update(
        deltaTime: TimeInterval,
        agents: [AgentInfo],
        chatPositions: (left: CGPoint, right: CGPoint)
    ) -> (agentA: String, agentB: String, posA: CGPoint, posB: CGPoint)? {
        if isChatting {
            chatTimer += deltaTime
            if chatTimer >= chatDuration {
                endChat()
            }
            return nil
        }

        checkTimer += deltaTime
        guard checkTimer >= checkInterval else { return nil }
        checkTimer = 0

        // Find idle agents who've been idle >20s
        let longIdleAgents = agents.filter { agent in
            agent.state == .idle && nowProvider().timeIntervalSince(agent.stateEnteredAt) > 20
        }

        guard longIdleAgents.count >= 2 else { return nil }

        // 30% chance
        guard chanceRollProvider() < 0.3 else { return nil }

        // Pick random pair
        let shuffled = pairOrdering(longIdleAgents)
        let agentA = shuffled[0]
        let agentB = shuffled[1]

        isChatting = true
        chattingAgents = (agentA.id, agentB.id)
        chatTimer = 0
        chatDuration = durationProvider()

        return (
            agentA: agentA.id,
            agentB: agentB.id,
            posA: chatPositions.left,
            posB: chatPositions.right
        )
    }

    /// Called when chat ends (timer expired or agents need to leave).
    public func endChat() {
        isChatting = false
        chattingAgents = nil
        chatTimer = 0
    }

    /// Whether a specific agent is currently in a chat.
    public func isAgentChatting(_ agentID: String) -> Bool {
        guard let chatting = chattingAgents else { return false }
        return chatting.0 == agentID || chatting.1 == agentID
    }
}
