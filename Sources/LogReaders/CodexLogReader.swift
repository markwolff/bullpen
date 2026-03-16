import Foundation
import Models

/// Reads and parses Codex CLI agent logs.
///
/// Codex CLI stores streaming JSONL log files with one JSON object per line.
/// Each entry has a `type` field (`session_meta`, `response_item`, `event_msg`, `turn_context`)
/// and a `payload` containing the actual data.
///
/// Session files are stored in:
/// - Active sessions: `~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl`
/// - Archived sessions: `~/.codex/archived_sessions/rollout-*.jsonl`
public struct CodexLogReader: AgentLogReader, Sendable {
    public let agentType: AgentType = .codexCLI

    /// Base directory where Codex CLI stores its data
    private let codexDirectory: URL

    public init(codexDirectory: URL? = nil) {
        self.codexDirectory = codexDirectory
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".codex")
    }

    public func discoverSessions() async throws -> [String: URL] {
        let fm = FileManager.default

        guard fm.fileExists(atPath: codexDirectory.path) else {
            return [:]
        }

        var sessions: [String: URL] = [:]

        // Scan active sessions: sessions/YYYY/MM/DD/*.jsonl
        let sessionsDir = codexDirectory.appendingPathComponent("sessions")
        if fm.fileExists(atPath: sessionsDir.path) {
            discoverSessionsRecursively(in: sessionsDir, fm: fm, sessions: &sessions)
        }

        // Scan archived sessions: archived_sessions/*.jsonl
        let archivedDir = codexDirectory.appendingPathComponent("archived_sessions")
        if fm.fileExists(atPath: archivedDir.path) {
            discoverSessionFiles(in: archivedDir, fm: fm, sessions: &sessions)
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

        guard let fileHandle = FileHandle(forReadingAtPath: logFileURL.path) else {
            return (activities: [], newOffset: afterOffset)
        }
        defer { fileHandle.closeFile() }

        fileHandle.seek(toFileOffset: afterOffset)
        let data = fileHandle.readDataToEndOfFile()

        guard !data.isEmpty else {
            return (activities: [], newOffset: afterOffset)
        }

        guard let text = String(data: data, encoding: .utf8) else {
            return (activities: [], newOffset: afterOffset)
        }

        // Derive session ID from filename (e.g., "rollout-2026-03-07T11-34-10-UUID" → use UUID part)
        let sessionID = extractSessionID(from: logFileURL)

        var activities: [AgentActivity] = []

        let lines = text.components(separatedBy: "\n")
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }

            if let activity = parseLogEntry(trimmed, sessionID: sessionID) {
                activities.append(activity)
            }
        }

        let newOffset = afterOffset + UInt64(data.count)
        return (activities: activities, newOffset: newOffset)
    }

    public func parseLogEntry(_ rawEntry: String, sessionID: String) -> AgentActivity? {
        guard let data = rawEntry.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String,
              let payload = json["payload"] as? [String: Any]
        else {
            return nil
        }

        let timestamp = parseISO8601(json["timestamp"] as? String) ?? Date()

        switch type {
        case "response_item":
            return parseResponseItem(payload, sessionID: sessionID, timestamp: timestamp, rawEntry: rawEntry)
        case "event_msg":
            return parseEventMsg(payload, sessionID: sessionID, timestamp: timestamp, rawEntry: rawEntry)
        case "session_meta":
            return parseSessionMeta(payload, sessionID: sessionID, timestamp: timestamp, rawEntry: rawEntry)
        default:
            // turn_context, etc. — not actionable activities
            return nil
        }
    }

    // MARK: - Private: Discovery

    /// Recursively discover `.jsonl` files in nested date directories (sessions/YYYY/MM/DD/)
    private func discoverSessionsRecursively(
        in directory: URL,
        fm: FileManager,
        sessions: inout [String: URL]
    ) {
        guard let contents = try? fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        for item in contents {
            var isDir: ObjCBool = false
            if fm.fileExists(atPath: item.path, isDirectory: &isDir), isDir.boolValue {
                discoverSessionsRecursively(in: item, fm: fm, sessions: &sessions)
            } else if item.pathExtension == "jsonl" {
                addSessionIfRecent(fileURL: item, fm: fm, sessions: &sessions)
            }
        }
    }

    /// Discover `.jsonl` files in a flat directory (archived_sessions/)
    private func discoverSessionFiles(
        in directory: URL,
        fm: FileManager,
        sessions: inout [String: URL]
    ) {
        guard let contents = try? fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        for file in contents {
            guard file.pathExtension == "jsonl" else { continue }
            addSessionIfRecent(fileURL: file, fm: fm, sessions: &sessions)
        }
    }

    /// Only include sessions modified in the last 10 minutes
    private func addSessionIfRecent(
        fileURL: URL,
        fm: FileManager,
        sessions: inout [String: URL]
    ) {
        if let attrs = try? fm.attributesOfItem(atPath: fileURL.path),
           let modDate = attrs[.modificationDate] as? Date,
           Date().timeIntervalSince(modDate) > 600 {
            return
        }

        let sessionID = extractSessionID(from: fileURL)
        sessions[sessionID] = fileURL
    }

    /// Extract session ID from filename.
    /// Filenames look like: `rollout-2026-03-07T11-34-10-019cc926-349f-7970-b7ac-17588a0174f0.jsonl`
    /// We use the full filename (without extension) as the session ID for uniqueness.
    private func extractSessionID(from fileURL: URL) -> String {
        fileURL.deletingPathExtension().lastPathComponent
    }

    // MARK: - Private: Parsing

    private func parseResponseItem(
        _ payload: [String: Any],
        sessionID: String,
        timestamp: Date,
        rawEntry: String
    ) -> AgentActivity? {
        guard let itemType = payload["type"] as? String else { return nil }

        switch itemType {
        case "message":
            return parseMessage(payload, sessionID: sessionID, timestamp: timestamp, rawEntry: rawEntry)

        case "function_call":
            return parseFunctionCall(payload, sessionID: sessionID, timestamp: timestamp, rawEntry: rawEntry)

        case "function_call_output":
            return parseFunctionCallOutput(payload, sessionID: sessionID, timestamp: timestamp, rawEntry: rawEntry)

        case "reasoning":
            return AgentActivity(
                sessionID: sessionID,
                timestamp: timestamp,
                activityType: .thinking,
                summary: "Thinking...",
                rawPayload: rawEntry
            )

        default:
            return nil
        }
    }

    private func parseMessage(
        _ payload: [String: Any],
        sessionID: String,
        timestamp: Date,
        rawEntry: String
    ) -> AgentActivity? {
        let role = payload["role"] as? String ?? ""

        if role == "user" {
            // Extract text from content array
            let text = extractTextFromContent(payload["content"])
            return AgentActivity(
                sessionID: sessionID,
                timestamp: timestamp,
                activityType: .userMessage,
                summary: truncate(text.isEmpty ? "User message" : text, to: 60),
                rawPayload: rawEntry
            )
        }

        if role == "assistant" {
            let text = extractTextFromContent(payload["content"])
            return AgentActivity(
                sessionID: sessionID,
                timestamp: timestamp,
                activityType: .assistantMessage,
                summary: truncate(text.isEmpty ? "Codex response" : text, to: 60),
                rawPayload: rawEntry
            )
        }

        // developer, system, etc. — skip
        return nil
    }

    private func parseFunctionCall(
        _ payload: [String: Any],
        sessionID: String,
        timestamp: Date,
        rawEntry: String
    ) -> AgentActivity? {
        let name = payload["name"] as? String ?? "unknown"
        let argsString = payload["arguments"] as? String ?? "{}"

        // Parse the arguments JSON string
        let arguments: [String: Any]
        if let argsData = argsString.data(using: .utf8),
           let parsed = try? JSONSerialization.jsonObject(with: argsData) as? [String: Any] {
            arguments = parsed
        } else {
            arguments = [:]
        }

        let summary = buildToolSummary(name: name, arguments: arguments)

        return AgentActivity(
            sessionID: sessionID,
            timestamp: timestamp,
            activityType: .toolUse,
            summary: summary,
            rawPayload: rawEntry
        )
    }

    private func parseFunctionCallOutput(
        _ payload: [String: Any],
        sessionID: String,
        timestamp: Date,
        rawEntry: String
    ) -> AgentActivity? {
        let output = payload["output"] as? String ?? ""

        // Detect errors from exit code and error patterns
        let isError = output.contains("exit code: 1")
            || output.contains("Process exited with code 1")
            || output.contains("[ERROR]")
            || output.contains("FATAL:")

        if isError {
            // Extract a meaningful error summary
            let errorLine = output.components(separatedBy: "\n")
                .first { $0.contains("[ERROR]") || $0.contains("FATAL:") || $0.contains("exit code:") }
                ?? "Command failed"
            return AgentActivity(
                sessionID: sessionID,
                timestamp: timestamp,
                activityType: .error,
                summary: "Error: \(truncate(errorLine, to: 120))",
                rawPayload: rawEntry
            )
        }

        return AgentActivity(
            sessionID: sessionID,
            timestamp: timestamp,
            activityType: .toolResult,
            summary: "Tool result received",
            rawPayload: rawEntry
        )
    }

    private func parseEventMsg(
        _ payload: [String: Any],
        sessionID: String,
        timestamp: Date,
        rawEntry: String
    ) -> AgentActivity? {
        guard let msgType = payload["type"] as? String else { return nil }

        switch msgType {
        case "task_started":
            return AgentActivity(
                sessionID: sessionID,
                timestamp: timestamp,
                activityType: .sessionStart,
                summary: "Session started",
                rawPayload: rawEntry
            )

        case "task_complete":
            let lastMessage = payload["last_agent_message"] as? String
            let summary = lastMessage.map { truncate($0, to: 80) } ?? "Session completed"
            return AgentActivity(
                sessionID: sessionID,
                timestamp: timestamp,
                activityType: .sessionEnd,
                summary: summary,
                rawPayload: rawEntry
            )

        case "turn_aborted":
            let reason = payload["reason"] as? String ?? "interrupted"
            return AgentActivity(
                sessionID: sessionID,
                timestamp: timestamp,
                activityType: .userMessage,
                summary: "Turn aborted: \(reason)",
                rawPayload: rawEntry
            )

        case "agent_message":
            let phase = payload["phase"] as? String
            if phase == "final_answer" {
                let message = payload["message"] as? String
                let summary = message.map { truncate($0, to: 80) } ?? "Final answer"
                return AgentActivity(
                    sessionID: sessionID,
                    timestamp: timestamp,
                    activityType: .assistantMessage,
                    summary: summary,
                    rawPayload: rawEntry
                )
            }
            // Non-final agent_message events are redundant with response_items
            return nil

        default:
            // user_message, token_count, etc. — skip (redundant with response_items)
            return nil
        }
    }

    private func parseSessionMeta(
        _ payload: [String: Any],
        sessionID: String,
        timestamp: Date,
        rawEntry: String
    ) -> AgentActivity? {
        // Check for subagent metadata in source.subagent.thread_spawn
        guard let source = payload["source"] as? [String: Any],
              let subagent = source["subagent"] as? [String: Any],
              let threadSpawn = subagent["thread_spawn"] as? [String: Any],
              let parentThreadID = threadSpawn["parent_thread_id"] as? String
        else {
            // Regular (non-subagent) session_meta — not actionable
            return nil
        }

        let agentRole = payload["agent_role"] as? String
            ?? threadSpawn["agent_role"] as? String
        let agentNickname = payload["agent_nickname"] as? String
            ?? threadSpawn["agent_nickname"] as? String
        var summary = "Subagent started"
        if let nickname = agentNickname {
            summary = "Subagent \(nickname) started"
            if let role = agentRole {
                summary += " (\(role))"
            }
        } else if let role = agentRole {
            summary = "Subagent started (\(role))"
        }

        return AgentActivity(
            sessionID: sessionID,
            timestamp: timestamp,
            activityType: .sessionStart,
            summary: summary,
            rawPayload: rawEntry,
            parentSessionID: parentThreadID
        )
    }

    // MARK: - Private: Helpers

    private func extractTextFromContent(_ content: Any?) -> String {
        guard let contentArray = content as? [[String: Any]] else { return "" }
        for item in contentArray {
            if let text = item["text"] as? String, !text.isEmpty {
                return text
            }
        }
        return ""
    }

    private func buildToolSummary(name: String, arguments: [String: Any]) -> String {
        switch name {
        case "exec_command":
            let cmd = arguments["cmd"] as? String ?? "unknown"
            return "Running \(truncate(cmd, to: 60))"

        case "spawn_agent":
            let prompt = arguments["prompt"] as? String ?? "subtask"
            return "Spawning agent: \(truncate(prompt, to: 50))"

        case "write_stdin":
            return "Sending input to process"

        case "wait":
            return "Waiting for process"

        case "update_plan":
            return "Updating plan"

        case "close_agent":
            return "Closing agent"

        case "view_image":
            return "Viewing image"

        default:
            // MCP tools: mcp__sentry__search_issues, mcp__serena__read_file, etc.
            if name.hasPrefix("mcp__") {
                let parts = name.split(separator: "__")
                if parts.count >= 3 {
                    let toolName = String(parts.last!)
                    return "Using \(toolName)"
                }
            }
            return "Using \(name)"
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
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }
}
