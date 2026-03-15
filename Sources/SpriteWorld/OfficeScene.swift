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
    /// Public for testing purposes.
    public func setupOffice() {
        // Wall (top 1/3) — task 4.3
        let wall = SKSpriteNode(
            color: SKColor(red: 0.918, green: 0.902, blue: 0.875, alpha: 1.0),
            size: CGSize(width: layout.sceneSize.width, height: layout.sceneSize.height / 3)
        )
        wall.position = CGPoint(
            x: layout.sceneSize.width / 2,
            y: layout.sceneSize.height - layout.sceneSize.height / 6
        )
        wall.name = "wall"
        wall.zPosition = -10
        addChild(wall)

        // Floor (bottom 2/3) — task 4.3
        let floor = SKSpriteNode(
            color: SKColor(red: 0.769, green: 0.714, blue: 0.627, alpha: 1.0),
            size: CGSize(width: layout.sceneSize.width, height: layout.sceneSize.height * 2 / 3)
        )
        floor.position = CGPoint(
            x: layout.sceneSize.width / 2,
            y: layout.sceneSize.height / 3
        )
        floor.name = "floor"
        floor.zPosition = -10
        addChild(floor)

        // Floor grain lines (thin horizontal lines) — task 4.3
        let grainColor = SKColor(red: 0.659, green: 0.596, blue: 0.510, alpha: 0.3) // #A89882 at 30%
        let floorTop = layout.sceneSize.height * 2 / 3
        let grainSpacing: CGFloat = 20
        var y = grainSpacing
        while y < floorTop {
            let grainLine = SKShapeNode(
                rect: CGRect(
                    x: 0,
                    y: y - 0.5,
                    width: layout.sceneSize.width,
                    height: 1
                )
            )
            grainLine.fillColor = grainColor
            grainLine.strokeColor = .clear
            grainLine.name = "floorGrain"
            grainLine.zPosition = -9
            addChild(grainLine)
            y += grainSpacing
        }

        // Desks with chairs and monitors — task 4.4
        for desk in layout.desks {
            let deskNode = SKShapeNode(rectOf: CGSize(width: 60, height: 40), cornerRadius: 4)
            deskNode.fillColor = SKColor(red: 0.55, green: 0.35, blue: 0.2, alpha: 1.0) // Brown
            deskNode.strokeColor = SKColor(red: 0.4, green: 0.25, blue: 0.15, alpha: 1.0)
            deskNode.lineWidth = 1.5
            deskNode.position = desk.position
            deskNode.name = "desk_\(desk.id)"
            deskNode.zPosition = 1
            addChild(deskNode)

            // Chair (small circle in front of the desk)
            let chairNode = SKShapeNode(circleOfRadius: 10)
            chairNode.fillColor = SKColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
            chairNode.strokeColor = .clear
            chairNode.position = CGPoint(x: 0, y: -40)
            chairNode.name = "chair_\(desk.id)"
            deskNode.addChild(chairNode)

            // Monitor on each desk (small rectangle) — task 4.4
            let monitorNode = SKShapeNode(rectOf: CGSize(width: 20, height: 14), cornerRadius: 2)
            monitorNode.fillColor = SKColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0) // Dark/off
            monitorNode.strokeColor = SKColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
            monitorNode.lineWidth = 1.0
            monitorNode.position = CGPoint(x: 0, y: 8)
            monitorNode.name = "monitor_\(desk.id)"
            monitorNode.zPosition = 2
            deskNode.addChild(monitorNode)

            // Monitor glow node (initially invisible) — task 4.11
            let glowNode = SKShapeNode(rectOf: CGSize(width: 30, height: 24), cornerRadius: 4)
            glowNode.fillColor = .clear
            glowNode.strokeColor = .clear
            glowNode.position = CGPoint(x: 0, y: 8)
            glowNode.name = "monitorGlow_\(desk.id)"
            glowNode.zPosition = 3
            glowNode.alpha = 0
            deskNode.addChild(glowNode)
        }

        // Office title label
        let titleLabel = SKLabelNode(text: "The Bullpen")
        titleLabel.fontName = "Helvetica-Bold"
        titleLabel.fontSize = 18
        titleLabel.fontColor = SKColor(white: 0.4, alpha: 1.0)
        titleLabel.position = CGPoint(x: layout.sceneSize.width / 2, y: layout.sceneSize.height - 30)
        titleLabel.zPosition = 10
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

        // Update monitor states based on desk assignments
        updateMonitorStates(agents: agents)
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

            // Turn on monitor
            turnOnMonitor(deskID: desk.id, state: agent.state)
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

        // Free up the desk and turn off monitor
        if let deskID = sprite.assignedDeskID {
            deskAssignments.removeValue(forKey: deskID)
            turnOffMonitor(deskID: deskID)
        }

        // Fade out and remove
        sprite.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Monitor Management — task 4.4, 4.11

    /// Turns on a desk monitor with a blue glow
    private func turnOnMonitor(deskID: Int, state: AgentState) {
        guard let deskNode = childNode(withName: "desk_\(deskID)") else { return }
        if let monitor = deskNode.childNode(withName: "monitor_\(deskID)") as? SKShapeNode {
            monitor.fillColor = SKColor(red: 0.2, green: 0.3, blue: 0.5, alpha: 1.0) // Blue glow on
        }
        updateMonitorGlow(deskID: deskID, state: state)
    }

    /// Turns off a desk monitor
    private func turnOffMonitor(deskID: Int) {
        guard let deskNode = childNode(withName: "desk_\(deskID)") else { return }
        if let monitor = deskNode.childNode(withName: "monitor_\(deskID)") as? SKShapeNode {
            monitor.fillColor = SKColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0) // Dark/off
        }
        if let glow = deskNode.childNode(withName: "monitorGlow_\(deskID)") as? SKShapeNode {
            glow.removeAllActions()
            glow.alpha = 0
            glow.fillColor = .clear
        }
    }

    /// Updates monitor glow color/opacity based on agent state — task 4.11
    private func updateMonitorGlow(deskID: Int, state: AgentState) {
        guard let deskNode = childNode(withName: "desk_\(deskID)") else { return }
        guard let glow = deskNode.childNode(withName: "monitorGlow_\(deskID)") as? SKShapeNode else { return }

        glow.removeAllActions()

        switch state {
        case .writingCode:
            glow.fillColor = SKColor(red: 0.314, green: 0.784, blue: 0.471, alpha: 1.0) // #50C878
            glow.alpha = 0.15
        case .runningCommand:
            glow.fillColor = SKColor(red: 0.910, green: 0.565, blue: 0.251, alpha: 1.0) // #E89040
            glow.alpha = 0.10
        case .idle:
            glow.fillColor = SKColor(red: 0.376, green: 0.565, blue: 0.816, alpha: 1.0) // #6090D0
            glow.alpha = 0.08
        case .error:
            // Red flicker alternating 20%/5% opacity
            glow.fillColor = SKColor(red: 0.878, green: 0.314, blue: 0.314, alpha: 1.0) // #E05050
            let flickerUp = SKAction.fadeAlpha(to: 0.20, duration: 0.3)
            let flickerDown = SKAction.fadeAlpha(to: 0.05, duration: 0.3)
            let flicker = SKAction.sequence([flickerUp, flickerDown])
            glow.run(SKAction.repeatForever(flicker))
        default:
            // For other states, use a subtle blue glow
            glow.fillColor = SKColor(red: 0.376, green: 0.565, blue: 0.816, alpha: 1.0) // #6090D0
            glow.alpha = 0.05
        }
    }

    /// Updates all monitor states based on current agent assignments
    private func updateMonitorStates(agents: [AgentInfo]) {
        for (deskID, agentID) in deskAssignments {
            if let agent = agents.first(where: { $0.id == agentID }) {
                updateMonitorGlow(deskID: deskID, state: agent.state)
            }
        }
    }

    // MARK: - Public Accessors for Testing

    /// Returns the number of active agent sprites
    public var agentSpriteCount: Int {
        agentSprites.count
    }

    /// Returns agent sprite positions (for uniqueness testing)
    public var agentSpritePositions: [CGPoint] {
        agentSprites.values.map(\.position)
    }

    /// Returns a specific agent sprite by ID
    public func agentSprite(forID id: String) -> AgentSprite? {
        agentSprites[id]
    }

    // MARK: - Update Loop

    public override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
    }
}
