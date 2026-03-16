import Foundation
import Models

/// Reads and parses Claude Code agent logs from ~/.claude/projects/
///
/// Claude Code writes JSONL log files with one JSON object per line.
/// Each entry has a type field (e.g., "assistant", "user", "result")
/// and contains the message content, timestamps, and session metadata.
public struct ClaudeCodeLogReader: AgentLogReader {
    public let agentType: AgentType = .claudeCode

    /// Base directory where Claude Code stores its logs
    private let claudeDirectory: URL

    public init(claudeDirectory: URL? = nil) {
        self.claudeDirectory = claudeDirectory
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".claude")
    }

    // MARK: - discoverSessions (task 2.1)

    public func discoverSessions() async throws -> [String: URL] {
        var sessions: [String: URL] = [:]

        let projectsDir = claudeDirectory.appendingPathComponent("projects")
        let fm = FileManager.default

        guard fm.fileExists(atPath: projectsDir.path) else {
            return sessions
        }

        // Enumerate projects/<hash>/sessions/<uuid>.jsonl
        let projectContents: [URL]
        do {
            projectContents = try fm.contentsOfDirectory(
                at: projectsDir,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
        } catch {
            return sessions
        }

        for projectDir in projectContents {
            // Claude Code stores session logs in several locations:
            // 1. Directly in project dir: projects/<hash>/<uuid>.jsonl
            // 2. In sessions subdir: projects/<hash>/sessions/<uuid>.jsonl
            // 3. Subagent logs: projects/<hash>/<uuid>/subagents/agent-<id>.jsonl
            var searchDirs: [URL] = [projectDir]
            let sessionsDir = projectDir.appendingPathComponent("sessions")
            if fm.fileExists(atPath: sessionsDir.path) {
                searchDirs.append(sessionsDir)
            }

            // Look for subagent directories inside session directories
            // Structure: projects/<hash>/<session-uuid>/subagents/*.jsonl
            let projectEntries: [URL]
            do {
                projectEntries = try fm.contentsOfDirectory(
                    at: projectDir,
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: [.skipsHiddenFiles]
                )
            } catch {
                projectEntries = []
            }
            for entry in projectEntries {
                var isDir: ObjCBool = false
                if fm.fileExists(atPath: entry.path, isDirectory: &isDir), isDir.boolValue {
                    let subagentsDir = entry.appendingPathComponent("subagents")
                    if fm.fileExists(atPath: subagentsDir.path) {
                        searchDirs.append(subagentsDir)
                    }
                }
            }

            for searchDir in searchDirs {
                let dirFiles: [URL]
                do {
                    dirFiles = try fm.contentsOfDirectory(
                        at: searchDir,
                        includingPropertiesForKeys: [.contentModificationDateKey],
                        options: [.skipsHiddenFiles]
                    )
                } catch {
                    continue
                }

                for file in dirFiles {
                    guard file.pathExtension == "jsonl" else { continue }

                    // Only include recently active sessions (modified in last 2 hours).
                    // Agents in long thinking/LLM calls may not write to logs for
                    // extended periods — a short window here causes active agents
                    // to be dropped from discovery and permanently disappear.
                    if let attrs = try? fm.attributesOfItem(atPath: file.path),
                       let modDate = attrs[.modificationDate] as? Date,
                       Date().timeIntervalSince(modDate) > 7200 {
                        continue
                    }

                    let sessionID = file.deletingPathExtension().lastPathComponent
                    sessions[sessionID] = file
                }
            }
        }

        return sessions
    }

    // MARK: - readActivities (task 2.2)

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

        // Derive session ID from filename
        let sessionID = logFileURL.deletingPathExtension().lastPathComponent

        var activities: [AgentActivity] = []
        var currentOffset = afterOffset

        guard let text = String(data: data, encoding: .utf8) else {
            return (activities: [], newOffset: afterOffset)
        }

        let lines = text.components(separatedBy: "\n")
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            // Calculate byte length of this line including the newline
            let lineByteCount = UInt64(line.utf8.count) + 1 // +1 for newline

            if trimmed.isEmpty {
                currentOffset += lineByteCount
                continue
            }

            if let activity = parseLogEntry(trimmed, sessionID: sessionID) {
                activities.append(activity)
            }
            // Advance offset regardless of parse success (skip bad lines)
            currentOffset += lineByteCount
        }

        // Adjust: the last line may not end with a newline, so use actual data length
        let newOffset = afterOffset + UInt64(data.count)

        return (activities: activities, newOffset: newOffset)
    }

    // MARK: - parseLogEntry (tasks 2.3-2.6)

    public func parseLogEntry(_ rawEntry: String, sessionID: String) -> AgentActivity? {
        guard let data = rawEntry.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String
        else {
            return nil
        }

        let message = json["message"] as? [String: Any]
        let contentArray = message?["content"] as? [[String: Any]]
        let stopReason = message?["stop_reason"] as? String

        // Check for plan mode indicators in content
        let isPlanMode = detectPlanMode(in: contentArray, rawEntry: rawEntry)

        // Parse timestamp
        let timestamp = parseTimestamp(from: json["timestamp"] as? String)

        // Check for error in tool results
        if type == "result" {
            if let content = contentArray {
                for item in content {
                    if item["is_error"] as? Bool == true {
                        let errorContent = item["content"] as? String ?? "Unknown error"
                        let summary = "Error: \(truncate(errorContent, to: 120))"
                        return AgentActivity(
                            sessionID: sessionID,
                            timestamp: timestamp,
                            activityType: .error,
                            summary: summary,
                            rawPayload: rawEntry,
                            isPlanMode: isPlanMode
                        )
                    }
                }
            }
            // Non-error tool result
            return AgentActivity(
                sessionID: sessionID,
                timestamp: timestamp,
                activityType: .toolResult,
                summary: "Tool result received",
                rawPayload: rawEntry,
                isPlanMode: isPlanMode
            )
        }

        // Handle user messages (including tool results, which arrive as type "user")
        if type == "user" {
            // Check if this is a tool_result (tool results come as user messages)
            if let content = contentArray {
                for item in content {
                    if (item["type"] as? String) == "tool_result" {
                        // Check for error in tool result
                        if item["is_error"] as? Bool == true {
                            let errorContent = item["content"] as? String ?? "Unknown error"
                            let summary = "Error: \(truncate(errorContent, to: 120))"
                            return AgentActivity(
                                sessionID: sessionID,
                                timestamp: timestamp,
                                activityType: .error,
                                summary: summary,
                                rawPayload: rawEntry,
                                isPlanMode: isPlanMode
                            )
                        }
                        // Non-error tool result
                        return AgentActivity(
                            sessionID: sessionID,
                            timestamp: timestamp,
                            activityType: .toolResult,
                            summary: "Tool result received",
                            rawPayload: rawEntry,
                            isPlanMode: isPlanMode
                        )
                    }
                }
            }
            return AgentActivity(
                sessionID: sessionID,
                timestamp: timestamp,
                activityType: .userMessage,
                summary: "User message",
                rawPayload: rawEntry,
                isPlanMode: isPlanMode
            )
        }

        // Handle assistant messages
        if type == "assistant" {
            // Check for end_turn → sessionEnd
            if stopReason == "end_turn" {
                // But only if there are no tool_use blocks (pure text end_turn)
                let hasToolUse = contentArray?.contains(where: { ($0["type"] as? String) == "tool_use" }) ?? false
                if !hasToolUse {
                    return AgentActivity(
                        sessionID: sessionID,
                        timestamp: timestamp,
                        activityType: .sessionEnd,
                        summary: "Finished",
                        rawPayload: rawEntry,
                        isPlanMode: isPlanMode
                    )
                }
            }

            // Check for tool_use blocks in content
            if let content = contentArray {
                for item in content {
                    if (item["type"] as? String) == "tool_use" {
                        let toolName = item["name"] as? String ?? "unknown"
                        let toolInput = item["input"] as? [String: Any] ?? [:]
                        let summary = buildToolSummary(toolName: toolName, input: toolInput)
                        return AgentActivity(
                            sessionID: sessionID,
                            timestamp: timestamp,
                            activityType: .toolUse,
                            summary: summary,
                            rawPayload: rawEntry,
                            isPlanMode: isPlanMode
                        )
                    }
                }
            }

            // Text-only assistant message → thinking
            return AgentActivity(
                sessionID: sessionID,
                timestamp: timestamp,
                activityType: .thinking,
                summary: "Thinking...",
                rawPayload: rawEntry,
                isPlanMode: isPlanMode
            )
        }

        // Skip unknown/internal types (e.g. "system") — not meaningful activity
        return nil
    }

    // MARK: - Private helpers

    private func parseTimestamp(from string: String?) -> Date {
        guard let string else { return Date() }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: string) {
            return date
        }
        return Date()
    }

    private func buildToolSummary(toolName: String, input: [String: Any]) -> String {
        switch toolName {
        case "Read":
            let filePath = input["file_path"] as? String ?? "unknown"
            return "Reading \(filePath)"
        case "Glob":
            let pattern = input["pattern"] as? String ?? ""
            return "Searching for '\(pattern)'"
        case "Grep":
            let pattern = input["pattern"] as? String ?? ""
            return "Searching for '\(pattern)'"
        case "Write":
            let filePath = input["file_path"] as? String ?? "unknown"
            return "Writing \(filePath)"
        case "Edit":
            let filePath = input["file_path"] as? String ?? "unknown"
            return "Writing \(filePath)"
        case "Bash":
            let command = input["command"] as? String ?? ""
            return "Running \(truncate(command, to: 80))"
        case "WebSearch":
            let query = input["query"] as? String ?? ""
            return "Searching '\(truncate(query, to: 80))'"
        case "WebFetch":
            let url = input["url"] as? String ?? ""
            return "Fetching \(truncate(url, to: 80))"
        default:
            return "Using \(toolName)"
        }
    }

    private func truncate(_ string: String, to maxLength: Int) -> String {
        if string.count <= maxLength {
            return string
        }
        return String(string.prefix(maxLength)) + "..."
    }

    private func detectPlanMode(in contentArray: [[String: Any]]?, rawEntry: String) -> Bool {
        // Check raw entry for plan mode system reminders
        if rawEntry.contains("Plan mode is active") || rawEntry.contains("Plan mode still active") {
            return true
        }
        // Check content blocks for plan mode text
        if let content = contentArray {
            for item in content {
                if let text = item["text"] as? String,
                   (text.contains("Plan mode is active") || text.contains("Plan mode still active")) {
                    return true
                }
            }
        }
        return false
    }
}
