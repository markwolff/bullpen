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

    /// Sessions that have been removed — skip during re-discovery
    private var dismissedSessions: Set<String> = []

    /// How often to scan for new sessions (seconds)
    private let discoveryInterval: TimeInterval

    /// How long before an agent is considered idle (seconds)
    private let idleTimeout: TimeInterval

    /// How long a finished agent stays before removal (seconds)
    private let finishedRemovalTimeout: TimeInterval

    /// How long an idle agent stays before removal (seconds)
    private let idleRemovalTimeout: TimeInterval

    /// Maximum number of simultaneous agents
    private let maxAgents: Int = 1000

    /// Counter for sequential agent naming
    private var agentCounter: Int = 0

    /// Notification service for agent state change alerts (8.6-8.8)
    public let notificationService = NotificationService()

    /// Whether the app window is currently visible (set externally)
    public var windowVisible: Bool = true

    /// Timer for periodic session discovery
    private var discoveryTimer: Timer?

    /// Timer for periodic idle/removal checks
    private var idleCheckTimer: Timer?

    /// Prevents duplicate timers and overlapping startup work.
    private var isMonitoring: Bool = false

    /// Serializes discovery so overlapping async passes cannot append duplicate agents.
    private var isPerformingDiscovery: Bool = false

    /// Remembers that another discovery pass was requested while one was in flight.
    private var pendingDiscoveryPass: Bool = false

    public init(
        logReaders: [any AgentLogReader]? = nil,
        discoveryInterval: TimeInterval = 10.0,
        idleTimeout: TimeInterval = 30.0,
        finishedRemovalTimeout: TimeInterval = 120.0,
        idleRemovalTimeout: TimeInterval = 120.0
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
        guard !isMonitoring else { return }
        isMonitoring = true

        // Perform initial discovery immediately
        Task { [weak self] in
            await self?.performDiscovery()
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
        isMonitoring = false
        pendingDiscoveryPass = false
        isPerformingDiscovery = false

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
        dismissedSessions.removeAll()
    }

    // MARK: - Public methods for testing

    /// Scans for new agent sessions across all log readers.
    /// Call directly in tests instead of waiting for timers.
    public func performDiscovery() async {
        guard !isPerformingDiscovery else {
            pendingDiscoveryPass = true
            return
        }

        isPerformingDiscovery = true
        defer {
            isPerformingDiscovery = false

            if pendingDiscoveryPass {
                pendingDiscoveryPass = false

                Task { @MainActor [weak self] in
                    await self?.performDiscovery()
                }
            }
        }

        for reader in logReaders {
            do {
                let sessions = try await reader.discoverSessions()
                // Collect new sessions first, then process them
                // (avoids reentrancy issues from Tasks spawned in setupWatcher)
                var newSessions: [(id: String, url: URL)] = []
                for (sessionID, fileURL) in sessions {
                    guard sessionFiles[sessionID] == nil else { continue }
                    guard !dismissedSessions.contains(sessionID) else { continue }
                    guard agents.count + newSessions.count < maxAgents else {
                        print("Bullpen: Max agents (\(maxAgents)) reached, skipping session \(sessionID)")
                        break
                    }
                    newSessions.append((id: sessionID, url: fileURL))
                }

                for session in newSessions {
                    sessionFiles[session.id] = session.url
                    readOffsets[session.id] = 0

                    // Generate traits deterministically from session ID
                    let traits = CharacterTraits.from(sessionID: session.id, agentType: reader.agentType)

                    // Derive project name from file path and generate unique agent name
                    let projectName = Self.extractProjectName(from: session.url)
                    let name = Self.generateAgentName(from: session.id)

                    // Detect subagents by checking if the path contains "/subagents/"
                    let isSubagent = session.url.path.contains("/subagents/")

                    // Create an AgentInfo for this new session
                    let agent = AgentInfo(
                        id: session.id,
                        name: name,
                        agentType: reader.agentType,
                        traits: traits,
                        state: .idle,
                        currentTaskDescription: "Starting up...",
                        isSubagent: isSubagent,
                        projectName: projectName
                    )
                    agents.append(agent)

                    // Set up a file watcher for this session's log
                    setupWatcher(for: session.id, fileURL: session.url, reader: reader)
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

        let oldState = agents[index].state
        let newState = determineState(from: activity)

        agents[index].state = newState
        agents[index].currentTaskDescription = activity.summary
        agents[index].lastUpdatedAt = activity.timestamp

        // Refine name from first user message prompt
        if !agents[index].nameRefined && activity.activityType == .userMessage,
           let rawPayload = activity.rawPayload {
            if let taskName = Self.extractTaskName(from: rawPayload) {
                agents[index].name = taskName
                agents[index].nameRefined = true
            }
        }

        // 7.10: Only update stateEnteredAt when the state actually transitions
        if oldState != newState {
            agents[index].stateEnteredAt = activity.timestamp

            // 8.6-8.7: Send notifications on state transitions
            let agent = agents[index]
            if newState == .finished {
                let service = notificationService
                let visible = windowVisible
                Task {
                    await service.notifyAgentFinished(agent: agent, windowVisible: visible)
                }
            } else if newState == .error {
                let service = notificationService
                let visible = windowVisible
                Task {
                    await service.notifyAgentError(agent: agent, windowVisible: visible)
                }
            }
        }

        // Propagate plan mode (sticky: stays true until explicitly false)
        if activity.isPlanMode {
            agents[index].isPlanMode = true
        } else if activity.activityType == .sessionEnd {
            agents[index].isPlanMode = false
        }

        // 7.7: Accumulate token usage
        agents[index].totalInputTokens += activity.inputTokens
        agents[index].totalOutputTokens += activity.outputTokens

        // 7.8: Track recent tool-use activities (FIFO, most recent first, cap at 5)
        if activity.activityType == .toolUse {
            agents[index].recentTools.insert(activity, at: 0)
            if agents[index].recentTools.count > 5 {
                agents[index].recentTools = Array(agents[index].recentTools.prefix(5))
            }
        }
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
        Task { [weak self] in
            await self?.processNewEntries(sessionID: sessionID, fileURL: fileURL, reader: reader)
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
    /// Note: sessionFiles entry is intentionally retained so that
    /// performDiscovery() won't re-discover this session and cause
    /// the agent sprite to disappear and reappear.
    private func cleanupAgent(sessionID: String) {
        dismissedSessions.insert(sessionID)
        watchers[sessionID]?.stopWatching()
        watchers.removeValue(forKey: sessionID)
        readOffsets.removeValue(forKey: sessionID)
    }

    // MARK: - Smart Naming

    /// Generates a deterministic unique display name from a session ID.
    /// Uses adjective+animal pairs (like Docker container names) for memorable identification.
    static func generateAgentName(from sessionID: String) -> String {
        let adjectives = [
            "Swift", "Bold", "Calm", "Keen", "Sage",
            "Warm", "Cool", "Deft", "Fair", "Glad",
            "Hale", "Just", "Kind", "Live", "Neat",
            "Pure", "Rare", "Safe", "True", "Wise",
        ]
        let animals = [
            "Fox", "Owl", "Elk", "Jay", "Ram",
            "Bee", "Ant", "Cat", "Dog", "Bat",
            "Hen", "Cow", "Emu", "Yak", "Asp",
            "Cod", "Eel", "Gnu", "Koi", "Pug",
        ]

        // Use a simple hash of the session ID for deterministic selection
        var hash: UInt64 = 5381
        for byte in sessionID.utf8 {
            hash = hash &* 33 &+ UInt64(byte)
        }

        let adjIndex = Int(hash % UInt64(adjectives.count))
        let animalIndex = Int((hash / UInt64(adjectives.count)) % UInt64(animals.count))

        return "\(adjectives[adjIndex]) \(animals[animalIndex])"
    }

    /// Extracts a project name from the log file path.
    /// Claude Code logs: ~/.claude/projects/<hash>/<session>.jsonl
    /// We try to decode the project hash directory name, which is a
    /// percent-encoded absolute path. Falls back to a short hash prefix.
    static func extractProjectName(from fileURL: URL) -> String {
        // Walk up from the session file to find the project directory
        let projectDir = fileURL.deletingLastPathComponent()
        let dirName = projectDir.lastPathComponent

        // If this is a "sessions" subdirectory, go up one more
        let effectiveDir: URL
        if dirName == "sessions" {
            effectiveDir = projectDir.deletingLastPathComponent()
        } else {
            effectiveDir = projectDir
        }

        // If we landed on a "subagents" directory, walk up past the
        // session UUID directory to the actual project hash directory.
        let effectiveName = effectiveDir.lastPathComponent
        let resolvedDir: URL
        if effectiveName == "subagents" {
            // subagents → session-uuid → project-hash
            resolvedDir = effectiveDir.deletingLastPathComponent().deletingLastPathComponent()
        } else {
            resolvedDir = effectiveDir
        }

        let encodedName = resolvedDir.lastPathComponent

        // Claude Code encodes the project path as the directory name
        // e.g., "-Users-mark-projects-bullpen-london" → "london"
        // Detect encoded paths (they start with "-")
        let projectName: String
        if encodedName.hasPrefix("-") {
            let parts = encodedName.split(separator: "-").map(String.init)
            projectName = parts.last ?? encodedName
        } else {
            projectName = encodedName
        }

        guard !projectName.isEmpty else { return "Agent" }

        // Capitalize first letter
        return projectName.prefix(1).uppercased() + projectName.dropFirst()
    }

    /// Extracts a short task name from a user message's raw JSON payload.
    /// Parses the user's prompt text and produces a concise label.
    static func extractTaskName(from rawPayload: String) -> String? {
        guard let data = rawPayload.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let message = json["message"] as? [String: Any],
              let content = message["content"] as? [[String: Any]]
        else {
            return nil
        }

        // Find the text content in the user message
        var promptText: String?
        for item in content {
            if (item["type"] as? String) == "text",
               let text = item["text"] as? String {
                promptText = text
                break
            }
        }

        // Also handle content as a plain string
        if promptText == nil, let text = message["content"] as? String {
            promptText = text
        }

        guard let text = promptText, !text.isEmpty else { return nil }

        return shortenPrompt(text)
    }

    /// Distills a user prompt into a short display name (max 25 chars).
    private static func shortenPrompt(_ text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Strip common prefixes
        let prefixes = [
            "please ", "can you ", "could you ", "i want you to ",
            "i need you to ", "help me ", "let's ", "let's ",
            "i'd like you to ", "go ahead and ", "we need to ", "you should ",
        ]
        let lower = cleaned.lowercased()
        for prefix in prefixes {
            if lower.hasPrefix(prefix) {
                cleaned = String(cleaned.dropFirst(prefix.count))
                break
            }
        }

        // Take first few meaningful words
        let words = cleaned.split(separator: " ", maxSplits: 5, omittingEmptySubsequences: true)
        guard !words.isEmpty else { return "Task" }

        // Build name from first 4 words, capitalize each
        let nameWords = words.prefix(4).map { word -> String in
            let w = String(word)
            return w.prefix(1).uppercased() + w.dropFirst().lowercased()
        }

        var result = nameWords.joined(separator: " ")

        // Cap at 25 characters
        if result.count > 25 {
            result = String(result.prefix(25)).trimmingCharacters(in: .whitespaces)
        }

        return result.isEmpty ? "Task" : result
    }
}
