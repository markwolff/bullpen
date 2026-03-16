import Foundation

/// Represents a single AI coding agent that is (or was) active on this machine.
/// This is the primary model consumed by the sprite world to drive character behavior.
public struct AgentInfo: Identifiable, Sendable, Equatable {
    public static func == (lhs: AgentInfo, rhs: AgentInfo) -> Bool {
        lhs.id == rhs.id
            && lhs.state == rhs.state
            && lhs.currentTaskDescription == rhs.currentTaskDescription
            && lhs.isPlanMode == rhs.isPlanMode
            && lhs.isSubagent == rhs.isSubagent
            && lhs.nameRefined == rhs.nameRefined
            && lhs.name == rhs.name
            && lhs.roleTitle == rhs.roleTitle
            && lhs.currentContextTokens == rhs.currentContextTokens
    }

    /// Unique identifier for this agent session (derived from log file or session ID)
    public let id: String

    /// Human-readable name for this agent — starts as project name, refined to task name
    public var name: String

    /// Whether the name has been refined from the first user prompt
    public var nameRefined: Bool = false

    /// What kind of agent this is
    public let agentType: AgentType

    /// Visual traits (hoodie color, skin tone, hair, accessory) derived from session ID
    public let traits: CharacterTraits

    /// The agent's current activity state
    public var state: AgentState

    /// Short description of what the agent is currently doing (e.g., "Editing ContentView.swift")
    public var currentTaskDescription: String

    /// When this agent session started
    public var startedAt: Date

    /// When the agent's state was last updated
    public var lastUpdatedAt: Date

    /// The workspace/project the agent is working in
    public var workspacePath: String?

    /// Total input tokens consumed during this session (7.7)
    public var totalInputTokens: Int = 0

    /// Total output tokens produced during this session (7.7)
    public var totalOutputTokens: Int = 0

    /// Current context window usage in tokens (latest input tokens from most recent API call)
    public var currentContextTokens: Int = 0

    /// Recent tool-use activities, most recent first, capped at 5 (7.8)
    public var recentTools: [AgentActivity] = []

    /// When the agent entered its current state (7.10).
    /// Unlike `lastUpdatedAt` which changes on every activity,
    /// this only changes when the state actually transitions.
    public var stateEnteredAt: Date

    /// Whether this agent is a subagent spawned by another agent session
    public var isSubagent: Bool = false

    /// Display role shown as subtitle beneath the agent's name.
    /// For subagents, derived from the meta.json `agentType` field that Claude Code
    /// writes alongside each subagent log (e.g., "Explore" → "Explorer", "test-runner" → "Test Runner").
    /// For main agents, inferred from state: "Planner" if in plan mode,
    /// "Lead" if supervising subagents, "Developer" otherwise.
    public var roleTitle: String?

    /// Whether this agent is currently in plan mode
    public var isPlanMode: Bool = false

    /// The session ID of the parent agent that spawned this subagent
    public var parentSessionID: String?

    /// The OS process ID for liveness checking (Claude Code only)
    public var pid: Int32? = nil

    /// Session IDs of currently active child subagents
    public var activeChildSessionIDs: Set<String> = []

    /// Whether this agent has any active child subagents
    public var hasActiveChildren: Bool {
        !activeChildSessionIDs.isEmpty
    }

    public init(
        id: String,
        name: String,
        agentType: AgentType,
        traits: CharacterTraits? = nil,
        state: AgentState = .idle,
        currentTaskDescription: String = "",
        startedAt: Date = .now,
        lastUpdatedAt: Date = .now,
        workspacePath: String? = nil,
        stateEnteredAt: Date? = nil,
        isSubagent: Bool = false,
        roleTitle: String? = nil,
        parentSessionID: String? = nil
    ) {
        self.id = id
        self.name = name
        self.agentType = agentType
        self.traits = traits ?? CharacterTraits.from(sessionID: id, agentType: agentType)
        self.state = state
        self.currentTaskDescription = currentTaskDescription
        self.startedAt = startedAt
        self.lastUpdatedAt = lastUpdatedAt
        self.workspacePath = workspacePath
        self.stateEnteredAt = stateEnteredAt ?? startedAt
        self.isSubagent = isSubagent
        self.roleTitle = roleTitle
        self.parentSessionID = parentSessionID
    }
}

/// The type of AI coding agent being monitored.
public enum AgentType: String, Sendable, CaseIterable {
    case claudeCode = "claude_code"
    case codexCLI = "codex_cli"
    // Add more agent types here as needed
}
