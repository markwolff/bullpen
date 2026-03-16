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
    @Published public internal(set) var agents: [AgentInfo] = []

    /// All registered log readers
    private let logReaders: [any AgentLogReader]

    /// Active file watchers (one per discovered log file)
    private var watchers: [String: LogWatcher] = [:]

    /// Byte offsets for incremental reading (sessionID -> offset)
    private var readOffsets: [String: UInt64] = [:]

    /// Known session log file paths (sessionID -> URL)
    private var sessionFiles: [String: URL] = [:]

    /// Sessions that have been removed — skip during re-discovery unless log file modified after dismissal
    private var dismissedSessionTimestamps: [String: Date] = [:]

    /// Child session → parent session lookup
    private var childToParentMap: [String: String] = [:]

    /// Parent session → child sessions lookup
    private var parentToChildrenMap: [String: Set<String>] = [:]

    /// How often to scan for new sessions (seconds)
    private let discoveryInterval: TimeInterval

    /// How long before an agent is considered idle (seconds)
    private let idleTimeout: TimeInterval

    /// How long a finished agent stays before removal (seconds)
    private let finishedRemovalTimeout: TimeInterval

    /// How long an idle agent stays before removal (seconds)
    private let idleRemovalTimeout: TimeInterval

    /// How long a deep thinking agent can pace before transitioning to idle (seconds)
    private let deepThinkingTimeout: TimeInterval

    /// Process liveness checker for PID-based deep thinking validation
    private let livenessChecker = ProcessLivenessChecker()

    /// Cached session PID mappings (populated lazily on first deep thinking transition)
    private var sessionPIDs: [String: Int32] = [:]

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

    /// When true, the next discovery pass defers agent creation for existing sessions.
    /// Set by startMonitoring() so that app launch doesn't spawn hundreds of agents
    /// from stale log files — only sessions with post-startup activity become agents.
    private var deferNextDiscovery: Bool = false

    /// Sessions discovered at startup awaiting post-startup activity before agent creation.
    /// Maps session ID → file size at discovery time (read offset starts here).
    private var pendingSessions: [String: UInt64] = [:]

    public init(
        logReaders: [any AgentLogReader]? = nil,
        discoveryInterval: TimeInterval = 10.0,
        idleTimeout: TimeInterval = 30.0,
        finishedRemovalTimeout: TimeInterval = 120.0,
        idleRemovalTimeout: TimeInterval = 120.0,
        deepThinkingTimeout: TimeInterval = 600.0
    ) {
        self.logReaders = logReaders ?? [
            ClaudeCodeLogReader(),
            CodexLogReader(),
        ]
        self.discoveryInterval = discoveryInterval
        self.idleTimeout = idleTimeout
        self.finishedRemovalTimeout = finishedRemovalTimeout
        self.idleRemovalTimeout = idleRemovalTimeout
        self.deepThinkingTimeout = deepThinkingTimeout
    }

    /// Starts monitoring all agent log sources.
    public func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        // Defer agent creation on the first discovery pass so that only
        // sessions with genuine post-startup activity spawn characters.
        deferNextDiscovery = true

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
                self?.checkDeepThinkingTimeouts()
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
        dismissedSessionTimestamps.removeAll()
        childToParentMap.removeAll()
        parentToChildrenMap.removeAll()
        pendingSessions.removeAll()
        sessionPIDs.removeAll()
        deferNextDiscovery = false
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
        let shouldDefer = deferNextDiscovery
        if shouldDefer {
            deferNextDiscovery = false
        }
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
                    // Allow re-discovery if log file was modified after dismissal
                    if let dismissedAt = dismissedSessionTimestamps[sessionID] {
                        let fm = FileManager.default
                        if let attrs = try? fm.attributesOfItem(atPath: fileURL.path),
                           let modDate = attrs[.modificationDate] as? Date,
                           modDate > dismissedAt {
                            dismissedSessionTimestamps.removeValue(forKey: sessionID)
                        } else {
                            continue
                        }
                    }
                    guard agents.count + newSessions.count < maxAgents else {
                        print("Bullpen: Max agents (\(maxAgents)) reached, skipping session \(sessionID)")
                        break
                    }
                    newSessions.append((id: sessionID, url: fileURL))
                }

                for session in newSessions {
                    sessionFiles[session.id] = session.url

                    if shouldDefer {
                        // First discovery pass via startMonitoring(): defer agent creation
                        // until post-startup activity. Record current file size so we only
                        // react to new writes.
                        let attrs = try? FileManager.default.attributesOfItem(atPath: session.url.path)
                        let fileSize = (attrs?[.size] as? UInt64) ?? 0
                        pendingSessions[session.id] = fileSize
                        readOffsets[session.id] = fileSize
                        setupWatcher(for: session.id, fileURL: session.url, reader: reader, skipInitialRead: true)
                    } else {
                        // Normal discovery: create agent immediately
                        readOffsets[session.id] = 0
                        createAgentForSession(sessionID: session.id, fileURL: session.url, reader: reader)
                        setupWatcher(for: session.id, fileURL: session.url, reader: reader)
                    }
                }
            } catch {
                print("Bullpen: Error discovering sessions for \(reader.agentType): \(error)")
            }
        }
    }

    /// Checks all agents for idle timeout and transitions them to .idle or .deepThinking.
    /// Call directly in tests instead of waiting for timers.
    public func checkIdleTimeouts() {
        let now = Date()
        for i in agents.indices {
            let agent = agents[i]
            // Don't transition finished, idle, or deepThinking agents
            guard agent.state != .finished && agent.state != .idle && agent.state != .deepThinking else { continue }
            // Never idle-timeout a parent with active children
            guard !agent.hasActiveChildren else { continue }
            if now.timeIntervalSince(agent.lastUpdatedAt) > idleTimeout {
                if agent.state == .thinking {
                    // Thinking agents enter deep thinking instead of idle
                    agents[i].state = .deepThinking
                    agents[i].stateEnteredAt = now
                    agents[i].lastUpdatedAt = now
                    // Look up and store PID for liveness checking
                    if agents[i].pid == nil && agents[i].agentType == .claudeCode {
                        if sessionPIDs.isEmpty {
                            sessionPIDs = livenessChecker.discoverSessionPIDs()
                        }
                        agents[i].pid = sessionPIDs[agent.id]
                    }
                } else {
                    agents[i].state = .idle
                    agents[i].lastUpdatedAt = now
                }
            }
        }
    }

    /// Checks deep thinking agents for timeout or dead process.
    /// Call directly in tests instead of waiting for timers.
    public func checkDeepThinkingTimeouts() {
        let now = Date()
        for i in agents.indices {
            let agent = agents[i]
            guard agent.state == .deepThinking else { continue }

            // Check PID liveness for Claude Code agents
            if agent.agentType == .claudeCode, let pid = agent.pid {
                if !livenessChecker.isProcessAlive(pid: pid) {
                    agents[i].state = .idle
                    agents[i].lastUpdatedAt = now
                    continue
                }
            }

            // Check deep thinking timeout
            if now.timeIntervalSince(agent.stateEnteredAt) > deepThinkingTimeout {
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

        // Collect IDs to remove first (avoid mutating agents during iteration)
        var idsToRemove: [String] = []
        for agent in agents {
            if agent.state == .error { continue }
            if agent.hasActiveChildren { continue }
            if now.timeIntervalSince(agent.startedAt) < 10.0 { continue }

            if agent.state == .finished,
               now.timeIntervalSince(agent.lastUpdatedAt) > finishedRemovalTimeout {
                idsToRemove.append(agent.id)
            } else if agent.state == .idle,
               now.timeIntervalSince(agent.lastUpdatedAt) > idleRemovalTimeout {
                idsToRemove.append(agent.id)
            }
        }

        // Cleanup and remove
        for id in idsToRemove {
            cleanupAgent(sessionID: id)
        }
        agents.removeAll { idsToRemove.contains($0.id) }
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

        // Register parent-child relationship from activity metadata
        if let parentID = activity.parentSessionID {
            registerParentChild(parentID: parentID, childID: sessionID)
        }

        // After updating a subagent's state, check if its parent should be supervising
        if let parentID = childToParentMap[sessionID],
           let parentIndex = agents.firstIndex(where: { $0.id == parentID }) {
            if agents[parentIndex].hasActiveChildren && agents[parentIndex].state != .supervisingAgents {
                agents[parentIndex].state = .supervisingAgents
                agents[parentIndex].currentTaskDescription = "Supervising..."
                agents[parentIndex].stateEnteredAt = Date()
            }
            // Keep parent alive while children are active
            agents[parentIndex].lastUpdatedAt = Date()
        }

        // Propagate plan mode (sticky: stays true until explicitly false)
        if activity.isPlanMode {
            agents[index].isPlanMode = true
        } else if activity.activityType == .sessionEnd {
            agents[index].isPlanMode = false
        }

        // Dynamically update role title for main agents based on current state.
        // Subagent roles are static (set from meta.json at creation time).
        if !agents[index].isSubagent {
            if agents[index].isPlanMode {
                agents[index].roleTitle = "Planner"
            } else if agents[index].hasActiveChildren {
                agents[index].roleTitle = "Lead"
            } else {
                agents[index].roleTitle = "Developer"
            }
        }

        // 7.7: Accumulate token usage
        agents[index].totalInputTokens += activity.inputTokens
        agents[index].totalOutputTokens += activity.outputTokens

        // Track latest context usage (input tokens = context window size for this API call)
        if activity.inputTokens > 0 {
            agents[index].currentContextTokens = activity.inputTokens
        }

        // 7.8: Track recent tool-use activities (FIFO, most recent first, cap at 5)
        if activity.activityType == .toolUse {
            agents[index].recentTools.insert(activity, at: 0)
            if agents[index].recentTools.count > 5 {
                agents[index].recentTools = Array(agents[index].recentTools.prefix(5))
            }
        }

        if shouldImmediatelyDismiss(activity: activity) {
            cleanupAgent(sessionID: sessionID)
            agents.removeAll { $0.id == sessionID }
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

    private func shouldImmediatelyDismiss(activity: AgentActivity) -> Bool {
        activity.activityType == .sessionEnd && activity.summary.hasPrefix("Rate limited:")
    }

    /// Creates an AgentInfo for a session and appends it to the agents array.
    /// Used for both immediate creation (normal discovery) and deferred
    /// creation (pending sessions promoted by new activity).
    private func createAgentForSession(
        sessionID: String,
        fileURL: URL,
        reader: any AgentLogReader
    ) {
        let traits = CharacterTraits.from(sessionID: sessionID, agentType: reader.agentType)
        let name = Self.generateAgentName(from: sessionID)
        let isSubagent = fileURL.path.contains("/subagents/")

        var parentSessionID: String?
        if isSubagent {
            let subagentsDir = fileURL.deletingLastPathComponent()
            if subagentsDir.lastPathComponent == "subagents" {
                let parentDir = subagentsDir.deletingLastPathComponent()
                parentSessionID = parentDir.lastPathComponent
            }
        }

        // Determine role title: for subagents, read the companion meta.json
        // that Claude Code writes alongside each subagent log. For main agents,
        // default to "Developer" (dynamically updated to "Planner"/"Lead" based on state).
        let roleTitle: String
        if isSubagent {
            roleTitle = Self.readSubagentRole(from: fileURL) ?? "Subagent"
        } else {
            roleTitle = "Developer"
        }

        let agent = AgentInfo(
            id: sessionID,
            name: name,
            agentType: reader.agentType,
            traits: traits,
            state: .idle,
            currentTaskDescription: "Starting up...",
            isSubagent: isSubagent,
            roleTitle: roleTitle,
            parentSessionID: parentSessionID
        )
        agents.append(agent)

        if let parentID = parentSessionID {
            registerParentChild(parentID: parentID, childID: sessionID)
        }
    }

    /// Sets up a file watcher for a specific session log file.
    private func setupWatcher(for sessionID: String, fileURL: URL, reader: any AgentLogReader, skipInitialRead: Bool = false) {
        let watcher = LogWatcher(path: fileURL.path) { [weak self] in
            Task { @MainActor [weak self] in
                await self?.processNewEntries(sessionID: sessionID, fileURL: fileURL, reader: reader)
            }
        }
        watchers[sessionID] = watcher
        watcher.startWatching()

        if !skipInitialRead {
            // Do an initial read
            Task { [weak self] in
                await self?.processNewEntries(sessionID: sessionID, fileURL: fileURL, reader: reader)
            }
        }
    }

    /// Reads new log entries for a session and updates the agent's state.
    private func processNewEntries(
        sessionID: String,
        fileURL: URL,
        reader: any AgentLogReader
    ) async {
        let currentOffset = readOffsets[sessionID] ?? 0
        let isInitialRead = currentOffset == 0

        do {
            let (activities, newOffset) = try await reader.readActivities(
                from: fileURL,
                afterOffset: currentOffset
            )
            readOffsets[sessionID] = newOffset

            // If this is a pending session (deferred at startup), only create
            // the agent when new post-startup activity actually arrives.
            if pendingSessions[sessionID] != nil {
                guard !activities.isEmpty else { return }
                pendingSessions.removeValue(forKey: sessionID)
                createAgentForSession(sessionID: sessionID, fileURL: fileURL, reader: reader)
            }

            // On first read, find first user message for name refinement
            if isInitialRead {
                if let firstUserMsg = activities.first(where: { $0.activityType == .userMessage }) {
                    if let index = agents.firstIndex(where: { $0.id == sessionID }),
                       !agents[index].nameRefined,
                       let rawPayload = firstUserMsg.rawPayload,
                       let taskName = Self.extractTaskName(from: rawPayload) {
                        agents[index].name = taskName
                        agents[index].nameRefined = true
                    }
                }

                // Register parent-child from any activity's metadata
                for activity in activities {
                    if let parentID = activity.parentSessionID {
                        registerParentChild(parentID: parentID, childID: sessionID)
                        break
                    }
                }
            }

            // Update the agent's state based on the latest activity
            if let latestActivity = activities.last {
                updateAgentState(sessionID: sessionID, activity: latestActivity)

                // Fix stale timestamps on initial read: use current time instead of
                // potentially minutes-old log timestamps to prevent immediate removal
                if isInitialRead {
                    if let index = agents.firstIndex(where: { $0.id == sessionID }) {
                        agents[index].lastUpdatedAt = Date()
                    }
                }
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
        dismissedSessionTimestamps[sessionID] = Date()
        watchers[sessionID]?.stopWatching()
        watchers.removeValue(forKey: sessionID)
        readOffsets.removeValue(forKey: sessionID)

        // Remove child from parent's tracking
        if let parentID = childToParentMap[sessionID] {
            parentToChildrenMap[parentID]?.remove(sessionID)
            if let parentIndex = agents.firstIndex(where: { $0.id == parentID }) {
                agents[parentIndex].activeChildSessionIDs.remove(sessionID)
                // If parent has no more children and is supervising, transition back
                if agents[parentIndex].activeChildSessionIDs.isEmpty
                    && agents[parentIndex].state == .supervisingAgents {
                    agents[parentIndex].state = .waitingForInput
                    agents[parentIndex].currentTaskDescription = "Waiting for input"
                    agents[parentIndex].stateEnteredAt = Date()
                    agents[parentIndex].lastUpdatedAt = Date()
                }
            }
            childToParentMap.removeValue(forKey: sessionID)
        }

        // If this agent was a parent, clean up its children map entry
        parentToChildrenMap.removeValue(forKey: sessionID)
    }

    /// Registers a parent-child relationship between sessions.
    private func registerParentChild(parentID: String, childID: String) {
        childToParentMap[childID] = parentID
        parentToChildrenMap[parentID, default: []].insert(childID)

        // Update parent's AgentInfo if it exists
        if let parentIndex = agents.firstIndex(where: { $0.id == parentID }) {
            agents[parentIndex].activeChildSessionIDs.insert(childID)
        }
        // Update child's AgentInfo if it exists
        if let childIndex = agents.firstIndex(where: { $0.id == childID }) {
            agents[childIndex].parentSessionID = parentID
        }
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

    // MARK: - Subagent Role Detection

    /// Reads the companion meta.json file for a subagent log to extract its role.
    ///
    /// Claude Code writes a `agent-<id>.meta.json` alongside each subagent JSONL log
    /// containing `{"agentType": "<type>"}`. The agentType directly indicates the
    /// subagent's role (e.g., "Explore", "test-runner", "code-reviewer", "general-purpose").
    /// We map these raw type strings to human-friendly display titles.
    static func readSubagentRole(from logFileURL: URL) -> String? {
        // Derive meta.json path: agent-<id>.jsonl → agent-<id>.meta.json
        let logName = logFileURL.deletingPathExtension().lastPathComponent
        let metaURL = logFileURL.deletingLastPathComponent()
            .appendingPathComponent("\(logName).meta.json")

        guard let data = try? Data(contentsOf: metaURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let agentType = json["agentType"] as? String
        else {
            return nil
        }

        return mapAgentTypeToTitle(agentType)
    }

    /// Maps a raw Claude Code subagent type string to a clean display title.
    ///
    /// Known agentType values observed in real logs include:
    ///   "Explore", "Plan", "general-purpose", "code-reviewer", "test-runner",
    ///   "feature-dev:code-architect", "feature-dev:code-explorer",
    ///   "codebase-investigator", "simplicity-champion", "product-thinker",
    ///   "validator", "sentry:issue-summarizer", and custom user-defined types.
    ///
    /// The mapping prioritizes well-known types, then falls back to cleaning up
    /// the raw string into a human-readable title.
    static func mapAgentTypeToTitle(_ agentType: String) -> String {
        // Well-known types with curated display names
        switch agentType.lowercased() {
        case "explore":
            return "Explorer"
        case "plan":
            return "Planner"
        case "general-purpose":
            return "Generalist"
        case "code-reviewer", "code-quality-advocate":
            return "Code Reviewer"
        case "test-runner":
            return "Test Runner"
        case "validator":
            return "Validator"
        case "feature-dev:code-architect":
            return "Architect"
        case "feature-dev:code-explorer", "codebase-investigator", "investigator":
            return "Investigator"
        case "simplicity-champion":
            return "Simplifier"
        case "product-thinker":
            return "Product Thinker"
        case "sentry:issue-summarizer":
            return "Issue Analyst"
        default:
            // Fall back to cleaning up the raw type string:
            // "edge-runtime-expert" → "Edge Runtime Expert"
            // "feature-dev:code-reviewer" → "Code Reviewer" (take part after colon)
            let base = agentType.contains(":") ? String(agentType.split(separator: ":").last!) : agentType
            return base.split(separator: "-")
                .map { $0.prefix(1).uppercased() + $0.dropFirst() }
                .joined(separator: " ")
        }
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

    /// Distills a user prompt into a short display name (max 28 chars).
    ///
    /// Strips filler prefixes, title-cases the first few words, and truncates
    /// at word boundaries to avoid ugly mid-word cuts like "Authenticati…".
    /// Also filters out system/meta content (e.g., "[request Interrupted")
    /// that can leak into user message payloads.
    static func shortenPrompt(_ text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Filter out system/meta content that isn't a real user prompt.
        // Claude Code sometimes includes "[request Interrupted..." or similar
        // metadata strings in the message content array.
        if cleaned.hasPrefix("[") || cleaned.hasPrefix("<") {
            return "Task"
        }

        // Strip common filler prefixes so the name leads with the action verb
        let prefixes = [
            "please ", "can you ", "could you ", "i want you to ",
            "i need you to ", "help me ", "let's ", "let's ",
            "i'd like you to ", "go ahead and ", "we need to ", "you should ",
            "i want to ", "we should ", "now ", "ok ", "okay ",
        ]
        let lower = cleaned.lowercased()
        for prefix in prefixes {
            if lower.hasPrefix(prefix) {
                cleaned = String(cleaned.dropFirst(prefix.count))
                break
            }
        }

        // Split into words, filter out noise
        let words = cleaned.split(separator: " ", maxSplits: 6, omittingEmptySubsequences: true)
        guard !words.isEmpty else { return "Task" }

        // Build name from words that fit within the character budget.
        // Truncate at word boundaries to avoid mid-word cuts.
        let maxLength = 28
        var result = ""
        for word in words.prefix(5) {
            let titleWord = word.prefix(1).uppercased() + word.dropFirst().lowercased()
            let candidate = result.isEmpty ? titleWord : "\(result) \(titleWord)"
            if candidate.count > maxLength { break }
            result = candidate
        }

        return result.isEmpty ? "Task" : result
    }
}
