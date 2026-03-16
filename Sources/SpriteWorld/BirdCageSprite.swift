import SpriteKit

/// An office bird cage decoration with a chirping animated parakeet inside.
public class BirdCageSprite: SKNode {

    /// The cage body sprite
    private let body: SKSpriteNode

    /// The small bird sprite inside the cage
    private let birdSprite: SKSpriteNode

    /// Time elapsed since the last chirp note was emitted
    private var lastChirpTime: TimeInterval = 0

    /// Seconds between chirp notes (randomized each cycle)
    private var chirpInterval: TimeInterval = 10

    public override init() {
        let cageTexture = TextureManager.shared.texture(for: TextureManager.decorationBirdCage)
        body = SKSpriteNode(texture: cageTexture, size: CGSize(width: 48, height: 72))

        let frame0 = TextureManager.shared.texture(for: TextureManager.birdIdleFrame0)
        birdSprite = SKSpriteNode(texture: frame0, size: CGSize(width: 18, height: 18))

        super.init()

        self.name = "decoration_bird_cage"

        addChild(body)

        birdSprite.position = CGPoint(x: 0, y: 4)
        birdSprite.zPosition = 1
        addChild(birdSprite)

        startBirdAnimation()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Bird Animation

    private func startBirdAnimation() {
        let frame0 = TextureManager.shared.texture(for: TextureManager.birdIdleFrame0)
        let frame1 = TextureManager.shared.texture(for: TextureManager.birdIdleFrame1)
        let frame2 = TextureManager.shared.texture(for: TextureManager.birdIdleFrame2)

        let animate = SKAction.animate(
            with: [frame0, frame1, frame2],
            timePerFrame: 0.4,
            resize: false,
            restore: true
        )
        birdSprite.run(SKAction.repeatForever(animate), withKey: "bird_idle")
    }

    // MARK: - Chirp Effect

    /// Emits a floating musical note that drifts upward and fades out.
    public func startChirp() {
        let note = SKLabelNode(fontNamed: "Helvetica")
        note.text = "♪"
        note.fontSize = 12
        note.position = CGPoint(x: 8, y: 20)
        note.zPosition = 10
        addChild(note)

        let drift = SKAction.moveBy(x: 0, y: 30, duration: 1.5)
        let fade = SKAction.fadeOut(withDuration: 1.5)
        let remove = SKAction.removeFromParent()
        note.run(SKAction.sequence([SKAction.group([drift, fade]), remove]))
    }

    // MARK: - Update

    /// Call each frame from the scene's update loop.
    /// - Parameter hasActiveAgents: Pass `true` when at least one agent is actively working.
    public func update(hasActiveAgents: Bool) {
        let now = CACurrentMediaTime()
        if now - lastChirpTime >= chirpInterval {
            lastChirpTime = now
            chirpInterval = hasActiveAgents
                ? TimeInterval.random(in: 3...8)
                : TimeInterval.random(in: 5...15)
            startChirp()
        }
    }
}
