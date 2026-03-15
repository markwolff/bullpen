import Foundation
import Models
import LogReaders

/// Central service that monitors all agent log sources and publishes
/// a live list of agent states. This is the bridge between log readers
/// and the sprite world.
@MainActor
public final class AgentMonitorService: ObservableObject {
    /// The current set of known agents and their states.
    /// The sprite world observes this to update character animations.
    @Published public private(set) var agents: [AgentInfo] = []

    /// All registered log readers
    private let logReaders: [any AgentLogReader]

    /// Active file watchers (one per discovered log file)
    private var watchers: [String: LogWatcher] = [:]

    /// Byte offsets for incremental reading (sessionID -> offset)
    private var readOffsets: [String: UInt64] = [:]

    /// Known session log file paths (sessionID -> URL)
    private var sessionFiles: [String: URL] = [:]

    /// How often to scan for new sessions (seconds)
    private let discoveryInterval: TimeInterval

    /// How long before an agent is considered idle (seconds)
    private let idleTimeout: TimeInterval

    /// How long a finished agent stays before removal (seconds)
    private let finishedRemovalTimeout: TimeInterval

    /// How long an idle agent stays before removal (seconds)
    private let idleRemovalTimeout: TimeInterval

    /// Maximum number of simultaneous agents
    private let maxAgents: Int = 8

    /// Counter for sequential agent naming
    private var agentCounter: Int = 0

    /// Timer for periodic session discovery
    private var discoveryTimer: Timer?

    /// Timer for periodic idle/removal checks
    private var idleCheckTimer: Timer?

    public init(
        logReaders: [any AgentLogReader]? = nil,
        discoveryInterval: TimeInterval = 10.0,
        idleTimeout: TimeInterval = 30.0,
        finishedRemovalTimeout: TimeInterval = 120.0,
        idleRemovalTimeout: TimeInterval = 300.0
    ) {
        self.logReaders = logReaders ?? [
            ClaudeCodeLogReader(),
            CodexLogReader(),
        ]
        self.discoveryInterval = discoveryInterval
        self.idleTimeout = idleTimeout
        self.finishedRemovalTimeout = finishedRemovalTimeout
        self.idleRemovalTimeout = idleRemovalTimeout
    }

    /// Starts monitoring all agent log sources.
    public func startMonitoring() {
        // Perform initial discovery immediately
        Task {
            await performDiscovery()
        }

        // Set up periodic discovery timer
        discoveryTimer = Timer.scheduledTimer(
            withTimeInterval: discoveryInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.performDiscovery()
            }
        }

