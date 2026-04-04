import AppKit
import Foundation
import Models
import Services
import SpriteKit
import SpriteWorld

private struct CaptureArguments {
    var outputPath = "/tmp/bullpen_screenshot.png"
    var worldPreset: WorldPreset?
    var scenarioID: String?
    var seed: UInt64?
    var manifestPath: String?
    var tickCount: Int?
}

private enum ScreenshotError: Error, LocalizedError {
    case missingFlagValue(String)
    case invalidWorld(String)
    case invalidSeed(String)
    case invalidTickCount(String)
    case renderFailed

    var errorDescription: String? {
        switch self {
        case .missingFlagValue(let flag):
            return "Missing value for \(flag)"
        case .invalidWorld(let rawValue):
            let valid = WorldPreset.allCases.map(\.rawValue).joined(separator: ", ")
            return "Invalid world preset '\(rawValue)'. Valid presets: \(valid)"
        case .invalidSeed(let rawValue):
            return "Invalid seed '\(rawValue)'"
        case .invalidTickCount(let rawValue):
            return "Invalid tick count '\(rawValue)'"
        case .renderFailed:
            return "Failed to render scene to texture"
        }
    }
}

private func parseArguments(_ arguments: [String]) throws -> CaptureArguments {
    var parsed = CaptureArguments()
    let args = Array(arguments.dropFirst())
    var positional: [String] = []
    var index = 0

    func requireValue(after index: Int, flag: String) throws -> String {
        guard index + 1 < args.count else {
            throw ScreenshotError.missingFlagValue(flag)
        }
        return args[index + 1]
    }

    while index < args.count {
        let flag = args[index]
        switch flag {
        case "--world":
            let rawValue = try requireValue(after: index, flag: flag)
            guard let preset = WorldPreset(rawValue: rawValue) else {
                throw ScreenshotError.invalidWorld(rawValue)
            }
            parsed.worldPreset = preset
            index += 2
        case "--scenario":
            parsed.scenarioID = try requireValue(after: index, flag: flag)
            index += 2
        case "--seed":
            let rawValue = try requireValue(after: index, flag: flag)
            guard let seed = UInt64(rawValue) else {
                throw ScreenshotError.invalidSeed(rawValue)
            }
            parsed.seed = seed
            index += 2
        case "--manifest":
            parsed.manifestPath = try requireValue(after: index, flag: flag)
            index += 2
        case "--ticks":
            let rawValue = try requireValue(after: index, flag: flag)
            guard let tickCount = Int(rawValue), tickCount >= 0 else {
                throw ScreenshotError.invalidTickCount(rawValue)
            }
            parsed.tickCount = tickCount
            index += 2
        default:
            positional.append(flag)
            index += 1
        }
    }

    if let first = positional.first {
        parsed.outputPath = first
    }

    return parsed
}

private func fixedCaptureDate(hour: Int, minute: Int) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    let components = DateComponents(
        calendar: calendar,
        timeZone: calendar.timeZone,
        year: 2026,
        month: 4,
        day: 3,
        hour: hour,
        minute: minute
    )
    return calendar.date(from: components) ?? Date(timeIntervalSince1970: 1_775_404_800)
}

@MainActor
private func configuredScene(
    snapshot: ScenarioSnapshot?,
    worldPreset: WorldPreset,
    seed: UInt64,
    tickCount: Int
) async throws -> (view: SKView, scene: OfficeScene, manifest: OfficeSceneManifest?) {
    let scene = OfficeScene(worldPreset: worldPreset)
    scene.scaleMode = .aspectFit
    let view = SKView(frame: NSRect(x: 0, y: 0, width: 1280, height: 768))
    view.presentScene(scene)

    guard let snapshot else {
        return (view, scene, nil)
    }

    let service = await FixtureMonitorServiceFactory.make(snapshot: snapshot)
    scene.dateProvider = { @Sendable in
        fixedCaptureDate(hour: snapshot.captureHour, minute: snapshot.captureMinute)
    }
    scene.updateAgents(service.agents.sorted { $0.id < $1.id })
    scene.settleForDeterministicCapture()

    let manifest = scene.makeManifest(
        scenarioID: snapshot.id,
        seed: seed,
        tickCount: tickCount
    )
    return (view, scene, manifest)
}

@MainActor
private func captureTexture(from view: SKView, scene: OfficeScene) throws -> NSBitmapImageRep {
    _ = NSApplication.shared

    guard let texture = view.texture(from: scene) else {
        throw ScreenshotError.renderFailed
    }

    return NSBitmapImageRep(cgImage: texture.cgImage())
}

@MainActor
private func writeScenarioManifest(_ manifest: OfficeSceneManifest, to path: String) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(manifest)
    let url = URL(fileURLWithPath: path)
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
    try data.write(to: url)
}

@MainActor
private func run() async throws {
    let arguments = try parseArguments(CommandLine.arguments)
    let snapshot: ScenarioSnapshot?
    if let scenarioID = arguments.scenarioID {
        snapshot = try FixtureMonitorServiceFactory.loadScenario(id: scenarioID)
    } else {
        snapshot = nil
    }
    let worldPreset = arguments.worldPreset ?? snapshot?.defaultWorldPreset ?? .classicBullpen
    let seed = arguments.seed ?? snapshot?.defaultSeed ?? 7
    let tickCount = arguments.tickCount ?? snapshot?.captureTickCount ?? 120

    let configured = try await configuredScene(
        snapshot: snapshot,
        worldPreset: worldPreset,
        seed: seed,
        tickCount: tickCount
    )

    for tick in 0...tickCount {
        configured.scene.update(Double(tick) / 60.0)
    }

    let bitmap = try captureTexture(from: configured.view, scene: configured.scene)
    guard let pngData = bitmap.representation(using: NSBitmapImageRep.FileType.png, properties: [:]) else {
        throw ScreenshotError.renderFailed
    }

    let outputURL = URL(fileURLWithPath: arguments.outputPath)
    try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
    try pngData.write(to: outputURL)

    if let manifestPath = arguments.manifestPath, let manifest = configured.manifest {
        try writeScenarioManifest(manifest, to: manifestPath)
    }

    print(outputURL.path)
}

@main
enum BullpenScreenshotMain {
    static func main() async {
        do {
            try await run()
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }
}
