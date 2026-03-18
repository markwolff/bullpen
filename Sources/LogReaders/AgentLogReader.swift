import Foundation
import Models

/// Protocol that all agent log readers must conform to.
/// Each implementation knows how to find and parse a specific agent's log format.
public protocol AgentLogReader: Sendable {
    /// The type of agent this reader handles
    var agentType: AgentType { get }

    /// Discovers all active (or recent) session log files on this machine.
    /// Returns session IDs mapped to their log file paths.
    func discoverSessions() async throws -> [String: URL]

    /// Reads new log entries from a given session log file, starting after `offset` bytes.
    /// Returns the parsed activities and the new byte offset to resume from.
    func readActivities(from logFileURL: URL, afterOffset: UInt64) async throws -> (activities: [AgentActivity], newOffset: UInt64)

    /// Parses a single raw log line/entry into an AgentActivity, if possible.
    func parseLogEntry(_ rawEntry: String, sessionID: String) -> AgentActivity?
}

// MARK: - Shared Helpers

extension AgentLogReader {

    /// Truncates a string to `maxLength` characters, appending "…" if trimmed.
    func truncate(_ string: String, to maxLength: Int) -> String {
        if string.count <= maxLength { return string }
        return String(string.prefix(maxLength - 1)) + "…"
    }

    /// Builds a summary for a user-message activity.
    /// Uses the actual prompt text (truncated to 60 chars) so the thought bubble
    /// shows what the agent is working on, not just "User message".
    func userMessageSummary(from text: String?) -> String {
        guard let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "User message"
        }
        return truncate(text, to: 60)
    }
}
