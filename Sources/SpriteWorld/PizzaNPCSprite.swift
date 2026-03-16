import SpriteKit

/// A simple pizza delivery NPC sprite. Walks in, drops pizza, walks out.
/// No thought bubble or complex behavior — just a walk animation.
public class PizzaNPCSprite: SKSpriteNode {

    public init() {
        let texture = TextureManager.shared.texture(for: TextureManager.npcPizzaDelivery)
        // 16x24 pixel art scaled 3x = 48x72
        super.init(texture: texture, color: .clear, size: CGSize(width: 48, height: 72))
        self.name = "npc_pizza_delivery"
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
