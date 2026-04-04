import SpriteKit
import Models

/// Manages desk clutter accumulation — sticky notes and crumpled paper appear
/// as agents work longer at their desks.
@MainActor
public class DeskClutterManager {

    /// Work time per desk in seconds
    private var deskWorkTimers: [Int: TimeInterval] = [:]

    /// Current clutter level per desk (0-4)
    private var clutterLevels: [Int: Int] = [:]

    /// Thresholds: minutes of work -> clutter items added
    private let thresholds: [(minutes: TimeInterval, items: Int)] = [
        (4 * 60, 1),   // 4 min -> 1 sticky note
        (12 * 60, 2),  // 12 min -> 2 sticky notes
    ]

    /// Sticky note texture names for color variety
    private let stickyColors = [
        TextureManager.itemStickyNoteYellow,
        TextureManager.itemStickyNotePink,
        TextureManager.itemStickyNoteBlue,
    ]

    private static let workingStates: Set<AgentState> = [.thinking, .writingCode, .readingFiles, .runningCommand, .searching, .supervisingAgents]

    public init() {}

    /// Call each frame from OfficeScene.update()
    public func update(deltaTime: TimeInterval, agents: [AgentInfo], deskAssignments: [Int: String], scene: SKScene) {
        for (deskID, agentID) in deskAssignments {
            guard let agent = agents.first(where: { $0.id == agentID }) else { continue }

            let isWorking = Self.workingStates.contains(agent.state)

            if isWorking {
                deskWorkTimers[deskID, default: 0] += deltaTime
                updateClutter(forDeskID: deskID, scene: scene)
            }
        }
    }

    private func updateClutter(forDeskID deskID: Int, scene: SKScene) {
        let workTime = deskWorkTimers[deskID] ?? 0
        let currentLevel = clutterLevels[deskID] ?? 0

        // Find the highest threshold met
        var targetLevel = 0
        for threshold in thresholds {
            if workTime >= threshold.minutes {
                targetLevel = threshold.items
            }
        }

        guard targetLevel > currentLevel else { return }

        // Add new clutter items
        guard let desk = scene.childNode(withName: "desk_\(deskID)") else { return }

        for idx in currentLevel..<targetLevel {
            let colorName = stickyColors[idx % stickyColors.count]
            let itemNode = SKSpriteNode(
                texture: TextureManager.shared.texture(for: colorName),
                size: CGSize(width: 12, height: 12)
            )

            // Randomized position on desk surface
            let xOffset = CGFloat.random(in: -18...18)
            let yOffset = CGFloat.random(in: 4...14)
            itemNode.position = CGPoint(x: xOffset, y: yOffset)
            itemNode.name = "clutter_\(deskID)_\(idx)"
            itemNode.zPosition = 3
            itemNode.zRotation = CGFloat.random(in: -0.2...0.2)

            // Fade in
            itemNode.alpha = 0
            itemNode.run(SKAction.fadeIn(withDuration: 0.5))

            desk.addChild(itemNode)
        }

        clutterLevels[deskID] = targetLevel
    }

    /// Clears all clutter from a desk (e.g., when agent leaves).
    public func clearClutter(forDeskID deskID: Int, scene: SKScene) {
        guard let desk = scene.childNode(withName: "desk_\(deskID)") else { return }

        for idx in 0..<2 {
            if let clutter = desk.childNode(withName: "clutter_\(deskID)_\(idx)") {
                clutter.run(SKAction.sequence([
                    SKAction.fadeOut(withDuration: 0.3),
                    SKAction.removeFromParent()
                ]))
            }
        }

        deskWorkTimers.removeValue(forKey: deskID)
        clutterLevels.removeValue(forKey: deskID)
    }
}
