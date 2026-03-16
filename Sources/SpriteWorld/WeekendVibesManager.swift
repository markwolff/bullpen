import SpriteKit

/// Manages weekend visual changes — on Saturdays and Sundays:
/// - Cat sleeps on a desk
/// - Poster and bulletin board hidden
/// - Warmer scene tint
@MainActor
public class WeekendVibesManager {

    /// Whether weekend mode is active
    public private(set) var isWeekend: Bool = false

    public init() {}

    /// Check and apply weekend state. Call during setup and periodically.
    public func update(scene: SKScene, catSprite: CatSprite?) {
        let weekday = Calendar.current.component(.weekday, from: Date())
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
        scene.childNode(withName: "decoration_poster")?.run(SKAction.fadeAlpha(to: 0, duration: 1.0))
        scene.childNode(withName: "decoration_bulletin_board")?.run(SKAction.fadeAlpha(to: 0, duration: 1.0))

        // Cat sleeps on a random desk
        if let cat = catSprite {
            let deskID = Int.random(in: 0..<16)
            if let desk = scene.childNode(withName: "desk_\(deskID)") {
                let destination = CGPoint(x: desk.position.x, y: desk.position.y + 5)
                cat.removeAllActions()
                cat.run(SKAction.sequence([
                    SKAction.fadeOut(withDuration: 0.2),
                    SKAction.run {
                        cat.position = destination
                        cat.startSleeping()
                    },
                    SKAction.fadeIn(withDuration: 0.2)
                ]))
            }
        }
    }

    private func deactivateWeekend(scene: SKScene, catSprite: CatSprite?) {
        isWeekend = false

        // Show poster and bulletin board again
        scene.childNode(withName: "decoration_poster")?.run(SKAction.fadeAlpha(to: 1.0, duration: 1.0))
        scene.childNode(withName: "decoration_bulletin_board")?.run(SKAction.fadeAlpha(to: 1.0, duration: 1.0))
    }
}
