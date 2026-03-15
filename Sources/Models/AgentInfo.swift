import Foundation

/// Represents a single AI coding agent that is (or was) active on this machine.
/// This is the primary model consumed by the sprite world to drive character behavior.
public struct AgentInfo: Identifiable, Sendable, Equatable {
    public static func == (lhs: AgentInfo, rhs: AgentInfo) -> Bool {
        lhs.id == rhs.id
    }

    /// Unique identifier for this agent session (derived from log file or session ID)
    public let id: String

    /// Human-readable name for this agent (e.g., "Claude Code #1", "Codex CLI")
    public let name: String

    /// What kind of agent this is
    public let agentType: AgentType

    /// The agent's current activity state
    public var state: AgentState

    /// Short description of what the agent is currently doing (e.g., "Editing ContentView.swift")
    public var currentTaskDescription: String

    /// When this agent session started
    public let startedAt: Date

    /// When the agent's state was last updated
    public var lastUpdatedAt: Date

    /// The workspace/project the agent is working in
    public var workspacePath: String?

    /// Total input tokens consumed during this session (7.7)
    public var totalInputTokens: Int = 0

    /// Total output tokens produced during this session (7.7)
    public var totalOutputTokens: Int = 0

    /// Recent tool-use activities, most recent first, capped at 5 (7.8)
    public var recentTools: [AgentActivity] = []

    /// When the agent entered its current state (7.10).
    /// Unlike `lastUpdatedAt` which changes on every activity,
    /// this only changes when the state actually transitions.
    public var stateEnteredAt: Date

    public init(
        id: String,
        name: String,
        agentType: AgentType,
        state: AgentState = .idle,
        currentTaskDescription: String = "",
        startedAt: Date = .now,
        lastUpdatedAt: Date = .now,
        workspacePath: String? = nil,
        stateEnteredAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.agentType = agentType
        self.state = state
        self.currentTaskDescription = currentTaskDescription
        self.startedAt = startedAt
        self.lastUpdatedAt = lastUpdatedAt
        self.workspacePath = workspacePath
        self.stateEnteredAt = stateEnteredAt ?? startedAt
    }
}

/// The type of AI coding agent being monitored.
public enum AgentType: String, Sendable, CaseIterable {
    case claudeCode = "claude_code"
    case codexCLI = "codex_cli"
    // Add more agent types here as needed
}
