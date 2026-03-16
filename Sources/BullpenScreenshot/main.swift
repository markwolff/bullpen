import AppKit
import SpriteKit
import SpriteWorld
import Models

@MainActor
func captureScreenshot(to outputPath: String) {
    // Ensure AppKit framework is initialized for headless SpriteKit rendering
    _ = NSApplication.shared

    let scene = OfficeScene()
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

let outputPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "/tmp/bullpen_screenshot.png"

captureScreenshot(to: outputPath)
