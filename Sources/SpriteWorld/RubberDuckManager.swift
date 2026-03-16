import SpriteKit
import Models

/// Manages rubber duck debugging — when an agent is in error state for >30s,
/// a rubber duck appears on their desk. Removes when leaving error state.
@MainActor
public class RubberDuckManager {

    /// Tracks which desks currently have ducks
    private var ducksOnDesks: Set<Int> = []

    /// Error duration threshold before duck appears (seconds)
    private let errorThreshold: TimeInterval = 30.0

    public init() {}

    /// Call each frame from OfficeScene.update()
    public func update(agents: [AgentInfo], deskAssignments: [Int: String], scene: SKScene) {
        // Track which desks should have ducks
        var desksNeedingDuck: Set<Int> = []

        for (deskID, agentID) in deskAssignments {
            guard let agent = agents.first(where: { $0.id == agentID }) else { continue }

            if agent.state == .error {
                let errorDuration = Date().timeIntervalSince(agent.stateEnteredAt)
                if errorDuration >= errorThreshold {
                    desksNeedingDuck.insert(deskID)
                }
            }
        }

        // Add ducks to desks that need them
        for deskID in desksNeedingDuck where !ducksOnDesks.contains(deskID) {
            addDuck(toDeskID: deskID, scene: scene)
        }

        // Remove ducks from desks that no longer need them
        for deskID in ducksOnDesks where !desksNeedingDuck.contains(deskID) {
            removeDuck(fromDeskID: deskID, scene: scene)
        }
    }

    private func addDuck(toDeskID deskID: Int, scene: SKScene) {
        guard let desk = scene.childNode(withName: "desk_\(deskID)") else { return }

        let duck = SKSpriteNode(
            texture: TextureManager.shared.texture(for: TextureManager.itemRubberDuck),
            size: CGSize(width: 24, height: 24)
        )
        duck.position = CGPoint(x: -20, y: 12)
        duck.name = "rubberDuck_\(deskID)"
        duck.zPosition = 3
        duck.alpha = 0
        desk.addChild(duck)

        // Pop-in animation
        duck.setScale(0)
        duck.run(SKAction.group([
            SKAction.fadeIn(withDuration: 0.3),
            SKAction.scale(to: 1.0, duration: 0.3)
        ]))

        ducksOnDesks.insert(deskID)
    }

    private func removeDuck(fromDeskID deskID: Int, scene: SKScene) {
        guard let desk = scene.childNode(withName: "desk_\(deskID)"),
              let duck = desk.childNode(withName: "rubberDuck_\(deskID)") else {
            ducksOnDesks.remove(deskID)
            return
        }

        duck.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))

        ducksOnDesks.remove(deskID)
    }

    /// Clears all ducks (e.g., when office resets)
    public func clearAll(scene: SKScene) {
        for deskID in ducksOnDesks {
            if let desk = scene.childNode(withName: "desk_\(deskID)") {
                desk.childNode(withName: "rubberDuck_\(deskID)")?.removeFromParent()
            }
        }
        ducksOnDesks.removeAll()
    }
}
