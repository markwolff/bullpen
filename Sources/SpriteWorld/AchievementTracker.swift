import Foundation
import Models

/// Tracks and persists achievement unlock state.
/// Evaluates unlock conditions from office stats and agent activity.
@MainActor
public class AchievementTracker {

    /// Persisted unlocked achievements
    public private(set) var unlockedAchievements: Set<Achievement> = []

    /// Total task completions (persisted)
    public private(set) var totalCompletions: Int = 0

    /// Whether an error→non-error transition has been seen
    private var hasSeenErrorRecovery: Bool = false

    /// Previous frame's agent states for transition detection
    private var previousStates: [String: AgentState] = [:]

    /// UserDefaults keys
    private static let unlockedKey = "achievementUnlocked"
    private static let completionsKey = "achievementCompletions"

    public init() {
        loadPersistedState()
    }

    /// Call each frame to evaluate unlock conditions.
    /// Returns newly unlocked achievements this frame.
    public func update(agents: [AgentInfo], maxDesks: Int = 16) -> [Achievement] {
        var newlyUnlocked: [Achievement] = []

        // Detect task completions (transition to .finished)
        for agent in agents {
            if let prevState = previousStates[agent.id], prevState != .finished, agent.state == .finished {
                totalCompletions += 1
                UserDefaults.standard.set(totalCompletions, forKey: Self.completionsKey)
            }

            // Detect error recovery
            if let prevState = previousStates[agent.id], prevState == .error, agent.state != .error {
                hasSeenErrorRecovery = true
            }

            previousStates[agent.id] = agent.state
        }

        // Check unlock conditions
        if !unlockedAchievements.contains(.hundredTasks) && totalCompletions >= 100 {
            newlyUnlocked.append(.hundredTasks)
        }

        if !unlockedAchievements.contains(.firstAllNighter) {
            let hour = Calendar.current.component(.hour, from: Date())
            let hasWorkingAgents = agents.contains { $0.state != .idle && $0.state != .finished }
            if (hour >= 0 && hour < 6) && hasWorkingAgents {
                newlyUnlocked.append(.firstAllNighter)
            }
        }

        if !unlockedAchievements.contains(.fullHouse) && agents.count >= maxDesks {
            newlyUnlocked.append(.fullHouse)
        }

        if !unlockedAchievements.contains(.firstErrorResolved) && hasSeenErrorRecovery {
            newlyUnlocked.append(.firstErrorResolved)
        }

        if !unlockedAchievements.contains(.speedDemon) {
            for agent in agents where agent.state == .finished {
                let duration = agent.lastUpdatedAt.timeIntervalSince(agent.startedAt)
                if duration < 30 {
                    newlyUnlocked.append(.speedDemon)
                    break
                }
            }
        }

        // Persist newly unlocked
        for achievement in newlyUnlocked {
            unlockedAchievements.insert(achievement)
        }
        if !newlyUnlocked.isEmpty {
            persistState()
        }

        return newlyUnlocked
    }

    private func loadPersistedState() {
        totalCompletions = UserDefaults.standard.integer(forKey: Self.completionsKey)

        if let savedArray = UserDefaults.standard.stringArray(forKey: Self.unlockedKey) {
            unlockedAchievements = Set(savedArray.compactMap { Achievement(rawValue: $0) })
        }
    }

    private func persistState() {
        UserDefaults.standard.set(
            Array(unlockedAchievements.map(\.rawValue)),
            forKey: Self.unlockedKey
        )
    }
}
