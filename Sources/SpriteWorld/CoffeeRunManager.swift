import SpriteKit
import Models

/// Manages coffee runs — agents walk to coffee machine after 5 minutes of continuous work.
/// A coffee cup appears on their desk afterward.
@MainActor
public class CoffeeRunManager {

    /// Cumulative work time per agent in seconds
    private var workTimers: [String: TimeInterval] = [:]

    /// Agents currently on a coffee run
    private var onCoffeeRun: Set<String> = []

    /// Agents who already have a cup on their desk
    private var hasCup: Set<String> = []

    /// Work duration threshold before coffee run (seconds)
    private let workThreshold: TimeInterval = 300 // 5 minutes

    public init() {}

    /// Call each frame from OfficeScene.update().
    /// Returns agent IDs that should go on coffee runs this frame.
    public func update(
        deltaTime: TimeInterval,
        agents: [AgentInfo],
        deskAssignments: [Int: String]
    ) -> [String] {
        var triggeredAgents: [String] = []

        for agent in agents {
            let isWorking = [AgentState.thinking, .writingCode, .readingFiles, .runningCommand, .searching]
                .contains(agent.state)

            if isWorking && !onCoffeeRun.contains(agent.id) {
                workTimers[agent.id, default: 0] += deltaTime

                if (workTimers[agent.id] ?? 0) >= workThreshold && !hasCup.contains(agent.id) {
                    triggeredAgents.append(agent.id)
                    onCoffeeRun.insert(agent.id)
                    workTimers[agent.id] = 0
                }
            } else if !isWorking {
                workTimers[agent.id] = 0
            }
        }

        // Clean up removed agents
        let currentIDs = Set(agents.map(\.id))
        for id in workTimers.keys where !currentIDs.contains(id) {
            workTimers.removeValue(forKey: id)
            onCoffeeRun.remove(id)
            hasCup.remove(id)
        }

        return triggeredAgents
    }

    /// Called when an agent completes their coffee run (arrived back at desk).
    public func coffeeRunCompleted(agentID: String) {
        onCoffeeRun.remove(agentID)
        hasCup.insert(agentID)
    }

    /// Places a coffee cup on the agent's desk.
    public func placeCup(deskID: Int, scene: SKScene) {
        guard let desk = scene.childNode(withName: "desk_\(deskID)") else { return }
        guard desk.childNode(withName: "coffeeCup_\(deskID)") == nil else { return }

        let cup = SKSpriteNode(
            texture: TextureManager.shared.texture(for: TextureManager.itemCoffeeCup),
            size: CGSize(width: 18, height: 18)
        )
        cup.position = CGPoint(x: 18, y: 8)
        cup.name = "coffeeCup_\(deskID)"
        cup.zPosition = 3
        cup.alpha = 0
        desk.addChild(cup)
        cup.run(SKAction.fadeIn(withDuration: 0.3))
    }

    /// Removes coffee cup when agent leaves.
    public func removeCup(deskID: Int, scene: SKScene) {
        guard let desk = scene.childNode(withName: "desk_\(deskID)") else { return }
        desk.childNode(withName: "coffeeCup_\(deskID)")?.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))
    }
}
