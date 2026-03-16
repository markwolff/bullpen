import SpriteKit

/// Manages night-time visual effects (10PM-6AM).
/// Adds dark overlay, boosts lamp glows, and adds sleepy-eye overlays on agents.
@MainActor
public class NightOwlManager {

    /// Whether night mode is currently active
    public private(set) var isNightMode: Bool = false

    /// The dark overlay node
    private weak var nightOverlay: SKShapeNode?

    public init() {}

    /// Updates night mode based on current hour. Call periodically (e.g. every 60s).
    public func update(hour: Int, scene: SKScene, agentSprites: [SKSpriteNode]) {
        let shouldBeNight = false  // Disabled: was hour >= 22 || hour < 6

        if shouldBeNight && !isNightMode {
            activateNightMode(scene: scene, agentSprites: agentSprites)
        } else if !shouldBeNight && isNightMode {
            deactivateNightMode(scene: scene, agentSprites: agentSprites)
        }
    }

    private func activateNightMode(scene: SKScene, agentSprites: [SKSpriteNode]) {
        isNightMode = true

        // Dark blue overlay
        let overlay = SKShapeNode(rectOf: CGSize(width: 1280, height: 768))
        overlay.fillColor = SKColor(red: 0.063, green: 0.094, blue: 0.188, alpha: 0.3)
        overlay.strokeColor = .clear
        overlay.position = CGPoint(x: 640, y: 384)
        overlay.zPosition = 8
        overlay.alpha = 0
        overlay.name = "night_overlay"
        scene.addChild(overlay)
        overlay.run(SKAction.fadeAlpha(to: 1.0, duration: 2.0))
        nightOverlay = overlay

        // Boost lamp glows
        for i in 0..<16 {
            if let desk = scene.childNode(withName: "desk_\(i)"),
               let lamp = desk.childNode(withName: "lamp_\(i)") {
                lamp.alpha = 1.0
                // Add warm glow around lamp
                let glow = SKShapeNode(circleOfRadius: 40)
                glow.fillColor = SKColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 0.15)
                glow.strokeColor = .clear
                glow.name = "lamp_night_glow"
                glow.zPosition = -1
                lamp.addChild(glow)

                let pulse = SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.25, duration: 2.0),
                    SKAction.fadeAlpha(to: 0.15, duration: 2.0)
                ])
                glow.run(SKAction.repeatForever(pulse))
            }
        }

        // Add sleepy eyes to agents
        for sprite in agentSprites {
            addSleepyEyes(to: sprite)
        }
    }

    private func deactivateNightMode(scene: SKScene, agentSprites: [SKSpriteNode]) {
        isNightMode = false

        // Remove overlay
        nightOverlay?.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 2.0),
            SKAction.removeFromParent()
        ]))
        nightOverlay = nil

        // Remove lamp glows
        for i in 0..<16 {
            if let desk = scene.childNode(withName: "desk_\(i)"),
               let lamp = desk.childNode(withName: "lamp_\(i)") {
                lamp.childNode(withName: "lamp_night_glow")?.removeFromParent()
            }
        }

        // Remove sleepy eyes
        for sprite in agentSprites {
            sprite.childNode(withName: "sleepy_eyes")?.removeFromParent()
        }
    }

    private func addSleepyEyes(to sprite: SKSpriteNode) {
        guard sprite.childNode(withName: "sleepy_eyes") == nil else { return }
        let eyes = SKSpriteNode(
            texture: TextureManager.shared.texture(for: TextureManager.overlaySleepyEyes),
            size: CGSize(width: 48, height: 18)
        )
        eyes.position = CGPoint(x: 0, y: sprite.size.height * 0.25)
        eyes.zPosition = 6
        eyes.alpha = 0.6
        eyes.name = "sleepy_eyes"
        sprite.addChild(eyes)
    }
}
