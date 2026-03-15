import SpriteKit
import Models
import Services

/// The main SpriteKit scene that renders the office world.
/// Agent sprites move around, sit at desks, and animate based on their current state.
public class OfficeScene: SKScene {

    /// The office layout defining desk positions and walkable areas
    private let layout: OfficeLayout

    /// Active agent sprites, keyed by agent ID
    private var agentSprites: [String: AgentSprite] = [:]

    /// Which desks are currently occupied (deskID -> agentID)
    private var deskAssignments: [Int: String] = [:]

    /// Background node for the office floor/walls
    private var backgroundNode: SKNode?

    // MARK: - Initialization

    public init(layout: OfficeLayout = .defaultLayout()) {
        self.layout = layout
        super.init(size: layout.sceneSize)
        self.scaleMode = .aspectFit
        self.backgroundColor = SKColor(red: 0.92, green: 0.91, blue: 0.88, alpha: 1.0) // Light beige
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Scene Lifecycle

    public override func didMove(to view: SKView) {
        super.didMove(to: view)
        setupOffice()
    }

    // MARK: - Office Setup

    /// Builds the static office environment (desks, walls, decorations).
    private func setupOffice() {
        // TODO: Replace with actual tilemap or sprite-based office art
        // For now, draw simple desk rectangles

        for desk in layout.desks {
            let deskNode = SKShapeNode(rectOf: CGSize(width: 60, height: 40), cornerRadius: 4)
            deskNode.fillColor = SKColor(red: 0.55, green: 0.35, blue: 0.2, alpha: 1.0) // Brown
            deskNode.strokeColor = SKColor(red: 0.4, green: 0.25, blue: 0.15, alpha: 1.0)
            deskNode.lineWidth = 1.5
            deskNode.position = desk.position
            deskNode.name = "desk_\(desk.id)"
            addChild(deskNode)

            // Chair (small circle in front of the desk)
            let chairNode = SKShapeNode(circleOfRadius: 10)
            chairNode.fillColor = SKColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
            chairNode.strokeColor = .clear
            chairNode.position = desk.chairPosition
            addChild(chairNode)
        }

        // TODO: Add walls, floor tiles, plants, coffee machine, etc.
        // TODO: Add ambient decorations (clock, whiteboard, etc.)

        // Office title label
        let titleLabel = SKLabelNode(text: "The Bullpen")
        titleLabel.fontName = "Helvetica-Bold"
        titleLabel.fontSize = 18
        titleLabel.fontColor = SKColor(white: 0.4, alpha: 1.0)
        titleLabel.position = CGPoint(x: layout.sceneSize.width / 2, y: layout.sceneSize.height - 30)
        addChild(titleLabel)
    }

    // MARK: - Agent Management

    /// Synchronizes the scene with the current list of agents.
    /// Call this from the main update loop whenever AgentMonitorService publishes changes.
    public func updateAgents(_ agents: [AgentInfo]) {
        let currentIDs = Set(agents.map(\.id))
        let existingIDs = Set(agentSprites.keys)

        // Remove sprites for agents that are no longer present
        for removedID in existingIDs.subtracting(currentIDs) {
            removeAgentSprite(id: removedID)
        }

        // Add or update sprites for current agents
        for agent in agents {
            if let existingSprite = agentSprites[agent.id] {
                existingSprite.update(with: agent)
            } else {
                addAgentSprite(for: agent)
            }
        }
    }

    /// Creates and adds a new agent sprite to the scene.
    private func addAgentSprite(for agent: AgentInfo) {
        let sprite = AgentSprite(agentInfo: agent)

        // Assign a desk
        let occupiedDeskIDs = Set(deskAssignments.keys)
        if let desk = layout.nextAvailableDesk(occupiedDeskIDs: occupiedDeskIDs) {
            sprite.assignedDeskID = desk.id
            deskAssignments[desk.id] = agent.id

            // Start at the entrance, then walk to desk
            let entrancePoint = CGPoint(x: layout.sceneSize.width / 2, y: 50)
            sprite.position = entrancePoint

            addChild(sprite)
            agentSprites[agent.id] = sprite

            // Walk to assigned desk
            let path = layout.findPath(from: entrancePoint, to: desk.chairPosition)
            sprite.walk(to: desk.chairPosition, via: path) {
                sprite.playAnimation(for: agent.state)
            }
        } else {
            // No desk available — just stand near the entrance
            sprite.position = CGPoint(
                x: CGFloat.random(in: 100...layout.sceneSize.width - 100),
                y: 80
            )
            addChild(sprite)
            agentSprites[agent.id] = sprite
        }
    }

    /// Removes an agent sprite from the scene.
    private func removeAgentSprite(id: String) {
        guard let sprite = agentSprites.removeValue(forKey: id) else { return }

        // Free up the desk
        if let deskID = sprite.assignedDeskID {
            deskAssignments.removeValue(forKey: deskID)
        }

        // Fade out and remove
        sprite.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Update Loop

    public override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        // TODO: Add ambient animations (clock ticking, random decorations, etc.)
    }
}

