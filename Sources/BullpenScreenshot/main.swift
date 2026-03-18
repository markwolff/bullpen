import AppKit
import SpriteKit
import SpriteWorld
import Models

@MainActor
func captureScreenshot(to outputPath: String, worldPreset: WorldPreset) {
    // Ensure AppKit framework is initialized for headless SpriteKit rendering
    _ = NSApplication.shared

    let scene = OfficeScene(worldPreset: worldPreset)
    let skView = SKView(frame: NSRect(x: 0, y: 0, width: 1280, height: 768))
    skView.presentScene(scene)
    scene.update(1.0)

    guard let texture = skView.texture(from: scene) else {
        print("Error: Failed to render scene to texture")
        exit(1)
    }
    let cgImage = texture.cgImage()

    let rep = NSBitmapImageRep(cgImage: cgImage)
    guard let pngData = rep.representation(using: .png, properties: [:]) else {
        print("Error: Failed to encode PNG")
        exit(1)
    }

    do {
        try pngData.write(to: URL(fileURLWithPath: outputPath))
        print(outputPath)
    } catch {
        print("Error: Failed to write file: \(error)")
        exit(1)
    }
}

// MARK: - Argument Parsing

var outputPath = "/tmp/bullpen_screenshot.png"
var worldPreset: WorldPreset = .classicBullpen
var args = Array(CommandLine.arguments.dropFirst())

// Parse --world flag
if let worldIndex = args.firstIndex(of: "--world") {
    if worldIndex + 1 < args.count {
        let rawValue = args[worldIndex + 1]
        guard let preset = WorldPreset(rawValue: rawValue) else {
            let validValues = WorldPreset.allCases.map(\.rawValue).joined(separator: ", ")
            print("Error: Invalid world preset '\(rawValue)'")
            print("Usage: BullpenScreenshot [outputPath] [--world <preset>]")
            print("Valid presets: \(validValues)")
            exit(1)
        }
        worldPreset = preset
        args.remove(at: worldIndex + 1)
        args.remove(at: worldIndex)
    } else {
        let validValues = WorldPreset.allCases.map(\.rawValue).joined(separator: ", ")
        print("Error: --world requires a preset value")
        print("Usage: BullpenScreenshot [outputPath] [--world <preset>]")
        print("Valid presets: \(validValues)")
        exit(1)
    }
}

// Remaining positional argument is the output path
if let first = args.first {
    outputPath = first
}

captureScreenshot(to: outputPath, worldPreset: worldPreset)
