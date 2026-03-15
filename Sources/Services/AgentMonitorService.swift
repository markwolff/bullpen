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
    private let discoveryInterval: TimeInterval = 10.0

    /// Timer for periodic session discovery
    private var discoveryTimer: Timer?

    public init(
        logReaders: [any AgentLogReader]? = nil
    ) {
        self.logReaders = logReaders ?? [
            ClaudeCodeLogReader(),
            CodexLogReader(),
        ]
    }

    /// Starts monitoring all agent log sources.
    public func startMonitoring() {
        // TODO: Perform initial session discovery
        // TODO: Set up periodic discovery timer to find new sessions
        // TODO: Set up file watchers for discovered log files

        discoveryTimer = Timer.scheduledTimer(
            withTimeInterval: discoveryInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.discoverNewSessions()
            }
        }

        Task {
            await discoverNewSessions()
        }
    }

    /// Stops monitoring and tears down all watchers.
    public func stopMonitoring() {
        discoveryTimer?.invalidate()
        discoveryTimer = nil

        for watcher in watchers.values {
            watcher.stopWatching()
        }
        watchers.removeAll()
    }

    /// Scans for new agent sessions across all log readers.
    private func discoverNewSessions() async {
        for reader in logReaders {
            do {
                let sessions = try await reader.discoverSessions()
                for (sessionID, fileURL) in sessions {
                    guard sessionFiles[sessionID] == nil else { continue }

                    sessionFiles[sessionID] = fileURL
                    readOffsets[sessionID] = 0

                    // Create an AgentInfo for this new session
                    let agent = AgentInfo(
                        id: sessionID,
                        name: "\(reader.agentType == .claudeCode ? "Claude Code" : "Codex CLI")",
                        agentType: reader.agentType,
                        state: .idle,
                        currentTaskDescription: "Starting up..."
                    )
                    agents.append(agent)

                    // Set up a file watcher for this session's log
                    setupWatcher(for: sessionID, fileURL: fileURL, reader: reader)
                }
            } catch {
                // TODO: Surface errors to the UI or log them
                print("Bullpen: Error discovering sessions for \(reader.agentType): \(error)")
            }
        }
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

    /// Updates an agent's state based on a new activity.
    private func updateAgentState(sessionID: String, activity: AgentActivity) {
        guard let index = agents.firstIndex(where: { $0.id == sessionID }) else { return }

        agents[index].state = activity.activityType.correspondingAgentState
        agents[index].currentTaskDescription = activity.summary
        agents[index].lastUpdatedAt = activity.timestamp
    }
}
