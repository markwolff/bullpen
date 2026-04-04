import Foundation
import LogReaders
import Models

protocol DeterministicReplayLogReader: AgentLogReader {}

public struct ScenarioLogReader: DeterministicReplayLogReader, Sendable {
    public let agentType: AgentType

    private let sessionsByID: [String: ScenarioSessionSnapshot]

    private static let repoRoot: URL = {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // Services
            .deletingLastPathComponent()   // Sources
            .deletingLastPathComponent()   // repo root
    }()

    public init(agentType: AgentType, sessions: [ScenarioSessionSnapshot]) {
        self.agentType = agentType
        self.sessionsByID = Dictionary(uniqueKeysWithValues: sessions.map { ($0.sessionID, $0) })
    }

    public func discoverSessions() async throws -> [String: URL] {
        Dictionary(uniqueKeysWithValues: sessionsByID.values.map { session in
            (session.sessionID, Self.resolveURL(for: session.filePath))
        })
    }

    public func readActivities(
        from logFileURL: URL,
        afterOffset: UInt64
    ) async throws -> (activities: [AgentActivity], newOffset: UInt64) {
        let sessionID = logFileURL.deletingPathExtension().lastPathComponent
        guard let session = sessionsByID[sessionID] else {
            return (activities: [], newOffset: afterOffset)
        }

        guard afterOffset == 0 else {
            return (activities: [], newOffset: afterOffset)
        }

        let activities = session.activities.map { $0.makeActivity(sessionID: sessionID) }
        return (activities: activities, newOffset: UInt64(activities.count))
    }

    public func parseLogEntry(_ rawEntry: String, sessionID: String) -> AgentActivity? {
        nil
    }

    private static func resolveURL(for filePath: String) -> URL {
        if filePath.hasPrefix("/") {
            return URL(fileURLWithPath: filePath)
        }
        return repoRoot.appendingPathComponent(filePath)
    }
}
