import SpriteKit
import Models

/// A trophy shelf that displays earned achievement trophies.
/// Trophies appear with a pop-in animation and sparkle when first unlocked.
public class AchievementShelfSprite: SKNode {

    /// The shelf background
    private let shelfSprite: SKSpriteNode

    /// Trophy slots (up to 5)
    private var trophySlots: [Achievement: SKSpriteNode] = [:]

    /// The 5 slot positions on the shelf
    private let slotPositions: [CGPoint] = [
        CGPoint(x: -36, y: 12),
        CGPoint(x: -18, y: 12),
        CGPoint(x: 0, y: 12),
        CGPoint(x: 18, y: 12),
        CGPoint(x: 36, y: 12),
    ]

    public override init() {
        let texture = TextureManager.shared.texture(for: TextureManager.decorationAchievementShelf)
        shelfSprite = SKSpriteNode(texture: texture, size: CGSize(width: 96, height: 32))
        super.init()

        self.name = "achievement_shelf"
        addChild(shelfSprite)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    /// Displays trophies for all unlocked achievements. Call after loading persisted state.
    public func displayUnlocked(_ achievements: Set<Achievement>) {
        for achievement in achievements {
            guard trophySlots[achievement] == nil else { continue }
            addTrophy(for: achievement, animated: false)
        }
    }

    /// Adds a trophy for a newly unlocked achievement with pop-in animation.
    public func unlockTrophy(for achievement: Achievement) {
        guard trophySlots[achievement] == nil else { return }
        addTrophy(for: achievement, animated: true)
    }

    private func addTrophy(for achievement: Achievement, animated: Bool) {
        let allCases = Achievement.allCases
        guard let slotIndex = allCases.firstIndex(of: achievement),
              slotIndex < slotPositions.count else { return }

        let texture = TextureManager.shared.texture(for: achievement.trophyTextureName)
        let trophy = SKSpriteNode(texture: texture, size: CGSize(width: 18, height: 24))
        trophy.position = slotPositions[slotIndex]
        trophy.zPosition = 1
        trophy.name = "trophy_\(achievement.rawValue)"

        if animated {
            // Pop-in animation
            trophy.setScale(0)
            trophy.alpha = 0
            addChild(trophy)

            let popIn = SKAction.group([
                SKAction.scale(to: 1.0, duration: 0.3),
                SKAction.fadeIn(withDuration: 0.3)
            ])
            popIn.timingMode = .easeOut
            trophy.run(popIn)

            // Sparkle burst
            addSparkle(at: slotPositions[slotIndex])
        } else {
            addChild(trophy)
        }

        trophySlots[achievement] = trophy
    }

    private func addSparkle(at position: CGPoint) {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 15
        emitter.numParticlesToEmit = 10
        emitter.particleLifetime = 0.8
        emitter.particleColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1.0)
        emitter.particleColorAlphaSpeed = -1.2
        emitter.particleSpeed = 20
        emitter.particleSpeedRange = 10
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi
        emitter.particleScale = 0.2
        emitter.position = position
        emitter.zPosition = 2
        addChild(emitter)

        emitter.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.removeFromParent()
        ]))
    }
}