        // Set up periodic idle/removal check timer (every 5 seconds)
        idleCheckTimer = Timer.scheduledTimer(
            withTimeInterval: 5.0,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkIdleTimeouts()
                self?.checkAgentRemoval()
            }
        }
    }

    /// Stops monitoring and tears down all watchers.
    public func stopMonitoring() {
        discoveryTimer?.invalidate()
        discoveryTimer = nil

        idleCheckTimer?.invalidate()
        idleCheckTimer = nil

        for watcher in watchers.values {
            watcher.stopWatching()
        }
        watchers.removeAll()
        agents.removeAll()
        readOffsets.removeAll()
        sessionFiles.removeAll()
    }

    // MARK: - Public methods for testing

    /// Scans for new agent sessions across all log readers.
    /// Call directly in tests instead of waiting for timers.
    public func performDiscovery() async {
        for reader in logReaders {
            do {
                let sessions = try await reader.discoverSessions()
                for (sessionID, fileURL) in sessions {
                    guard sessionFiles[sessionID] == nil else { continue }

                    // Enforce max agents limit
                    guard agents.count < maxAgents else {
                        print("Bullpen: Max agents (\(maxAgents)) reached, skipping session \(sessionID)")
                        return
                    }

                    sessionFiles[sessionID] = fileURL
                    readOffsets[sessionID] = 0

                    // Generate sequential name
                    agentCounter += 1
                    let name = "Agent \(agentCounter)"

                    // Create an AgentInfo for this new session
                    let agent = AgentInfo(
                        id: sessionID,
                        name: name,
                        agentType: reader.agentType,
                        state: .idle,
                        currentTaskDescription: "Starting up..."
                    )
                    agents.append(agent)

                    // Set up a file watcher for this session's log
                    setupWatcher(for: sessionID, fileURL: fileURL, reader: reader)
                }
            } catch {
                print("Bullpen: Error discovering sessions for \(reader.agentType): \(error)")
            }
        }
    }

    /// Checks all agents for idle timeout and transitions them to .idle if needed.
    /// Call directly in tests instead of waiting for timers.
    public func checkIdleTimeouts() {
        let now = Date()
        for i in agents.indices {
            let agent = agents[i]
            // Don't transition finished agents to idle (finished is terminal until new activity)
            guard agent.state != .finished && agent.state != .idle else { continue }
            if now.timeIntervalSince(agent.lastUpdatedAt) > idleTimeout {
                agents[i].state = .idle
                agents[i].lastUpdatedAt = now
            }
        }
    }

    /// Checks agents for removal conditions.
    /// - Finished for finishedRemovalTimeout → remove
    /// - Idle for idleRemovalTimeout → remove
    /// - Error agents are NOT removed (they need attention)
    /// Call directly in tests instead of waiting for timers.
    public func checkAgentRemoval() {
        let now = Date()
        agents.removeAll { agent in
            // Never remove error agents
            if agent.state == .error { return false }

            if agent.state == .finished,
               now.timeIntervalSince(agent.lastUpdatedAt) > finishedRemovalTimeout {
                cleanupAgent(sessionID: agent.id)
                return true
            }

            if agent.state == .idle,
               now.timeIntervalSince(agent.lastUpdatedAt) > idleRemovalTimeout {
                cleanupAgent(sessionID: agent.id)
                return true
            }

            return false
        }
    }

    /// Updates an agent's state based on a new activity.
    /// Exposed for testing.
    public func updateAgentState(sessionID: String, activity: AgentActivity) {
        guard let index = agents.firstIndex(where: { $0.id == sessionID }) else { return }

        let newState = determineState(from: activity)
        agents[index].state = newState
        agents[index].currentTaskDescription = activity.summary
        agents[index].lastUpdatedAt = activity.timestamp
    }

    // MARK: - Private helpers

    /// Determines the correct AgentState from an activity by examining
    /// the summary text for more precise state mapping.
    private func determineState(from activity: AgentActivity) -> AgentState {
        let summary = activity.summary
        let type = activity.activityType

        // Check explicit activity types first
        switch type {
        case .error:
            return .error
        case .sessionEnd:
            return .finished
        case .userMessage:
            return .waitingForInput
        case .thinking:
            return .thinking
        default:
            break
        }

        // Summary-based detection for tool use and other types
        if summary == "Thinking..." {
            return .thinking
        }
        if summary.hasPrefix("Reading") || summary.hasPrefix("Searching for") {
            return .readingFiles
        }
        if summary.hasPrefix("Writing") || summary.hasPrefix("Editing") {
            return .writingCode
        }
        if summary.hasPrefix("Running") {
            return .runningCommand
        }
        if summary.hasPrefix("Searching") || summary.hasPrefix("Fetching") {
            return .searching
        }

        // Default fallback
        return type.correspondingAgentState
    }

    /// Sets up a file watcher for a specific session log file.
    private func setupWatcher(for sessionID: String, fileURL: URL, reader: any AgentLogReader) {
        let watcher = LogWatcher(path: fileURL.path) { [weak self] in
            Task { @MainActor [weak self] in
                await self?.processNewEntries(sessionID: sessionID, fileURL: fileURL, reader: reader)
            }
        }
        watchers[sessionID] = watcher
        watcher.startWatching()

        // Do an initial read
        Task {
            await processNewEntries(sessionID: sessionID, fileURL: fileURL, reader: reader)
        }
    }

    /// Reads new log entries for a session and updates the agent's state.
    private func processNewEntries(
        sessionID: String,
        fileURL: URL,
        reader: any AgentLogReader
    ) async {
        let currentOffset = readOffsets[sessionID] ?? 0

        do {
            let (activities, newOffset) = try await reader.readActivities(
                from: fileURL,
                afterOffset: currentOffset
            )
            readOffsets[sessionID] = newOffset

            // Update the agent's state based on the latest activity
            if let latestActivity = activities.last {
                updateAgentState(sessionID: sessionID, activity: latestActivity)
            }
        } catch {
            print("Bullpen: Error reading log for session \(sessionID): \(error)")
        }
    }

    /// Cleans up watcher and tracking state for a removed agent.
    private func cleanupAgent(sessionID: String) {
        watchers[sessionID]?.stopWatching()
        watchers.removeValue(forKey: sessionID)
        readOffsets.removeValue(forKey: sessionID)
        sessionFiles.removeValue(forKey: sessionID)
    }
}
