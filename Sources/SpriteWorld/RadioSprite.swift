import SpriteKit

/// An office radio decoration that shows animated sound waves when agents are working.
public class RadioSprite: SKNode {

    /// The radio body sprite
    private let body: SKSpriteNode

    /// Animated wave arcs
    private var waves: [SKShapeNode] = []

    /// Whether waves are currently animating
    private var wavesActive: Bool = false

    public override init() {
        let texture = TextureManager.shared.texture(for: TextureManager.decorationRadio)
        body = SKSpriteNode(texture: texture, size: CGSize(width: 40, height: 32))
        super.init()

        self.name = "decoration_radio"
        addChild(body)
        setupWaves()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func setupWaves() {
        for i in 0..<3 {
            let wave = SKShapeNode()
            let path = CGMutablePath()
            let radius = CGFloat(8 + i * 6)
            path.addArc(center: .zero, radius: radius, startAngle: -.pi / 4, endAngle: .pi / 4, clockwise: false)
            wave.path = path
            wave.strokeColor = SKColor(white: 0.8, alpha: 0.6)
            wave.lineWidth = 1.5
            wave.position = CGPoint(x: 20, y: 5)
            wave.alpha = 0
            wave.name = "radio_wave_\(i)"
            wave.zPosition = 1
            addChild(wave)
            waves.append(wave)
        }
    }

    /// Call periodically to update wave animation state.
    public func updateWaves(hasActiveAgents: Bool) {
        if hasActiveAgents && !wavesActive {
            startWaves()
        } else if !hasActiveAgents && wavesActive {
            stopWaves()
        }
    }

    private func startWaves() {
        wavesActive = true
        for (i, wave) in waves.enumerated() {
            let delay = TimeInterval(i) * 0.5
            let pulse = SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.repeatForever(SKAction.sequence([
                    SKAction.group([
                        SKAction.fadeAlpha(to: 0.6, duration: 0.3),
                        SKAction.scale(to: 1.2, duration: 0.3)
                    ]),
                    SKAction.group([
                        SKAction.fadeAlpha(to: 0.0, duration: 1.2),
                        SKAction.scale(to: 0.5, duration: 1.2)
                    ])
                ]))
            ])
            wave.run(pulse, withKey: "pulse")
        }
    }

    private func stopWaves() {
        wavesActive = false
        for wave in waves {
            wave.removeAction(forKey: "pulse")
            wave.run(SKAction.fadeOut(withDuration: 0.5))
        }
    }
}
