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

    /// Callback fired when an agent sprite is clicked. The parameter is the agent ID,
    /// or nil if the click landed on empty space. (7.5)
    public var onAgentClicked: ((String?) -> Void)?

    /// Which desks are currently occupied (deskID -> agentID)
    private var deskAssignments: [Int: String] = [:]

    /// Background node for the office floor/walls
    private var backgroundNode: SKNode?

    /// The office cat sprite (8.9-8.13)
    public private(set) var catSprite: CatSprite?

    /// Last update time for delta calculation
    private var lastUpdateTime: TimeInterval = 0

    /// Last time we updated window daylight
    private var lastDaylightUpdate: TimeInterval = 0

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
        setupTiledBackground()
        setupDesks()
        setupDecorations()
        setupTitleLabel()
        setupAmbientAnimations()
        setupCat()
    }

    // MARK: - 6.4: Tiled Background

    /// Tiles the background with repeating tile-sized nodes.
    private func setupTiledBackground() {
        let tileSize: CGFloat = 32

        // Wall (top 1/3) — tile-sized nodes
        let wallTexture = TextureManager.shared.texture(for: TextureManager.tileWall)
        let wallHeight = layout.sceneSize.height / 3
        let wallBottom = layout.sceneSize.height - wallHeight

        var x: CGFloat = tileSize / 2
        while x < layout.sceneSize.width {
            var y = wallBottom + tileSize / 2
            while y < layout.sceneSize.height {
                let tile = SKSpriteNode(texture: wallTexture, size: CGSize(width: tileSize, height: tileSize))
                tile.position = CGPoint(x: x, y: y)
                tile.zPosition = -10
                addChild(tile)
                y += tileSize
            }
            x += tileSize
        }

        // Add a single named wall node for test compatibility
        let wall = SKSpriteNode(
            color: .clear,
            size: CGSize(width: layout.sceneSize.width, height: wallHeight)
        )
        wall.position = CGPoint(
            x: layout.sceneSize.width / 2,
            y: layout.sceneSize.height - wallHeight / 2
        )
        wall.name = "wall"
        wall.zPosition = -11
        addChild(wall)

        // Floor (bottom 2/3) — tile-sized nodes
        let floorTexture = TextureManager.shared.texture(for: TextureManager.tileFloor)
        let floorHeight = layout.sceneSize.height * 2 / 3

        x = tileSize / 2
        while x < layout.sceneSize.width {
            var y: CGFloat = tileSize / 2
            while y < floorHeight {
                let tile = SKSpriteNode(texture: floorTexture, size: CGSize(width: tileSize, height: tileSize))
                tile.position = CGPoint(x: x, y: y)
                tile.zPosition = -10
                addChild(tile)
                y += tileSize
            }
            x += tileSize
        }

        // Add a single named floor node for test compatibility
        let floor = SKSpriteNode(
            color: .clear,
            size: CGSize(width: layout.sceneSize.width, height: floorHeight)
        )
        floor.position = CGPoint(
            x: layout.sceneSize.width / 2,
            y: floorHeight / 2
        )
        floor.name = "floor"
        floor.zPosition = -11
        addChild(floor)

        // Floor grain lines (thin horizontal lines) — task 4.3
        let grainColor = SKColor(red: 0.659, green: 0.596, blue: 0.510, alpha: 0.3)
        let grainSpacing: CGFloat = 20
        var grainY = grainSpacing
        while grainY < floorHeight {
            let grainLine = SKShapeNode(
                rect: CGRect(
                    x: 0,
                    y: grainY - 0.5,
                    width: layout.sceneSize.width,
                    height: 1
                )
            )
            grainLine.fillColor = grainColor
            grainLine.strokeColor = .clear
            grainLine.name = "floorGrain"
            grainLine.zPosition = -9
            addChild(grainLine)
            grainY += grainSpacing
        }
    }

    // MARK: - 6.3: Furniture Textures

    /// Sets up desks with texture-based rendering.
    private func setupDesks() {
        let tm = TextureManager.shared

        for desk in layout.desks {
            // Desk — use texture
            let deskTexture = tm.texture(for: TextureManager.furnitureDesk)
            let deskNode = SKSpriteNode(texture: deskTexture, size: CGSize(width: 60, height: 40))
            deskNode.position = desk.position
            deskNode.name = "desk_\(desk.id)"
            deskNode.zPosition = 1
            addChild(deskNode)

            // Chair — pushed back 5 points for empty desk ambient state (8.5)
            let chairTexture = tm.texture(for: TextureManager.furnitureChair)
            let chairNode = SKSpriteNode(texture: chairTexture, size: CGSize(width: 20, height: 20))
            chairNode.position = CGPoint(x: 0, y: -45)
            chairNode.name = "chair_\(desk.id)"
            deskNode.addChild(chairNode)

            // Monitor (off by default)
            let monitorTexture = tm.texture(for: TextureManager.furnitureMonitorOff)
            let monitorNode = SKSpriteNode(texture: monitorTexture, size: CGSize(width: 20, height: 14))
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

            // Coffee mug on each desk (6.17)
            let mugTexture = tm.texture(for: TextureManager.furnitureCoffeeMug)
            let mugNode = SKSpriteNode(texture: mugTexture, size: CGSize(width: 10, height: 12))
            mugNode.position = CGPoint(x: 22, y: 5)
            mugNode.name = "coffeeMug_\(desk.id)"
            mugNode.zPosition = 2
            deskNode.addChild(mugNode)

            // Steam emitter on coffee mug (6.15) with horizontal wobble (8.3)
            let steam = createSteamEmitter()
            steam.position = CGPoint(x: 22, y: 12)
            steam.name = "steamEmitter_\(desk.id)"
            steam.zPosition = 4
            deskNode.addChild(steam)

            // Lamp on alternating desks (6.17)
            if desk.id % 2 == 0 {
                let lampTexture = tm.texture(for: TextureManager.furnitureLamp)
                let lampNode = SKSpriteNode(texture: lampTexture, size: CGSize(width: 16, height: 32))
                lampNode.position = CGPoint(x: -22, y: 10)
                lampNode.name = "lamp_\(desk.id)"
                lampNode.zPosition = 2
                deskNode.addChild(lampNode)
            }
        }
    }

    // MARK: - 6.15: Coffee Mug Steam Particles

    /// Creates a subtle steam emitter for coffee mugs with horizontal wobble (8.3).
    private func createSteamEmitter() -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 1
        emitter.particleLifetime = 2.0
        emitter.particleLifetimeRange = 0.5
        emitter.particleColor = SKColor(white: 1.0, alpha: 0.3)
        emitter.particleColorAlphaSpeed = -0.15
        emitter.particleSpeed = 5
        emitter.particleSpeedRange = 2
        emitter.emissionAngle = .pi / 2 // Upward
        emitter.emissionAngleRange = .pi / 8
        emitter.particleScale = 0.2
        emitter.particleScaleSpeed = 0.05
        emitter.particleAlpha = 0.3
        emitter.particleAlphaSpeed = -0.15
        // 8.3: Slight horizontal wobble via position range
        emitter.particlePositionRange = CGVector(dx: 2, dy: 0)
        emitter.xAcceleration = 1.5
        return emitter
    }

    // MARK: - 6.17: Decorations

    /// Adds static decoration nodes to the office.
    private func setupDecorations() {
        let tm = TextureManager.shared

        // 2 plants at corners
        let plantTexture = tm.texture(for: TextureManager.decorationPlant)

        let plant1 = SKSpriteNode(texture: plantTexture, size: CGSize(width: 24, height: 40))
        plant1.position = CGPoint(x: 40, y: layout.sceneSize.height - 80)
        plant1.name = "decoration_plant_0"
        plant1.zPosition = 2
        addChild(plant1)

        let plant2 = SKSpriteNode(texture: plantTexture, size: CGSize(width: 24, height: 40))
        plant2.position = CGPoint(x: layout.sceneSize.width - 40, y: layout.sceneSize.height - 80)
        plant2.name = "decoration_plant_1"
        plant2.zPosition = 2
        addChild(plant2)

        // Window on back wall
        let windowTexture = tm.texture(for: TextureManager.decorationWindow)
        let windowNode = SKSpriteNode(texture: windowTexture, size: CGSize(width: 80, height: 50))
        windowNode.position = CGPoint(x: layout.sceneSize.width / 2, y: layout.sceneSize.height - 60)
        windowNode.name = "decoration_window"
        windowNode.zPosition = 2
        addChild(windowNode)

        // Whiteboard on side wall
        let whiteboardTexture = tm.texture(for: TextureManager.decorationWhiteboard)
        let whiteboardNode = SKSpriteNode(texture: whiteboardTexture, size: CGSize(width: 100, height: 60))
        whiteboardNode.position = CGPoint(x: 100, y: layout.sceneSize.height - 140)
        whiteboardNode.name = "decoration_whiteboard"
        whiteboardNode.zPosition = 2
        addChild(whiteboardNode)

        // Clock on wall
        let clockTexture = tm.texture(for: TextureManager.decorationClock)
        let clockNode = SKSpriteNode(texture: clockTexture, size: CGSize(width: 20, height: 20))
        clockNode.position = CGPoint(x: layout.sceneSize.width - 100, y: layout.sceneSize.height - 40)
        clockNode.name = "decoration_clock"
        clockNode.zPosition = 2
        addChild(clockNode)
    }

    /// Sets up the title label.
    private func setupTitleLabel() {
        let titleLabel = SKLabelNode(text: "The Bullpen")
        titleLabel.fontName = "Helvetica-Bold"
        titleLabel.fontSize = 18
        titleLabel.fontColor = SKColor(white: 0.4, alpha: 1.0)
        titleLabel.position = CGPoint(x: layout.sceneSize.width / 2, y: layout.sceneSize.height - 30)
        titleLabel.zPosition = 10
        addChild(titleLabel)
    }

    // MARK: - 8.1-8.5: Ambient Animations

    /// Sets up all ambient animations: clock second hand, plant sway, window daylight.
    private func setupAmbientAnimations() {
        setupClockSecondHand()
        setupPlantSway()
        applyWindowDaylight(hour: currentHour())
    }

    /// 8.1: Adds a ticking second hand to the wall clock.
    private func setupClockSecondHand() {
        guard let clockNode = childNode(withName: "decoration_clock") else { return }

        let secondHand = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 8))
        secondHand.path = path
        secondHand.strokeColor = SKColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1.0)
        secondHand.lineWidth = 1
        secondHand.name = "clock_second_hand"
        secondHand.zPosition = 3
        clockNode.addChild(secondHand)

        // Rotate 6 degrees per second clockwise (negative angle = clockwise in SpriteKit)
        let rotate = SKAction.rotate(byAngle: -.pi / 30, duration: 1.0)
        secondHand.run(SKAction.repeatForever(rotate), withKey: "tick")
    }

    /// 8.2: Adds subtle sway animation to plant decoration nodes.
    private func setupPlantSway() {
        for i in 0...1 {
            guard let plantNode = childNode(withName: "decoration_plant_\(i)") else { continue }

            let swayLeft = SKAction.rotate(byAngle: CGFloat.pi / 90, duration: 1.5) // ~2 degrees
            swayLeft.timingMode = .easeInEaseOut
            let swayRight = swayLeft.reversed()
            let sway = SKAction.sequence([swayLeft, swayRight])
            plantNode.run(SKAction.repeatForever(sway), withKey: "sway")
        }
    }

    /// 8.4: Returns the daylight color for a given hour (0-23).
    /// Public for testing.
    public static func daylightColor(for hour: Int) -> SKColor {
        switch hour {
        case 6..<12:
            // Morning: warm yellow #F5E6C8
            return SKColor(red: 0.961, green: 0.902, blue: 0.784, alpha: 1.0)
        case 12..<18:
            // Afternoon: bright white #FFFFFF
            return SKColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        case 18..<21:
            // Evening: warm orange #E8C090
            return SKColor(red: 0.910, green: 0.753, blue: 0.565, alpha: 1.0)
        default:
            // Night (9pm-6am): dark blue #4060A0
            return SKColor(red: 0.251, green: 0.376, blue: 0.627, alpha: 1.0)
        }
    }

    /// Returns the current hour (0-23).
    private func currentHour() -> Int {
        Calendar.current.component(.hour, from: Date())
    }

    /// 8.4: Applies daylight color to the window decoration node.
    /// Accepts an hour parameter for testability.
    public func applyWindowDaylight(hour: Int) {
        guard let windowNode = childNode(withName: "decoration_window") as? SKSpriteNode else { return }
        let color = Self.daylightColor(for: hour)
        windowNode.removeAction(forKey: "daylight")
        windowNode.color = color
        let colorize = SKAction.colorize(with: color, colorBlendFactor: 0.4, duration: 2.0)
        windowNode.run(colorize, withKey: "daylight")
    }

    // MARK: - 8.9-8.13: Office Cat

    /// Sets up the office cat sprite.
    private func setupCat() {
        let cat = CatSprite()
        // Place near a corner initially
        cat.position = CGPoint(x: 80, y: 100)
        addChild(cat)
        catSprite = cat
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

    // MARK: - Monitor Management — task 4.4, 4.11, 6.3

    /// Turns on a desk monitor with the "on" texture
    private func turnOnMonitor(deskID: Int, state: AgentState) {
        guard let deskNode = childNode(withName: "desk_\(deskID)") else { return }
        if let monitor = deskNode.childNode(withName: "monitor_\(deskID)") as? SKSpriteNode {
            let onTexture = TextureManager.shared.texture(for: TextureManager.furnitureMonitorOn)
            monitor.texture = onTexture
        }
        updateMonitorGlow(deskID: deskID, state: state)
    }

    /// Turns off a desk monitor
    private func turnOffMonitor(deskID: Int) {
        guard let deskNode = childNode(withName: "desk_\(deskID)") else { return }
        if let monitor = deskNode.childNode(withName: "monitor_\(deskID)") as? SKSpriteNode {
            let offTexture = TextureManager.shared.texture(for: TextureManager.furnitureMonitorOff)
            monitor.texture = offTexture
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
            glow.fillColor = SKColor(red: 0.314, green: 0.784, blue: 0.471, alpha: 1.0)
            glow.alpha = 0.15
        case .runningCommand:
            glow.fillColor = SKColor(red: 0.910, green: 0.565, blue: 0.251, alpha: 1.0)
            glow.alpha = 0.10
        case .idle:
            glow.fillColor = SKColor(red: 0.376, green: 0.565, blue: 0.816, alpha: 1.0)
            glow.alpha = 0.08
        case .error:
            glow.fillColor = SKColor(red: 0.878, green: 0.314, blue: 0.314, alpha: 1.0)
            let flickerUp = SKAction.fadeAlpha(to: 0.20, duration: 0.3)
            let flickerDown = SKAction.fadeAlpha(to: 0.05, duration: 0.3)
            let flicker = SKAction.sequence([flickerUp, flickerDown])
            glow.run(SKAction.repeatForever(flicker))
        default:
            glow.fillColor = SKColor(red: 0.376, green: 0.565, blue: 0.816, alpha: 1.0)
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

    /// Returns the current desk assignments (for cat update)
    public var currentDeskAssignments: [Int: String] {
        deskAssignments
    }

    // MARK: - Click Detection (7.5)

    public override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        let nodes = self.nodes(at: location)

        if let agentSprite = nodes.compactMap({ $0 as? AgentSprite ?? $0.parent as? AgentSprite }).first {
            onAgentClicked?(agentSprite.agentInfo.id)
        } else {
            onAgentClicked?(nil)
        }
    }

    // MARK: - Update Loop

    public override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)

        // Calculate delta time
        let deltaTime = lastUpdateTime > 0 ? currentTime - lastUpdateTime : 0
        lastUpdateTime = currentTime

        // Update idle ZZZ for all agent sprites
        for sprite in agentSprites.values {
            sprite.updateIdleZZZ(currentTime: currentTime)
        }

        // Update office cat (8.10-8.13)
        if let cat = catSprite {
            let agents = agentSprites.values.map(\.agentInfo)
            let deskPositions = layout.desks.map { (id: $0.id, position: $0.chairPosition) }
            let activeDeskIDs = Set(deskAssignments.keys)
            cat.update(deltaTime: deltaTime, agents: agents, deskPositions: deskPositions, activeDeskIDs: activeDeskIDs)
        }

        // Periodically update window daylight (every 60 seconds)
        if currentTime - lastDaylightUpdate > 60.0 {
            lastDaylightUpdate = currentTime
            applyWindowDaylight(hour: currentHour())
        }
    }
}
