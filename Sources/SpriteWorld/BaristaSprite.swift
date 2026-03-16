import SpriteKit

/// A barista NPC sprite positioned behind a coffee station counter.
public class BaristaSprite: SKNode {

    /// The barista character sprite
    private let bodySprite: SKSpriteNode

    /// The coffee station/counter behind the barista
    private let stationSprite: SKSpriteNode

    public override init() {
        let stationTexture = TextureManager.shared.texture(for: TextureManager.decorationCoffeeStation)
        stationSprite = SKSpriteNode(texture: stationTexture, size: CGSize(width: 96, height: 72))

        let bodyTexture = TextureManager.shared.texture(for: "barista_idle_frame0")
        bodySprite = SKSpriteNode(texture: bodyTexture, size: CGSize(width: 48, height: 72))

        super.init()

        self.name = "decoration_barista"

        stationSprite.position = CGPoint(x: 0, y: 10)
        stationSprite.zPosition = 0
        addChild(stationSprite)

        bodySprite.position = CGPoint(x: 0, y: 0)
        bodySprite.zPosition = 1
        addChild(bodySprite)

        startIdleAnimation()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Public API

    /// Plays a serve animation and emits a floating coffee emoji, then restores idle.
    public func serveCustomer() {
        bodySprite.removeAction(forKey: "baristaIdle")
        bodySprite.texture = TextureManager.shared.texture(for: "barista_serve")

        let coffeeLabel = SKLabelNode(text: "☕")
        coffeeLabel.fontSize = 16
        coffeeLabel.position = CGPoint(x: 10, y: 24)
        coffeeLabel.zPosition = 10
        addChild(coffeeLabel)

        let drift = SKAction.moveBy(x: 0, y: 20, duration: 1.0)
        let fade = SKAction.fadeOut(withDuration: 1.0)
        let floatGroup = SKAction.group([drift, fade])
        let removeLabel = SKAction.removeFromParent()
        coffeeLabel.run(SKAction.sequence([floatGroup, removeLabel]))

        let wait = SKAction.wait(forDuration: 1.5)
        let restore = SKAction.run { [weak self] in
            self?.startIdleAnimation()
        }
        run(SKAction.sequence([wait, restore]))
    }

    // MARK: - Private Helpers

    private func startIdleAnimation() {
        let frame0 = TextureManager.shared.texture(for: "barista_idle_frame0")
        let frame1 = TextureManager.shared.texture(for: "barista_idle_frame1")
        let animate = SKAction.animate(with: [frame0, frame1], timePerFrame: 0.8)
        let loop = SKAction.repeatForever(animate)
        bodySprite.run(loop, withKey: "baristaIdle")
    }
}
