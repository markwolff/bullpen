import SpriteKit
import Foundation

/// A plant that grows based on total tasks completed across all agents.
/// Persists growth state to UserDefaults. 4 stages: seedling, small, medium, large.
public class GrowingPlantSprite: SKSpriteNode {

    /// Growth stages with thresholds
    public enum GrowthStage: Int, CaseIterable {
        case seedling = 0
        case small = 5
        case medium = 15
        case large = 30

        var textureName: String {
            switch self {
            case .seedling: return TextureManager.plantSeedling
            case .small: return TextureManager.plantSmall
            case .medium: return TextureManager.plantMedium
            case .large: return TextureManager.plantLarge
            }
        }

        var displaySize: CGSize {
            switch self {
            case .seedling: return CGSize(width: 32, height: 40)
            case .small: return CGSize(width: 32, height: 56)
            case .medium: return CGSize(width: 40, height: 72)
            case .large: return CGSize(width: 48, height: 88)
            }
        }

        static func stage(for count: Int) -> GrowthStage {
            if count >= GrowthStage.large.rawValue { return .large }
            if count >= GrowthStage.medium.rawValue { return .medium }
            if count >= GrowthStage.small.rawValue { return .small }
            return .seedling
        }
    }

    /// Current growth stage
    public private(set) var stage: GrowthStage

    /// Total task completions tracked
    public private(set) var taskCount: Int

    /// UserDefaults key for persistence
    private static let persistenceKey = "growingPlantTaskCount"

    public init() {
        let count = UserDefaults.standard.integer(forKey: Self.persistenceKey)
        self.taskCount = count
        self.stage = GrowthStage.stage(for: count)

        let texture = TextureManager.shared.texture(for: stage.textureName)
        super.init(texture: texture, color: .clear, size: stage.displaySize)
        self.name = "growing_plant"
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    /// Records a task completion. If growth stage changes, animates the transition.
    public func recordCompletion() {
        taskCount += 1
        UserDefaults.standard.set(taskCount, forKey: Self.persistenceKey)

        let newStage = GrowthStage.stage(for: taskCount)
        if newStage != stage {
            stage = newStage
            animateGrowth()
        }
    }

    private func animateGrowth() {
        let newTexture = TextureManager.shared.texture(for: stage.textureName)
        let newSize = stage.displaySize

        // Scale bounce + texture swap
        let bounceUp = SKAction.scale(to: 1.2, duration: 0.15)
        bounceUp.timingMode = .easeOut
        let swap = SKAction.run { [weak self] in
            self?.texture = newTexture
            self?.size = newSize
        }
        let bounceDown = SKAction.scale(to: 1.0, duration: 0.15)
        bounceDown.timingMode = .easeIn

        run(SKAction.sequence([bounceUp, swap, bounceDown]))

        // Sparkle burst
        addGrowthSparkle()
    }

    private func addGrowthSparkle() {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 20
        emitter.numParticlesToEmit = 15
        emitter.particleLifetime = 1.0
        emitter.particleColor = SKColor(red: 0.4, green: 0.9, blue: 0.4, alpha: 1.0)
        emitter.particleColorAlphaSpeed = -1.0
        emitter.particleSpeed = 25
        emitter.particleSpeedRange = 10
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi
        emitter.particleScale = 0.2
        emitter.position = CGPoint(x: 0, y: size.height / 2)
        emitter.zPosition = 6
        addChild(emitter)

        emitter.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            SKAction.removeFromParent()
        ]))
    }
}
