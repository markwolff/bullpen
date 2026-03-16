import Foundation

/// Represents the current activity state of an AI coding agent.
/// Each state maps to a different sprite animation/behavior in the office world.
public enum AgentState: String, Sendable, CaseIterable {
    /// Agent is not currently doing anything
    case idle

    /// Agent is analyzing code or thinking about a problem
    case thinking

    /// Agent is writing or editing code
    case writingCode

    /// Agent is reading/reviewing files
    case readingFiles

    /// Agent is executing a shell command
    case runningCommand

    /// Agent is searching through the codebase
    case searching

    /// Agent is waiting for user input
    case waitingForInput

    /// Agent encountered an error
    case error

    /// Agent session has ended
    case finished

    /// Agent is supervising active subagents
    case supervisingAgents

    /// Agent has been thinking for a long time (>30s) — paces the office with 🤔
    case deepThinking

    /// Whether this state represents active work (not idle, finished, or error).
    public var isActive: Bool {
        switch self {
        case .thinking, .writingCode, .readingFiles, .runningCommand, .searching, .supervisingAgents:
            true
        case .idle, .waitingForInput, .error, .finished, .deepThinking:
            false
        }
    }

    /// Human-readable description for display in thought bubbles
    public var displayLabel: String {
        switch self {
        case .idle: "Idle"
        case .thinking: "Thinking..."
        case .writingCode: "Writing code"
        case .readingFiles: "Reading files"
        case .runningCommand: "Running command"
        case .searching: "Searching"
        case .waitingForInput: "Waiting for input"
        case .error: "Error!"
        case .finished: "Done"
        case .supervisingAgents: "Supervising..."
        case .deepThinking: "Deep in thought..."
        }
    }
}
