import Foundation

/// Checks whether OS processes are still alive, used to determine if a
/// Claude Code session is still running during deep thinking periods.
public struct ProcessLivenessChecker: Sendable {

    public init() {}

    /// Returns true if the process with the given PID is still running.
    /// Uses `kill(pid, 0)` which sends no signal but checks for existence.
    public func isProcessAlive(pid: Int32) -> Bool {
        kill(pid, 0) == 0
    }

    /// Reads Claude Code session files from `~/.claude/sessions/` to discover
    /// which session IDs map to which PIDs.
    /// Returns a dictionary of `[sessionId: pid]`.
    public func discoverSessionPIDs(claudeDirectory: URL? = nil) -> [String: Int32] {
        let baseDir = claudeDirectory ?? FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude")
        let sessionsDir = baseDir.appendingPathComponent("sessions")

        guard FileManager.default.fileExists(atPath: sessionsDir.path) else {
            return [:]
        }

        var result: [String: Int32] = [:]

        guard let files = try? FileManager.default.contentsOfDirectory(
            at: sessionsDir,
            includingPropertiesForKeys: nil
        ) else {
            return [:]
        }

        for file in files where file.pathExtension == "json" {
            guard let data = try? Data(contentsOf: file),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let pid = json["pid"] as? Int,
                  let sessionId = json["sessionId"] as? String
            else {
                continue
            }
            result[sessionId] = Int32(pid)
        }

        return result
    }
}
