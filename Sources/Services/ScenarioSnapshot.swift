import Foundation
import Models

public struct ScenarioSnapshot: Codable, Sendable, Equatable {
    public static let schemaVersionValue = "scenario-snapshot-v1"

    public let schemaVersion: String
    public let id: String
    public let description: String
    public let defaultWorldPreset: WorldPreset
    public let defaultSeed: UInt64
    public let captureHour: Int
    public let captureMinute: Int
    public let captureTickCount: Int
    public let sessions: [ScenarioSessionSnapshot]

    public init(
        id: String,
        description: String,
        defaultWorldPreset: WorldPreset = .classicBullpen,
        defaultSeed: UInt64,
        captureHour: Int = 10,
        captureMinute: Int = 0,
        captureTickCount: Int = 120,
        sessions: [ScenarioSessionSnapshot]
    ) {
        self.schemaVersion = Self.schemaVersionValue
        self.id = id
        self.description = description
        self.defaultWorldPreset = defaultWorldPreset
        self.defaultSeed = defaultSeed
        self.captureHour = captureHour
        self.captureMinute = captureMinute
        self.captureTickCount = captureTickCount
        self.sessions = sessions
    }

    public static func load(from url: URL) throws -> ScenarioSnapshot {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ScenarioSnapshot.self, from: Data(contentsOf: url))
    }

    public func write(to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(self).write(to: url)
    }
}

public struct ScenarioSessionSnapshot: Codable, Sendable, Equatable {
    public let sessionID: String
    public let agentType: AgentType
    public let filePath: String
    public let activities: [ScenarioActivitySnapshot]

    public init(
        sessionID: String,
        agentType: AgentType,
        filePath: String,
        activities: [ScenarioActivitySnapshot]
    ) {
        self.sessionID = sessionID
        self.agentType = agentType
        self.filePath = filePath
        self.activities = activities
    }
}

public struct ScenarioActivitySnapshot: Codable, Sendable, Equatable {
    public let timestamp: Date
    public let activityType: ActivityType
    public let summary: String
    public let userMessageText: String?
    public let codexRoleTitle: String?
    public let inputTokens: Int
    public let outputTokens: Int
    public let isPlanMode: Bool
    public let parentSessionID: String?

    public init(
        timestamp: Date,
        activityType: ActivityType,
        summary: String,
        userMessageText: String? = nil,
        codexRoleTitle: String? = nil,
        inputTokens: Int = 0,
        outputTokens: Int = 0,
        isPlanMode: Bool = false,
        parentSessionID: String? = nil
    ) {
        self.timestamp = timestamp
        self.activityType = activityType
        self.summary = summary
        self.userMessageText = userMessageText
        self.codexRoleTitle = codexRoleTitle
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.isPlanMode = isPlanMode
        self.parentSessionID = parentSessionID
    }

    public init(activity: AgentActivity) {
        self.timestamp = activity.timestamp
        self.activityType = activity.activityType
        self.summary = activity.summary
        self.userMessageText = activity.userMessageText
        self.codexRoleTitle = activity.codexRoleTitle
        self.inputTokens = activity.inputTokens
        self.outputTokens = activity.outputTokens
        self.isPlanMode = activity.isPlanMode
        self.parentSessionID = activity.parentSessionID
    }

    public func makeActivity(sessionID: String) -> AgentActivity {
        AgentActivity(
            sessionID: sessionID,
            timestamp: timestamp,
            activityType: activityType,
            summary: summary,
            userMessageText: userMessageText,
            codexRoleTitle: codexRoleTitle,
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            isPlanMode: isPlanMode,
            parentSessionID: parentSessionID
        )
    }
}
