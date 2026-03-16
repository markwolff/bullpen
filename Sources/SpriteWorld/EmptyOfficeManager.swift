import SpriteKit
import Models

/// Manages the "empty office" state when no agents are present.
/// Activates screensaver laptops, dim overlay, enhanced cat behavior, and janitor NPC.
@MainActor
public class EmptyOfficeManager {

    /// Whether empty office mode is currently active
    public private(set) var isActive: Bool = false

    /// Timer tracking how long the office has been empty
    private var emptyTimer: TimeInterval = 0

    /// The dim overlay node
    private weak var dimOverlay: SKShapeNode?

    /// The janitor NPC
    private var janitor: JanitorNPCSprite?

    /// Threshold before activating empty mode (seconds)
    private let activationDelay: TimeInterval = 10.0

    /// Reference to scene for node management
    private weak var scene: SKScene?

    public init() {}

    /// Call each frame from OfficeScene.update()
    /// - Returns: true if empty mode state changed (for scene to react)
    @discardableResult
    public func update(deltaTime: TimeInterval, agentCount: Int, scene: SKScene) -> Bool {
        self.scene = scene

        if agentCount == 0 {
            emptyTimer += deltaTime
            if !isActive && emptyTimer >= activationDelay {
                activate(scene: scene)
                return true
            }
            if isActive {
                updateJanitor(deltaTime: deltaTime, scene: scene)
            }
        } else {
            if isActive {
                deactivate(scene: scene)
                return true
            }
            emptyTimer = 0
        }
        return false
    }

    private func activate(scene: SKScene) {
        isActive = true

        // Remove any stale overlays from prior activations
        scene.enumerateChildNodes(withName: "empty_office_overlay") { node, _ in
            node.removeAllActions()
            node.removeFromParent()
        }

        // Add dim overlay
        let overlay = SKShapeNode(rectOf: CGSize(width: 1280, height: 768))
        overlay.fillColor = SKColor(red: 0.063, green: 0.094, blue: 0.188, alpha: 0.1)
        overlay.strokeColor = .clear
        overlay.position = CGPoint(x: 640, y: 384)
        overlay.zPosition = 8
        overlay.alpha = 0
        overlay.name = "empty_office_overlay"
        scene.addChild(overlay)
        overlay.run(SKAction.fadeAlpha(to: 1.0, duration: 2.0))
        dimOverlay = overlay

        // Switch all laptops to screensaver
        setLaptopScreensavers(on: true, scene: scene)

        // Increase dust motes
        if let dustMotes = scene.childNode(withName: "dust_motes") as? SKEmitterNode {
            dustMotes.particleBirthRate = 2.0
        }

        // Spawn janitor
        spawnJanitor(scene: scene)
    }

    private func deactivate(scene: SKScene) {
        isActive = false
        emptyTimer = 0

        // Remove all overlays (including any orphaned ones from rapid activate/deactivate cycles)
        scene.enumerateChildNodes(withName: "empty_office_overlay") { node, _ in
            node.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 1.0),
                SKAction.removeFromParent()
            ]))
        }
        dimOverlay = nil

        // Restore laptops
        setLaptopScreensavers(on: false, scene: scene)

        // Restore dust motes
        if let dustMotes = scene.childNode(withName: "dust_motes") as? SKEmitterNode {
            dustMotes.particleBirthRate = 0.8
        }

        // Remove janitor
        removeJanitor()
    }

    private func setLaptopScreensavers(on: Bool, scene: SKScene) {
        let texture = TextureManager.shared.texture(
            for: on ? TextureManager.furnitureLaptopScreensaver : TextureManager.furnitureLaptopOff
        )
        for i in 0..<16 {
            if let desk = scene.childNode(withName: "desk_\(i)"),
               let monitor = desk.childNode(withName: "monitor_\(i)") as? SKSpriteNode {
                monitor.texture = texture
            }
        }
    }

    private func spawnJanitor(scene: SKScene) {
        let j = JanitorNPCSprite()
        j.position = CGPoint(x: -50, y: 150)
        j.zPosition = 5
        scene.addChild(j)
        janitor = j
        j.startSweeping(sceneWidth: 1280)
    }

    private func removeJanitor() {
        janitor?.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ]))
        janitor = nil
    }

    private func updateJanitor(deltaTime: TimeInterval, scene: SKScene) {
        // Janitor loops automatically via SKActions
        if let j = janitor, j.parent == nil {
            // Janitor was removed, respawn after a delay
            spawnJanitor(scene: scene)
        }
    }
}
