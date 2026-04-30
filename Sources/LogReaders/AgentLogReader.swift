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
    /// Reads raw file data from the given byte offset, moving larger reads off
    /// the caller's executor so UI-bound services do not stall on long logs.
    func readLogData(
        from fileURL: URL,
        afterOffset: UInt64,
        backgroundReadThreshold: UInt64 = 50_000
    ) async throws -> Data {
        let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path)
        let fileSize = (attrs?[.size] as? UInt64) ?? 0
        let readSize = fileSize > afterOffset ? fileSize - afterOffset : 0

        if readSize > backgroundReadThreshold {
            return try await Task.detached {
                try Self.readFileData(from: fileURL, afterOffset: afterOffset)
            }.value
        }

        return try Self.readFileData(from: fileURL, afterOffset: afterOffset)
    }

    /// Parses common ISO-8601 timestamps emitted by agent runtimes.
    func parseISO8601Timestamp(_ string: String?) -> Date? {
        guard let string else { return nil }
        return LogReaderISO8601.date(from: string)
    }

    /// Returns JSONL records that are safe to consume plus the number of bytes
    /// represented by those records. A trailing non-JSON fragment is left
    /// unread so a live writer can finish it on the next pass.
    func consumableJSONLLines(from data: Data) -> (lines: [String], consumedByteCount: UInt64) {
        guard !data.isEmpty,
              let text = String(data: data, encoding: .utf8) else {
            return ([], 0)
        }

        var lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var consumedByteCount = UInt64(data.count)

        if data.last != UInt8(ascii: "\n"), let trailingLine = lines.last {
            let trimmed = trailingLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if Self.looksLikeJSONFragment(trimmed), !Self.isCompleteJSONLine(trimmed) {
                consumedByteCount -= UInt64(trailingLine.utf8.count)
                lines.removeLast()
            }
        }

        return (lines, consumedByteCount)
    }

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

    private static func readFileData(from fileURL: URL, afterOffset: UInt64) throws -> Data {
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let handle = FileHandle(forReadingAtPath: fileURL.path) else {
            return Data()
        }

        defer { try? handle.close() }
        try handle.seek(toOffset: afterOffset)
        return try handle.readToEnd() ?? Data()
    }

    private static func isCompleteJSONLine(_ line: String) -> Bool {
        guard let data = line.data(using: .utf8) else { return false }
        return (try? JSONSerialization.jsonObject(with: data)) != nil
    }

    private static func looksLikeJSONFragment(_ line: String) -> Bool {
        line.first == "{" || line.first == "["
    }
}

private enum LogReaderISO8601 {
    nonisolated(unsafe) static let withFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    nonisolated(unsafe) static let basic: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static func date(from string: String) -> Date? {
        withFractionalSeconds.date(from: string) ?? basic.date(from: string)
    }
}
