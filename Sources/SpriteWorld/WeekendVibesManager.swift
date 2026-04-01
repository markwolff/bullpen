import SpriteKit

/// Manages weekend visual changes — on Saturdays and Sundays:
/// - Cat sleeps on a desk
/// - Poster and bulletin board hidden
/// - Warmer scene tint
@MainActor
public class WeekendVibesManager {
    private let weekdayProvider: @Sendable () -> Int
    private let deskChooser: @Sendable (Range<Int>) -> Int
    private let decorationFadeDuration: TimeInterval
    private let catTransitionDuration: TimeInterval

    /// Whether weekend mode is active
    public private(set) var isWeekend: Bool = false

    public init(
        weekdayProvider: @escaping @Sendable () -> Int = {
            Calendar.current.component(.weekday, from: Date())
        },
        deskChooser: @escaping @Sendable (Range<Int>) -> Int = { range in
            Int.random(in: range)
        },
        decorationFadeDuration: TimeInterval = 1.0,
        catTransitionDuration: TimeInterval = 0.2
    ) {
        self.weekdayProvider = weekdayProvider
        self.deskChooser = deskChooser
        self.decorationFadeDuration = decorationFadeDuration
        self.catTransitionDuration = catTransitionDuration
    }

    /// Check and apply weekend state. Call during setup and periodically.
    public func update(scene: SKScene, catSprite: CatSprite?) {
        let weekday = weekdayProvider()
        let shouldBeWeekend = weekday == 1 || weekday == 7 // Sunday = 1, Saturday = 7

        if shouldBeWeekend && !isWeekend {
            activateWeekend(scene: scene, catSprite: catSprite)
        } else if !shouldBeWeekend && isWeekend {
            deactivateWeekend(scene: scene, catSprite: catSprite)
        }
    }

    private func activateWeekend(scene: SKScene, catSprite: CatSprite?) {
        isWeekend = true

        // Hide poster and bulletin board
        updateDecoration(scene.childNode(withName: "decoration_poster"), alpha: 0)
        updateDecoration(scene.childNode(withName: "decoration_bulletin_board"), alpha: 0)

        // Cat sleeps on a random desk
        if let cat = catSprite {
            let deskID = deskChooser(0..<16)
            if let desk = scene.childNode(withName: "desk_\(deskID)") {
                let destination = CGPoint(x: desk.position.x, y: desk.position.y + 5)
                cat.removeAllActions()
                if catTransitionDuration == 0 {
                    cat.position = destination
                    cat.startSleeping()
                    cat.alpha = 1.0
                } else {
                    cat.run(SKAction.sequence([
                        SKAction.fadeOut(withDuration: catTransitionDuration),
                        SKAction.run {
                            cat.position = destination
                            cat.startSleeping()
                        },
                        SKAction.fadeIn(withDuration: catTransitionDuration)
                    ]))
                }
            }
        }
    }

    private func deactivateWeekend(scene: SKScene, catSprite: CatSprite?) {
        isWeekend = false

        // Show poster and bulletin board again
        updateDecoration(scene.childNode(withName: "decoration_poster"), alpha: 1.0)
        updateDecoration(scene.childNode(withName: "decoration_bulletin_board"), alpha: 1.0)
    }

    private func updateDecoration(_ node: SKNode?, alpha: CGFloat) {
        guard let node else { return }
        if decorationFadeDuration == 0 {
            node.alpha = alpha
        } else {
            node.run(SKAction.fadeAlpha(to: alpha, duration: decorationFadeDuration))
        }
    }
}
