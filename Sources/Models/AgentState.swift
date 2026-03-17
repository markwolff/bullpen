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

    /// RGB color components (0-1 range) for UI display of this state.
    /// Single source of truth used by SpriteKit (SKColor) and SwiftUI (Color).
    public var displayColorRGB: (red: Double, green: Double, blue: Double) {
        switch self {
        case .idle:              (0.627, 0.627, 0.627) // #A0A0A0
        case .thinking:          (0.941, 0.753, 0.251) // #F0C040
        case .writingCode:       (0.314, 0.784, 0.471) // #50C878
        case .readingFiles:      (0.376, 0.690, 0.816) // #60B0D0
        case .runningCommand:    (0.910, 0.565, 0.251) // #E89040
        case .searching:         (0.690, 0.502, 0.816) // #B080D0
        case .waitingForInput:   (0.376, 0.565, 0.816) // #6090D0
        case .error:             (0.878, 0.314, 0.314) // #E05050
        case .finished:          (0.439, 0.439, 0.439) // #707070
        case .supervisingAgents: (0.251, 0.690, 0.690) // #40B0B0
        case .deepThinking:      (0.910, 0.753, 0.251) // Amber/gold
        }
    }
}
