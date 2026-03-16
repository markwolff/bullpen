import Foundation

/// A single parsed log entry representing an action taken by an agent.
/// Log readers produce these; the AgentMonitorService consumes them to update AgentInfo.
public struct AgentActivity: Sendable {
    /// The agent session this activity belongs to
    public let sessionID: String

    /// When this activity occurred
    public let timestamp: Date

    /// The type of activity (maps to AgentState)
    public let activityType: ActivityType

    /// Human-readable summary of the activity (e.g., "Read Package.swift", "Ran `swift build`")
    public let summary: String

    /// Optional: the raw log line or JSON payload for debugging
    public let rawPayload: String?

    /// Number of input tokens consumed by this activity (7.7)
    public let inputTokens: Int

    /// Number of output tokens produced by this activity (7.7)
    public let outputTokens: Int

    /// Whether the agent is in plan mode during this activity
    public var isPlanMode: Bool

    public init(
        sessionID: String,
        timestamp: Date,
        activityType: ActivityType,
        summary: String,
        rawPayload: String? = nil,
        inputTokens: Int = 0,
        outputTokens: Int = 0,
        isPlanMode: Bool = false
    ) {
        self.sessionID = sessionID
        self.timestamp = timestamp
        self.activityType = activityType
        self.summary = summary
        self.rawPayload = rawPayload
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.isPlanMode = isPlanMode
    }
}

/// Categorized activity types parsed from log entries.
public enum ActivityType: String, Sendable {
    case toolUse          // Agent used a tool (read, write, bash, etc.)
    case toolResult       // Result came back from a tool
    case assistantMessage // Agent produced a text response
    case userMessage      // User sent a message to the agent
    case thinking         // Agent is in extended thinking
    case error            // Something went wrong
    case sessionStart     // Agent session began
    case sessionEnd       // Agent session ended

    /// Maps this activity type to the corresponding agent display state.
    public var correspondingAgentState: AgentState {
        switch self {
        case .toolUse: .writingCode       // TODO: refine based on tool name
        case .toolResult: .readingFiles   // TODO: refine based on tool name
        case .assistantMessage: .writingCode
        case .userMessage: .waitingForInput
        case .thinking: .thinking
        case .error: .error
        case .sessionStart: .idle
        case .sessionEnd: .finished
        }
    }
}
