import Foundation
import Models

/// Reads and parses Claude Code agent logs from ~/.claude/projects/
///
/// Claude Code writes JSONL log files with one JSON object per line.
/// Each entry has a type field (e.g., "assistant", "user", "tool_use", "tool_result")
/// and contains the message content, timestamps, and session metadata.
public struct ClaudeCodeLogReader: AgentLogReader {
    public let agentType: AgentType = .claudeCode

    /// Base directory where Claude Code stores its logs
    private let claudeDirectory: URL

    public init(claudeDirectory: URL? = nil) {
        self.claudeDirectory = claudeDirectory
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".claude")
    }

    public func discoverSessions() async throws -> [String: URL] {
        // TODO: Scan ~/.claude/projects/ for active JSONL log files
        // Claude Code stores logs under ~/.claude/projects/<project-hash>/
        // Look for recently modified .jsonl files
        let sessions: [String: URL] = [:]

        let projectsDir = claudeDirectory.appendingPathComponent("projects")
        guard FileManager.default.fileExists(atPath: projectsDir.path) else {
            return sessions
        }

        // TODO: Enumerate subdirectories and find .jsonl log files
        // For each log file, derive a session ID from the filename or directory name
        // Filter to only "recent" sessions (e.g., modified in last 24 hours)

        return sessions
    }

    public func readActivities(
        from logFileURL: URL,
        afterOffset: UInt64
    ) async throws -> (activities: [AgentActivity], newOffset: UInt64) {
        // TODO: Open the file, seek to afterOffset, read new lines
        // Parse each line as JSON, convert to AgentActivity
        // Return the new file offset so we can resume next time

        guard FileManager.default.fileExists(atPath: logFileURL.path) else {
            return (activities: [], newOffset: afterOffset)
        }

        let activities: [AgentActivity] = []
        let newOffset = afterOffset

        // TODO: Implement incremental JSONL reading:
        // 1. Open file handle
        // 2. Seek to afterOffset
        // 3. Read line by line
        // 4. Parse each JSON line with parseLogEntry
        // 5. Track byte offset

        return (activities: activities, newOffset: newOffset)
    }

    public func parseLogEntry(_ rawEntry: String, sessionID: String) -> AgentActivity? {
        // TODO: Parse a single JSONL line from Claude Code logs
        // Expected JSON structure (approximate):
        // {
        //   "type": "assistant" | "user" | "tool_use" | "tool_result",
        //   "timestamp": "...",
        //   "message": { ... },
        //   "tool_name": "...",        // for tool_use entries
        //   "tool_input": { ... },     // for tool_use entries
        // }

        guard let data = rawEntry.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String
        else {
            return nil
        }

        let activityType: ActivityType = switch type {
        case "assistant": .assistantMessage
        case "user": .userMessage
        case "tool_use": .toolUse
        case "tool_result": .toolResult
        default: .assistantMessage
        }

        // TODO: Extract timestamp properly from the JSON
        let timestamp = Date()

        // TODO: Build a meaningful summary from the log entry content
        let summary = "Claude Code: \(type)"

        return AgentActivity(
            sessionID: sessionID,
            timestamp: timestamp,
            activityType: activityType,
            summary: summary,
            rawPayload: rawEntry
        )
    }
}
