import SpriteKit

/// A simple NPC janitor that sweeps across the office floor during empty office mode.
/// Uses a 16x24 pixel art texture, walks left-to-right with a sweeping animation.
public class JanitorNPCSprite: SKSpriteNode {

    public init() {
        let texture = TextureManager.shared.texture(for: TextureManager.npcJanitor)
        // 16x24 pixel art scaled 3x = 48x72
        super.init(texture: texture, color: .clear, size: CGSize(width: 48, height: 72))
        self.name = "npc_janitor"
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    /// Starts the sweeping walk cycle across the scene.
    public func startSweeping(sceneWidth: CGFloat) {
        let startX: CGFloat = -50
        let endX = sceneWidth + 50
        let speed: CGFloat = 30 // points per second
        let distance = endX - startX
        let duration = TimeInterval(distance / speed)

        let walkRight = SKAction.moveTo(x: endX, duration: duration)
        walkRight.timingMode = .linear

        let resetPosition = SKAction.run { [weak self] in
            self?.position.x = startX
        }

        let pause = SKAction.wait(forDuration: 5.0)
        let sweep = SKAction.sequence([walkRight, pause, resetPosition, pause])
        run(SKAction.repeatForever(sweep), withKey: "sweep")
    }
}
