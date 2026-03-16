import SpriteKit
import Models

/// Monitors active agent count and triggers pizza delivery when 5+ agents are working.
/// Pizza NPC walks from door to center, drops a pizza box, walks back, and fades out.
@MainActor
public class PizzaDeliveryManager {

    /// Whether a delivery is currently in progress
    public private(set) var isDelivering: Bool = false

    /// Cooldown timer (10 minutes between deliveries)
    private var cooldownTimer: TimeInterval = 0
    private let cooldownDuration: TimeInterval = 600 // 10 minutes

    /// Active agent threshold
    private let agentThreshold: Int = 5

    /// Whether a pizza box is currently on the floor
    private var hasPizzaBox: Bool = false
    private var pizzaBoxTimer: TimeInterval = 0
    private let pizzaBoxDuration: TimeInterval = 60 // 1 minute

    public init() {}

    /// Call each frame from OfficeScene.update()
    public func update(
        deltaTime: TimeInterval,
        activeAgentCount: Int,
        scene: SKScene,
        layout: OfficeLayout,
        doorPosition: CGPoint,
        dropPosition: CGPoint
    ) {
        cooldownTimer += deltaTime

        // Check if pizza box should fade
        if hasPizzaBox {
            pizzaBoxTimer += deltaTime
            if pizzaBoxTimer >= pizzaBoxDuration {
                removePizzaBox(scene: scene)
            }
        }

        // Check delivery trigger
        if !isDelivering
            && activeAgentCount >= agentThreshold
            && cooldownTimer >= cooldownDuration {
            triggerDelivery(scene: scene, layout: layout, doorPosition: doorPosition, dropPosition: dropPosition)
        }
    }

    private func triggerDelivery(scene: SKScene, layout: OfficeLayout, doorPosition: CGPoint, dropPosition: CGPoint) {
        isDelivering = true
        cooldownTimer = 0

        let npc = PizzaNPCSprite()
        npc.position = doorPosition
        npc.zPosition = 5
        scene.addChild(npc)

        let walkSpeed: CGFloat = 80
        let toDropPath = layout.findPath(from: doorPosition, to: dropPosition)
        let walkToDrop = PathMovement.sequence(
            from: doorPosition,
            points: toDropPath,
            speed: walkSpeed,
            beforeSegment: { [weak npc] start, end in
                guard let npc, abs(end.x - start.x) > 0.5 else { return }
                npc.xScale = end.x < start.x ? -abs(npc.xScale) : abs(npc.xScale)
            }
        ) ?? SKAction.wait(forDuration: 0)

        let pause = SKAction.wait(forDuration: 3.0)

        let dropBox = SKAction.run { [weak self] in
            self?.placePizzaBox(at: dropPosition, scene: scene)
        }

        let backPath = layout.findPath(from: dropPosition, to: doorPosition)
        let walkBack = PathMovement.sequence(
            from: dropPosition,
            points: backPath,
            speed: walkSpeed,
            beforeSegment: { [weak npc] start, end in
                guard let npc, abs(end.x - start.x) > 0.5 else { return }
                npc.xScale = end.x < start.x ? -abs(npc.xScale) : abs(npc.xScale)
            }
        ) ?? SKAction.wait(forDuration: 0)

        let fadeAndRemove = SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ])

        let done = SKAction.run { [weak self] in
            self?.isDelivering = false
        }

        npc.run(SKAction.sequence([walkToDrop, pause, dropBox, walkBack, fadeAndRemove, done]))
    }

    private func placePizzaBox(at position: CGPoint, scene: SKScene) {
        removePizzaBox(scene: scene) // Clear any existing

        let box = SKSpriteNode(
            texture: TextureManager.shared.texture(for: TextureManager.itemPizzaBox),
            size: CGSize(width: 40, height: 24)
        )
        box.position = position
        box.name = "pizza_box"
        box.zPosition = 3
        box.alpha = 0
        scene.addChild(box)

        box.run(SKAction.group([
            SKAction.fadeIn(withDuration: 0.2),
            SKAction.sequence([
                SKAction.scale(to: 1.1, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.1)
            ])
        ]))

        hasPizzaBox = true
        pizzaBoxTimer = 0
    }

    private func removePizzaBox(scene: SKScene) {
        if let box = scene.childNode(withName: "pizza_box") {
            box.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 1.0),
                SKAction.removeFromParent()
            ]))
        }
        hasPizzaBox = false
        pizzaBoxTimer = 0
    }
}
