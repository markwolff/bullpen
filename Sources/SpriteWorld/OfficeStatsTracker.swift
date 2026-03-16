import Foundation
import Models

/// Tracks office-wide statistics for the whiteboard overlay.
/// Maintains daily agent count, active count, and rolling activity history.
@MainActor
public class OfficeStatsTracker {

    /// Set of unique agent IDs seen today
    private var agentIDsToday: Set<String> = []

    /// The date when we last reset the daily counter
    private var lastResetDate: Date = Date()

    /// Current active agent count
    public private(set) var activeCount: Int = 0

    /// Rolling activity history (12 slots for 5-minute buckets over last hour)
    public private(set) var activityHistory: [Int] = Array(repeating: 0, count: 12)

    /// Timer for rotating activity buckets
    private var bucketTimer: TimeInterval = 0
    private let bucketInterval: TimeInterval = 300 // 5 minutes

    /// Total unique agents seen today
    public var totalAgentsToday: Int { agentIDsToday.count }

    public init() {}

    /// Call each frame to track stats.
    public func update(deltaTime: TimeInterval, agents: [AgentInfo]) {
        // Reset at midnight
        let calendar = Calendar.current
        if !calendar.isDate(lastResetDate, inSameDayAs: Date()) {
            agentIDsToday.removeAll()
            lastResetDate = Date()
        }

        // Track unique agents
        for agent in agents {
            agentIDsToday.insert(agent.id)
        }

        // Count active
        activeCount = agents.filter { agent in
            agent.state != .idle && agent.state != .finished
        }.count

        // Update activity bucket
        bucketTimer += deltaTime
        if bucketTimer >= bucketInterval {
            bucketTimer = 0
            activityHistory.removeFirst()
            activityHistory.append(activeCount)
        }
    }
}
