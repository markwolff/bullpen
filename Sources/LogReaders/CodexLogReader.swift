import Foundation
import Models

/// Reads and parses Codex CLI agent logs.
///
/// Codex CLI is OpenAI's coding agent. This reader discovers and parses
/// its log files to determine agent activity. Codex stores complete JSON
/// session files (not streaming JSONL) in `~/.codex/history/`.
public struct CodexLogReader: AgentLogReader, Sendable {
    public let agentType: AgentType = .codexCLI

    /// Base directory where Codex CLI stores its logs
    private let codexDirectory: URL

    public init(codexDirectory: URL? = nil) {
        self.codexDirectory = codexDirectory
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".codex")
    }

    public func discoverSessions() async throws -> [String: URL] {
        let historyDir = codexDirectory.appendingPathComponent("history")

        guard FileManager.default.fileExists(atPath: historyDir.path) else {
            return [:]
        }

        let contents = try FileManager.default.contentsOfDirectory(
            at: historyDir,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        var sessions: [String: URL] = [:]
        for fileURL in contents {
            guard fileURL.pathExtension == "json" else { continue }
            let sessionID = fileURL.deletingPathExtension().lastPathComponent
            sessions[sessionID] = fileURL
        }

        return sessions
    }

    public func readActivities(
        from logFileURL: URL,
        afterOffset: UInt64
    ) async throws -> (activities: [AgentActivity], newOffset: UInt64) {
        guard FileManager.default.fileExists(atPath: logFileURL.path) else {
            return (activities: [], newOffset: afterOffset)
        }

        let data = try Data(contentsOf: logFileURL)

        guard !data.isEmpty else {
            return (activities: [], newOffset: afterOffset)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return (activities: [], newOffset: afterOffset)
        }

        guard let items = json["items"] as? [[String: Any]] else {
            return (activities: [], newOffset: afterOffset)
        }

        // Derive session ID from filename
        let sessionID = logFileURL.deletingPathExtension().lastPathComponent

        // Parse timestamps from the top-level session object
        let sessionStartDate = parseISO8601(json["startTime"] as? String) ?? Date()

        let skipCount = Int(afterOffset)
        var activities: [AgentActivity] = []

        for (index, item) in items.enumerated() {
            guard index >= skipCount else { continue }

            let itemActivities = parseItem(
                item,
                sessionID: sessionID,
                timestamp: sessionStartDate,
                rawJSON: item
            )
            activities.append(contentsOf: itemActivities)
        }

        let newOffset = UInt64(items.count)
        return (activities: activities, newOffset: newOffset)
    }

    public func parseLogEntry(_ rawEntry: String, sessionID: String) -> AgentActivity? {
        guard let data = rawEntry.data(using: .utf8),
              let item = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }

        let activities = parseItem(item, sessionID: sessionID, timestamp: Date(), rawJSON: item)
        return activities.first
    }

    // MARK: - Private

    /// Parse a single item from the items array, producing one or more activities.
    private func parseItem(
        _ item: [String: Any],
        sessionID: String,
        timestamp: Date,
        rawJSON: [String: Any]
    ) -> [AgentActivity] {
        let role = item["role"] as? String ?? ""

        if role == "user" {
            return [AgentActivity(
                sessionID: sessionID,
                timestamp: timestamp,
                activityType: .userMessage,
                summary: truncate(item["content"] as? String ?? "User message", to: 60),
                rawPayload: serializeJSON(rawJSON)
            )]
        }

        guard role == "assistant" else {
            return []
        }

        guard let functionCalls = item["functionCalls"] as? [[String: Any]],
              !functionCalls.isEmpty
        else {
            // Assistant text without function calls → thinking
            return [AgentActivity(
                sessionID: sessionID,
                timestamp: timestamp,
                activityType: .thinking,
                summary: "Thinking...",
                rawPayload: serializeJSON(rawJSON)
            )]
        }

        // One activity per function call
        var activities: [AgentActivity] = []
        for call in functionCalls {
            let name = call["name"] as? String ?? ""
            let arguments = call["arguments"] as? [String: Any] ?? [:]
            let output = call["output"] as? String ?? ""

            let (activityType, summary) = mapFunctionCall(
                name: name,
                arguments: arguments,
                output: output
            )

            activities.append(AgentActivity(
                sessionID: sessionID,
                timestamp: timestamp,
                activityType: activityType,
                summary: summary,
                rawPayload: serializeJSON(rawJSON)
            ))
        }

        return activities
    }

    /// Map a Codex function call to an activity type and summary string.
    private func mapFunctionCall(
        name: String,
        arguments: [String: Any],
        output: String
    ) -> (ActivityType, String) {
        switch name {
        case "file_read":
            let path = arguments["path"] as? String ?? "unknown"
            return (.toolUse, "Reading \(path)")

        case "file_write":
            let path = arguments["path"] as? String ?? "unknown"
            return (.toolUse, "Writing \(path)")

        case "file_edit":
            let path = arguments["path"] as? String ?? "unknown"
            return (.toolUse, "Editing \(path)")

        case "shell":
            let commandParts: [String]
            if let arr = arguments["command"] as? [String] {
                commandParts = arr
            } else if let str = arguments["command"] as? String {
                commandParts = [str]
            } else {
                commandParts = ["unknown"]
            }
            let commandStr = commandParts.joined(separator: " ")
            let truncatedCommand = truncate(commandStr, to: 40)

            // Detect errors: output containing error indicators or exit code
            let isError = output.contains("exit code: 1")
                || output.contains("[ERROR]")
                || output.contains("FATAL:")

            if isError {
                return (.error, "Running \(truncatedCommand)")
            }
            return (.toolUse, "Running \(truncatedCommand)")

        default:
            return (.toolUse, "\(name)")
        }
    }

    private func truncate(_ string: String, to maxLength: Int) -> String {
        if string.count <= maxLength {
            return string
        }
        return String(string.prefix(maxLength - 1)) + "…"
    }

    private func parseISO8601(_ string: String?) -> Date? {
        guard let string else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }

    private func serializeJSON(_ json: [String: Any]) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: json) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}
