import Foundation
import Models

public enum FixtureMonitorServiceFactory {
    public enum FactoryError: Error, LocalizedError {
        case scenarioNotFound(String)

        public var errorDescription: String? {
            switch self {
            case .scenarioNotFound(let id):
                return "Scenario '\(id)' was not found under Tests/Fixtures/Scenarios"
            }
        }
    }

    private static let repoRoot: URL = {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // Services
            .deletingLastPathComponent()   // Sources
            .deletingLastPathComponent()   // repo root
    }()

    public static var defaultScenarioDirectory: URL {
        repoRoot
            .appendingPathComponent("Tests")
            .appendingPathComponent("Fixtures")
            .appendingPathComponent("Scenarios")
    }

    public static func loadScenario(
        id: String,
        from directory: URL = defaultScenarioDirectory
    ) throws -> ScenarioSnapshot {
        let url = directory.appendingPathComponent("\(id).json")
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw FactoryError.scenarioNotFound(id)
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ScenarioSnapshot.self, from: data)
    }

    @MainActor
    public static func make(snapshot: ScenarioSnapshot) async -> AgentMonitorService {
        let groupedSessions = Dictionary(grouping: snapshot.sessions, by: \.agentType)
        let readers = groupedSessions.map { agentType, sessions in
            ScenarioLogReader(agentType: agentType, sessions: sessions)
        }

        let service = AgentMonitorService(
            logReaders: readers,
            discoveryInterval: 10_000,
            idleTimeout: 30.0,
            finishedRemovalTimeout: 120.0,
            idleRemovalTimeout: 120.0,
            deepThinkingTimeout: 600.0
        )

        await service.performDiscovery()
        await service.replayAllDiscoveredSessions()
        return service
    }
}
