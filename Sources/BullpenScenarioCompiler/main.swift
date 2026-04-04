import Foundation
import LogReaders
import Models
import Services

private let repoRoot: URL = {
    URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()   // BullpenScenarioCompiler
        .deletingLastPathComponent()   // Sources
        .deletingLastPathComponent()   // repo root
}()

private func fixtureURL(_ relativePath: String) -> URL {
    repoRoot.appendingPathComponent(relativePath)
}

private func parseFixtureActivities(
    relativePath: String,
    sessionID: String,
    agentType: AgentType
) throws -> [ScenarioActivitySnapshot] {
    let reader: any AgentLogReader
    switch agentType {
    case .codexCLI:
        reader = CodexLogReader()
    case .claudeCode:
        reader = ClaudeCodeLogReader()
    }

    let contents = try String(contentsOf: fixtureURL(relativePath), encoding: .utf8)
    let activities = contents
        .split(separator: "\n", omittingEmptySubsequences: false)
        .compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            return reader.parseLogEntry(trimmed, sessionID: sessionID)
        }
        .map(ScenarioActivitySnapshot.init(activity:))

    return representativeActivities(from: activities)
}

private func representativeActivities(from activities: [ScenarioActivitySnapshot]) -> [ScenarioActivitySnapshot] {
    guard !activities.isEmpty else { return [] }

    let parentMetadata = activities.first {
        $0.parentSessionID != nil || $0.codexRoleTitle != nil
    }

    let preferredFinal = activities.last(where: isMeaningfulActive) ?? activities.last!

    if let parentMetadata, parentMetadata != preferredFinal {
        return [parentMetadata, preferredFinal]
    }

    return [preferredFinal]
}

private func isMeaningfulActive(_ activity: ScenarioActivitySnapshot) -> Bool {
    switch activity.activityType {
    case .thinking, .toolUse:
        return true
    case .assistantMessage:
        return activity.summary.hasPrefix("Writing")
            || activity.summary.hasPrefix("Editing")
            || activity.summary.hasPrefix("Running")
            || activity.summary.hasPrefix("Searching")
    default:
        return false
    }
}

private func makeFixtureSession(
    sessionID: String,
    agentType: AgentType,
    relativePath: String,
    virtualFilePath: String
) throws -> ScenarioSessionSnapshot {
    ScenarioSessionSnapshot(
        sessionID: sessionID,
        agentType: agentType,
        filePath: virtualFilePath,
        activities: try parseFixtureActivities(
            relativePath: relativePath,
            sessionID: sessionID,
            agentType: agentType
        )
    )
}

private func makeSyntheticSession(
    sessionID: String,
    agentType: AgentType,
    virtualFilePath: String,
    activityType: ActivityType,
    summary: String,
    timestamp: Date,
    userMessageText: String? = nil,
    codexRoleTitle: String? = nil,
    parentSessionID: String? = nil
) -> ScenarioSessionSnapshot {
    ScenarioSessionSnapshot(
        sessionID: sessionID,
        agentType: agentType,
        filePath: virtualFilePath,
        activities: [
            ScenarioActivitySnapshot(
                timestamp: timestamp,
                activityType: activityType,
                summary: summary,
                userMessageText: userMessageText,
                codexRoleTitle: codexRoleTitle,
                parentSessionID: parentSessionID
            )
        ]
    )
}

private func scenarioSnapshots() throws -> [ScenarioSnapshot] {
    let fixtureCodexSingle = try makeFixtureSession(
        sessionID: "codex-main-1",
        agentType: .codexCLI,
        relativePath: "Tests/Fixtures/Codex/simple-session.jsonl",
        virtualFilePath: "/Users/test/.codex/sessions/2026/04/03/codex-main-1.jsonl"
    )
    let fixtureCodexSubagent = try makeFixtureSession(
        sessionID: "codex-subagent-1",
        agentType: .codexCLI,
        relativePath: "Tests/Fixtures/Codex/subagent-session.jsonl",
        virtualFilePath: "/Users/test/.codex/sessions/2026/04/03/codex-subagent-1.jsonl"
    )
    let fixtureClaudeLong = try makeFixtureSession(
        sessionID: "claude-long-1",
        agentType: .claudeCode,
        relativePath: "Tests/Fixtures/ClaudeCode/long-session.jsonl",
        virtualFilePath: "/Users/test/.claude/projects/hash/sessions/claude-long-1.jsonl"
    )
    let fixtureClaudeTool = try makeFixtureSession(
        sessionID: "claude-tool-1",
        agentType: .claudeCode,
        relativePath: "Tests/Fixtures/ClaudeCode/multi-tool-session.jsonl",
        virtualFilePath: "/Users/test/.claude/projects/hash/sessions/claude-tool-1.jsonl"
    )

    let syntheticBase = Date(timeIntervalSince1970: 1_710_000_000)

    return [
        ScenarioSnapshot(
            id: "baseline-empty-v1",
            description: "Empty office baseline render with no active sessions.",
            defaultWorldPreset: .classicBullpen,
            defaultSeed: 7,
            sessions: []
        ),
        ScenarioSnapshot(
            id: "codex-single-session-v1",
            description: "Single Codex replay derived from the simple fixture.",
            defaultWorldPreset: .classicBullpen,
            defaultSeed: 11,
            sessions: [fixtureCodexSingle]
        ),
        ScenarioSnapshot(
            id: "codex-subagent-v1",
            description: "Codex subagent replay derived from the subagent fixture.",
            defaultWorldPreset: .classicBullpen,
            defaultSeed: 23,
            sessions: [fixtureCodexSubagent]
        ),
        ScenarioSnapshot(
            id: "claude-long-session-v1",
            description: "Claude long-session replay derived from the long fixture.",
            defaultWorldPreset: .classicBullpen,
            defaultSeed: 31,
            sessions: [fixtureClaudeLong]
        ),
        ScenarioSnapshot(
            id: "busy-mixed-office-v1",
            description: "Mixed busy office combining Codex and Claude real-ish fixtures.",
            defaultWorldPreset: .classicBullpen,
            defaultSeed: 42,
            sessions: [fixtureCodexSingle, fixtureCodexSubagent, fixtureClaudeLong, fixtureClaudeTool]
        ),
        ScenarioSnapshot(
            id: "dense-office-stress-v1",
            description: "Synthetic dense office used for deterministic stress checks.",
            defaultWorldPreset: .classicBullpen,
            defaultSeed: 314,
            sessions: [
                makeSyntheticSession(sessionID: "dense-1", agentType: .claudeCode, virtualFilePath: "/Users/test/.claude/projects/hash/sessions/dense-1.jsonl", activityType: .toolUse, summary: "Writing feature.swift", timestamp: syntheticBase),
                makeSyntheticSession(sessionID: "dense-2", agentType: .claudeCode, virtualFilePath: "/Users/test/.claude/projects/hash/sessions/dense-2.jsonl", activityType: .thinking, summary: "Thinking...", timestamp: syntheticBase.addingTimeInterval(1)),
                makeSyntheticSession(sessionID: "dense-3", agentType: .codexCLI, virtualFilePath: "/Users/test/.codex/sessions/2026/04/03/dense-3.jsonl", activityType: .toolUse, summary: "Running swift test", timestamp: syntheticBase.addingTimeInterval(2)),
                makeSyntheticSession(sessionID: "dense-4", agentType: .codexCLI, virtualFilePath: "/Users/test/.codex/sessions/2026/04/03/dense-4.jsonl", activityType: .toolUse, summary: "Searching for regressions", timestamp: syntheticBase.addingTimeInterval(3)),
                makeSyntheticSession(sessionID: "dense-5", agentType: .claudeCode, virtualFilePath: "/Users/test/.claude/projects/hash/sessions/dense-5.jsonl", activityType: .assistantMessage, summary: "Reviewed the change set", timestamp: syntheticBase.addingTimeInterval(4)),
                makeSyntheticSession(sessionID: "dense-6", agentType: .codexCLI, virtualFilePath: "/Users/test/.codex/sessions/2026/04/03/dense-6.jsonl", activityType: .error, summary: "Error: build failed", timestamp: syntheticBase.addingTimeInterval(5)),
                makeSyntheticSession(sessionID: "dense-7", agentType: .claudeCode, virtualFilePath: "/Users/test/.claude/projects/hash/sessions/dense-7.jsonl", activityType: .toolUse, summary: "Editing OfficeScene.swift", timestamp: syntheticBase.addingTimeInterval(6)),
                makeSyntheticSession(sessionID: "dense-8", agentType: .codexCLI, virtualFilePath: "/Users/test/.codex/sessions/2026/04/03/dense-8.jsonl", activityType: .thinking, summary: "Thinking...", timestamp: syntheticBase.addingTimeInterval(7), codexRoleTitle: "explore", parentSessionID: "dense-1"),
            ]
        ),
        ScenarioSnapshot(
            id: "idle-heavy-v1",
            description: "Synthetic mostly-idle office for deterministic invariants.",
            defaultWorldPreset: .classicBullpen,
            defaultSeed: 19,
            sessions: [
                makeSyntheticSession(sessionID: "idle-1", agentType: .claudeCode, virtualFilePath: "/Users/test/.claude/projects/hash/sessions/idle-1.jsonl", activityType: .sessionStart, summary: "Started session", timestamp: syntheticBase),
                makeSyntheticSession(sessionID: "idle-2", agentType: .codexCLI, virtualFilePath: "/Users/test/.codex/sessions/2026/04/03/idle-2.jsonl", activityType: .sessionStart, summary: "Started session", timestamp: syntheticBase.addingTimeInterval(1)),
            ]
        ),
        ScenarioSnapshot(
            id: "error-heavy-v1",
            description: "Synthetic office with multiple error states.",
            defaultWorldPreset: .classicBullpen,
            defaultSeed: 1337,
            sessions: [
                makeSyntheticSession(sessionID: "error-1", agentType: .claudeCode, virtualFilePath: "/Users/test/.claude/projects/hash/sessions/error-1.jsonl", activityType: .error, summary: "Error: rate limit", timestamp: syntheticBase),
                makeSyntheticSession(sessionID: "error-2", agentType: .codexCLI, virtualFilePath: "/Users/test/.codex/sessions/2026/04/03/error-2.jsonl", activityType: .error, summary: "Error: migration failed", timestamp: syntheticBase.addingTimeInterval(1)),
                makeSyntheticSession(sessionID: "error-3", agentType: .codexCLI, virtualFilePath: "/Users/test/.codex/sessions/2026/04/03/error-3.jsonl", activityType: .toolUse, summary: "Inspecting rollback plan", timestamp: syntheticBase.addingTimeInterval(2)),
            ]
        ),
        ScenarioSnapshot(
            id: "deep-thinking-heavy-v1",
            description: "Synthetic office with several long-thinking agents.",
            defaultWorldPreset: .classicBullpen,
            defaultSeed: 271,
            sessions: [
                makeSyntheticSession(sessionID: "think-1", agentType: .claudeCode, virtualFilePath: "/Users/test/.claude/projects/hash/sessions/think-1.jsonl", activityType: .thinking, summary: "Thinking...", timestamp: syntheticBase),
                makeSyntheticSession(sessionID: "think-2", agentType: .codexCLI, virtualFilePath: "/Users/test/.codex/sessions/2026/04/03/think-2.jsonl", activityType: .thinking, summary: "Thinking...", timestamp: syntheticBase.addingTimeInterval(1)),
                makeSyntheticSession(sessionID: "think-3", agentType: .claudeCode, virtualFilePath: "/Users/test/.claude/projects/hash/sessions/think-3.jsonl", activityType: .toolUse, summary: "Writing architecture notes", timestamp: syntheticBase.addingTimeInterval(2)),
            ]
        ),
    ]
}

@main
enum BullpenScenarioCompilerMain {
    private static func outputDirectory() -> URL {
        let args = Array(CommandLine.arguments.dropFirst())
        if let index = args.firstIndex(of: "--output-dir"), index + 1 < args.count {
            return URL(fileURLWithPath: args[index + 1], isDirectory: true)
        }
        return repoRoot
            .appendingPathComponent("Tests")
            .appendingPathComponent("Fixtures")
            .appendingPathComponent("Scenarios")
    }

    static func main() throws {
        let outputDirectory = outputDirectory()
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

        for snapshot in try scenarioSnapshots() {
            let outputURL = outputDirectory.appendingPathComponent("\(snapshot.id).json")
            try snapshot.write(to: outputURL)
            print(outputURL.path)
        }
    }
}
