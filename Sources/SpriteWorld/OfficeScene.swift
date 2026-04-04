import SpriteKit
import Models
import Services

public struct OfficeSceneManifest: Codable, Equatable, Sendable {
    public struct DeskAssignment: Codable, Equatable, Sendable {
        public let deskID: Int
        public let agentID: String

        public init(deskID: Int, agentID: String) {
            self.deskID = deskID
            self.agentID = agentID
        }
    }

    public let schemaVersion: String
    public let scenarioID: String
    public let worldPreset: String
    public let seed: UInt64
    public let tickCount: Int
    public let visibleAgentIDs: [String]
    public let stateCounts: [String: Int]
    public let occupiedDeskAssignments: [DeskAssignment]
    public let featureFlags: [String: Bool]

    public init(
        schemaVersion: String = "scene-manifest-v1",
        scenarioID: String,
        worldPreset: String,
        seed: UInt64,
        tickCount: Int,
        visibleAgentIDs: [String],
        stateCounts: [String: Int],
        occupiedDeskAssignments: [DeskAssignment],
        featureFlags: [String: Bool]
    ) {
        self.schemaVersion = schemaVersion
        self.scenarioID = scenarioID
        self.worldPreset = worldPreset
        self.seed = seed
        self.tickCount = tickCount
        self.visibleAgentIDs = visibleAgentIDs.sorted()
        self.stateCounts = stateCounts
        self.occupiedDeskAssignments = occupiedDeskAssignments
        self.featureFlags = featureFlags
    }
}

/// The main SpriteKit scene that renders the office world.
/// Agent sprites move around, sit at desks, and animate based on their current state.
public class OfficeScene: SKScene {
    private enum PhysicsMask {
        static let agent: UInt32 = 0x1 << 0
        static let environment: UInt32 = 0x1 << 1
    }

    /// The office layout defining desk positions and walkable areas
    private var layout: OfficeLayout

    /// Active agent sprites, keyed by agent ID
    private var agentSprites: [String: AgentSprite] = [:]

    /// Agent IDs that are currently fading out (removed but still animating).
    /// Prevents duplicate sprite creation during the fade-out period.
    private var fadingOutAgentIDs: Set<String> = []

    /// Callback fired when an agent sprite is clicked. The parameter is the agent ID,
    /// or nil if the click landed on empty space. (7.5)
    public var onAgentClicked: ((String?) -> Void)?

    /// Which desks are currently occupied (deskID -> agentID)
    private var deskAssignments: [Int: String] = [:]

    /// The current world preset
    public private(set) var worldPreset: WorldPreset

    /// The active theme derived from the world preset
    private var activeTheme: WorldTheme

    /// Allows deterministic tests and screenshot capture to override wall-clock time.
    public var dateProvider: @Sendable () -> Date = { Date() }

    /// Disables custom scene feature updates while still allowing SpriteKit
    /// actions to advance through the engine's own update cycle.
    public var featureUpdatesEnabled: Bool = true

    /// Root node for all themeable environment visuals (wall, floor, rooms, rugs, furniture, decorations)
    private var environmentRoot: SKNode?

    /// Root node for persistent actors (agents, cat, dog)
    private var actorRoot: SKNode?

    /// Whether setupOffice() has been called
    private var isOfficeSetUp: Bool = false

    /// The office cat sprite (8.9-8.13)
    public private(set) var catSprite: CatSprite?

    /// The office dog sprite - Pancake the Maltipoo
    public private(set) var dogSprite: DogSprite?

    /// Last update time for delta calculation
    private var lastUpdateTime: TimeInterval = 0

    /// Last time we updated window daylight
    private var lastDaylightUpdate: TimeInterval = 0

    // MARK: - Feature Managers

    /// Empty office mode manager (0C)
    private let emptyOfficeManager = EmptyOfficeManager()

    /// Night owl mode manager (1D)
    private let nightOwlManager = NightOwlManager()

    /// Rubber duck debugging manager (2A)
    private let rubberDuckManager = RubberDuckManager()

    /// Desk clutter accumulation manager (2B)
    private let deskClutterManager = DeskClutterManager()

    /// Office stats tracker for whiteboard (2C)
    private let officeStatsTracker = OfficeStatsTracker()

    /// Coffee run manager (3A)
    private let coffeeRunManager = CoffeeRunManager()

    /// Water cooler chat manager (3B)
    private let waterCoolerChatManager = WaterCoolerChatManager()

    /// Pair programming manager (3C)
    private let pairProgrammingManager = PairProgrammingManager()

    /// Pizza delivery manager (4A)
    private let pizzaDeliveryManager = PizzaDeliveryManager()

    /// Standup meeting manager (4B)
    private let standupMeetingManager = StandupMeetingManager()

    /// Weekend vibes manager (5A)
    private let weekendVibesManager = WeekendVibesManager()

    /// Achievement tracker (5B)
    private let achievementTracker = AchievementTracker()

    /// Radio sprite reference
    private var radioSprite: RadioSprite?

    /// Growing plant sprite reference
    private var growingPlantSprite: GrowingPlantSprite?

    /// Bird cage decoration
    private var birdCageSprite: BirdCageSprite?

    /// Barista NPC
    private var baristaSprite: BaristaSprite?

    /// Whiteboard stats overlay reference
    private var whiteboardOverlay: WhiteboardStatsOverlay?

    /// Achievement shelf reference
    private var achievementShelf: AchievementShelfSprite?

    /// Last time we updated stats overlay
    private var lastStatsUpdate: TimeInterval = 0

    /// Last time we updated throttled feature managers (2-second cadence)
    private var lastManagerUpdateTime: TimeInterval = 0

    // MARK: - Cached Per-Frame Data

    /// Cached agent infos, updated in updateAgents(_:) to avoid per-frame allocation
    private var cachedAgentInfos: [AgentInfo] = []

    /// Cached active agent count, updated in updateAgents(_:)
    private var cachedActiveAgentCount: Int = 0

    /// Cached desk positions for cat/dog updates, updated when deskAssignments changes
    private var cachedDeskPositions: [(id: Int, position: CGPoint)] = []

    /// Cached set of active desk IDs, updated when deskAssignments changes
    private var cachedActiveDeskIDs: Set<Int> = []

    /// Tracks how long the scene has had zero agents (for auto-pause)
    private var emptySceneTimer: TimeInterval = 0

    // MARK: - Initialization

    public init(layout: OfficeLayout? = nil, worldPreset: WorldPreset = .classicBullpen) {
        self.layout = layout ?? OfficeLayout.layout(for: worldPreset)
        self.worldPreset = worldPreset
        self.activeTheme = WorldTheme.theme(for: worldPreset)
        super.init(size: self.layout.sceneSize)
        self.scaleMode = .aspectFit
        self.backgroundColor = activeTheme.backgroundColor
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
    /// Public for testing purposes. Idempotent — safe to call more than once.
    public func setupOffice() {
        guard !isOfficeSetUp else { return }
        isOfficeSetUp = true

        physicsWorld.gravity = .zero

        // Create the three stable roots
        let envRoot = SKNode()
        envRoot.name = "background_container"
        envRoot.zPosition = -12
        addChild(envRoot)
        environmentRoot = envRoot

        let actors = SKNode()
        actors.name = "actor_root"
        actors.zPosition = 5
        addChild(actors)
        actorRoot = actors

        // Build collision geometry once (invariant across presets)
        setupCollisionGeometry()

        // Build the environment visuals for the current theme
        rebuildEnvironment(for: activeTheme)

        // Spawn persistent actors in actorRoot
        setupCat()
        setupDog()
    }

    // MARK: - World Switching

    /// Switches the scene to a new world preset.
    ///
    /// This is a full restart: clears all agents, desk assignments, and pets,
    /// swaps to the new layout, and rebuilds the entire scene.
    public func applyWorld(_ preset: WorldPreset) {
        worldPreset = preset
        layout = OfficeLayout.layout(for: preset)
        activeTheme = WorldTheme.theme(for: preset)
        backgroundColor = activeTheme.backgroundColor

        // If the scene hasn't been set up yet, didMove(to:) will handle it
        guard isOfficeSetUp else { return }

        // Clear all agents and desk assignments (full restart)
        for (_, sprite) in agentSprites {
            sprite.removeFromParent()
        }
        agentSprites.removeAll()
        deskAssignments.removeAll()
        fadingOutAgentIDs.removeAll()
        cachedDeskPositions.removeAll()
        cachedActiveDeskIDs.removeAll()

        // Remove and recreate pets
        catSprite?.removeFromParent()
        catSprite = nil
        dogSprite?.removeFromParent()
        dogSprite = nil

        // Rebuild collision geometry for new layout
        if let collisionLayer = childNode(withName: "collision_layer") {
            collisionLayer.removeAllChildren()
        }
        setupCollisionGeometry()

        // Rebuild all environment visuals
        rebuildEnvironment(for: activeTheme)

        // Respawn pets in new layout
        setupCat()
        setupDog()

        applyWindowDaylight(hour: currentHour())
    }

    /// Removes and recreates all themeable visuals under `environmentRoot`.
    private func rebuildEnvironment(for theme: WorldTheme) {
        guard let envRoot = environmentRoot else { return }
        envRoot.removeAllChildren()

        setupTiledBackground(theme: theme, parent: envRoot)
        setupRoomArchitecture(theme: theme, parent: envRoot)
        setupRug(theme: theme, parent: envRoot)
        setupDesks(theme: theme, parent: envRoot)
        setupDecorations(parent: envRoot)
        setupFeatureDecorations(parent: envRoot)
        setupAmbientAnimations(theme: theme, parent: envRoot)
    }

    /// Reapplies monitor glow/state for all occupied desks after an environment rebuild.
    private func reapplyMonitorVisuals() {
        for (deskID, agentID) in deskAssignments {
            if let sprite = agentSprites[agentID], sprite.hasDockedLaptopAtDesk {
                applyMonitorState(deskID: deskID, state: sprite.agentInfo.state)
            }
        }
    }

    // MARK: - 6.4: Tiled Background

    /// Tiles the background with wall, floor, and cornice — using theme colors.
    private func setupTiledBackground(theme: WorldTheme, parent: SKNode) {
        let wallHeight = layout.sceneSize.height * 0.44
        let wall = SKSpriteNode(
            color: theme.wallColor,
            size: CGSize(width: layout.sceneSize.width, height: wallHeight)
        )
        wall.position = CGPoint(x: layout.sceneSize.width / 2, y: layout.sceneSize.height - wallHeight / 2)
        wall.name = "wall"
        wall.zPosition = -11
        parent.addChild(wall)

        let floorHeight = layout.sceneSize.height - wallHeight
        let floor = SKSpriteNode(
            color: theme.floorColor,
            size: CGSize(width: layout.sceneSize.width, height: floorHeight)
        )
        floor.position = CGPoint(x: layout.sceneSize.width / 2, y: floorHeight / 2)
        floor.name = "floor"
        floor.zPosition = -11
        parent.addChild(floor)

        let cornice = SKShapeNode(rect: CGRect(x: 0, y: wall.position.y - wallHeight / 2, width: layout.sceneSize.width, height: 8))
        cornice.fillColor = theme.trimColor
        cornice.strokeColor = .clear
        cornice.name = "cornice"
        cornice.zPosition = -10
        parent.addChild(cornice)
    }

    private func setupRoomArchitecture(theme: WorldTheme, parent: SKNode) {
        for room in layout.rooms {
            let shadow = SKShapeNode(rect: room.frame.insetBy(dx: -5, dy: -5), cornerRadius: 18)
            shadow.fillColor = SKColor(white: 0.0, alpha: 0.08)
            shadow.strokeColor = .clear
            shadow.zPosition = -9
            parent.addChild(shadow)

            let panel = SKShapeNode(rect: room.frame, cornerRadius: 16)
            panel.fillColor = theme.roomFillColor(for: room.id)
            panel.strokeColor = theme.roomBorderColor(for: room.id)
            panel.lineWidth = 2
            panel.name = "room_panel_\(room.id)"
            panel.zPosition = -8
            parent.addChild(panel)

            let header = SKShapeNode(rect: CGRect(x: room.frame.minX + 12, y: room.frame.maxY - 26, width: room.frame.width - 24, height: 14), cornerRadius: 7)
            header.fillColor = theme.roomHeaderColor(for: room.id)
            header.strokeColor = .clear
            header.name = "room_header_\(room.id)"
            header.zPosition = -7
            parent.addChild(header)

            let displayName = theme.roomLabel(for: room)
            let label = SKLabelNode(text: displayName.uppercased())
            label.fontName = "Menlo-Bold"
            label.fontSize = 10
            label.fontColor = theme.labelTextColor
            label.horizontalAlignmentMode = .left
            label.position = CGPoint(x: room.frame.minX + 18, y: room.frame.maxY - 22)
            label.name = "room_label_\(room.id)"
            label.zPosition = -6
            parent.addChild(label)
        }

        for barrier in layout.solidPartitions {
            parent.addChild(architectureNode(for: barrier.rect, fillColor: theme.solidWallColor, alpha: 1.0))
        }

        for barrier in layout.glassPartitions {
            let glass = architectureNode(for: barrier.rect, fillColor: theme.glassWallColor, alpha: 0.55)
            glass.strokeColor = theme.glassStrokeColor
            glass.lineWidth = 1.5
            parent.addChild(glass)
        }

        if layout.preset == .classicBullpen {
            setupRecreationAccents(parent: parent)
        }
    }

    private func architectureNode(for rect: CGRect, fillColor: SKColor, alpha: CGFloat) -> SKShapeNode {
        let node = SKShapeNode(rect: rect, cornerRadius: min(rect.width, rect.height) > 12 ? 6 : 2)
        node.fillColor = fillColor
        node.strokeColor = .clear
        node.alpha = alpha
        node.zPosition = -5
        return node
    }

    private func setupRecreationAccents(parent: SKNode) {
        let pingPongShadow = SKShapeNode(rectOf: CGSize(width: 132, height: 68), cornerRadius: 10)
        pingPongShadow.fillColor = SKColor(white: 0.0, alpha: 0.15)
        pingPongShadow.strokeColor = .clear
        pingPongShadow.position = CGPoint(x: 200, y: 278)
        pingPongShadow.zPosition = -3
        parent.addChild(pingPongShadow)

        let pingPong = SKShapeNode(rectOf: CGSize(width: 124, height: 60), cornerRadius: 8)
        pingPong.fillColor = SKColor(red: 0.18, green: 0.44, blue: 0.36, alpha: 1.0)
        pingPong.strokeColor = SKColor(red: 0.88, green: 0.90, blue: 0.86, alpha: 1.0)
        pingPong.lineWidth = 2
        pingPong.position = CGPoint(x: 200, y: 280)
        pingPong.zPosition = -2
        parent.addChild(pingPong)

        let centerLine = SKShapeNode(rectOf: CGSize(width: 3, height: 56), cornerRadius: 1.5)
        centerLine.fillColor = SKColor(white: 0.92, alpha: 1.0)
        centerLine.strokeColor = .clear
        centerLine.position = pingPong.position
        centerLine.zPosition = -1
        parent.addChild(centerLine)

        let net = SKShapeNode(rectOf: CGSize(width: 122, height: 2), cornerRadius: 1)
        net.fillColor = SKColor(white: 0.1, alpha: 0.9)
        net.strokeColor = .clear
        net.position = CGPoint(x: pingPong.position.x, y: pingPong.position.y)
        net.zPosition = 0
        parent.addChild(net)
    }

    // MARK: - Cozy Rug

    /// Adds area rugs using theme colors.
    private func setupRug(theme: WorldTheme, parent: SKNode) {
        for rug in layout.rugs {
            let rugNode = SKShapeNode(rectOf: rug.size, cornerRadius: rug.cornerRadius)
            rugNode.fillColor = theme.rugColor(for: rug.colorSlot.rawValue)
            rugNode.strokeColor = .clear
            rugNode.position = rug.position
            rugNode.name = "rug_\(rug.id)"
            rugNode.zPosition = -7
            parent.addChild(rugNode)
        }
    }

    // MARK: - 6.3: Furniture Textures

    /// Sets up long communal tables with per-seat laptops and chairs — using theme colors.
    private func setupDesks(theme: WorldTheme, parent: SKNode) {
        let tm = TextureManager.shared

        for table in layout.tables {
            let tableWidth = table.width
            switch layout.deskRenderStyle {
            case .classicBench:
                let tableShadow = SKShapeNode(rectOf: CGSize(width: tableWidth + 10, height: 42), cornerRadius: 14)
                tableShadow.fillColor = SKColor(white: 0.0, alpha: 0.12)
                tableShadow.strokeColor = .clear
                tableShadow.position = CGPoint(x: table.centerX, y: table.centerY - 3)
                tableShadow.name = "table_shadow_\(table.id)"
                tableShadow.zPosition = 0
                parent.addChild(tableShadow)

                let tableNode = SKShapeNode(rectOf: CGSize(width: tableWidth, height: 34), cornerRadius: 12)
                tableNode.fillColor = theme.tableColor
                tableNode.strokeColor = .clear
                tableNode.lineWidth = 0
                tableNode.isAntialiased = false
                tableNode.position = CGPoint(x: table.centerX, y: table.centerY)
                tableNode.name = "table_\(table.id)"
                tableNode.zPosition = 1
                parent.addChild(tableNode)

                let accentStrip = SKShapeNode(rectOf: CGSize(width: tableWidth - 24, height: 6), cornerRadius: 3)
                accentStrip.fillColor = theme.tableAccentColor
                accentStrip.strokeColor = .clear
                accentStrip.position = CGPoint(x: 0, y: 8)
                accentStrip.name = "table_accent_\(table.id)"
                accentStrip.zPosition = 2
                tableNode.addChild(accentStrip)

            case .zenChabudai:
                let tableShadow = SKShapeNode(rectOf: CGSize(width: tableWidth + 20, height: 50), cornerRadius: 18)
                tableShadow.fillColor = SKColor(white: 0.0, alpha: 0.10)
                tableShadow.strokeColor = .clear
                tableShadow.position = CGPoint(x: table.centerX, y: table.centerY - 5)
                tableShadow.name = "table_shadow_\(table.id)"
                tableShadow.zPosition = 0
                parent.addChild(tableShadow)

                let tableNode = SKSpriteNode(
                    texture: tm.texture(for: TextureManager.zenChabudaiTable),
                    size: CGSize(width: tableWidth + 24, height: 40)
                )
                tableNode.position = CGPoint(x: table.centerX, y: table.centerY)
                tableNode.name = "table_\(table.id)"
                tableNode.zPosition = 1
                parent.addChild(tableNode)

            case .ruinsWorkbench:
                let tableShadow = SKShapeNode(rectOf: CGSize(width: tableWidth + 12, height: 44), cornerRadius: 10)
                tableShadow.fillColor = SKColor(white: 0.0, alpha: 0.18)
                tableShadow.strokeColor = .clear
                tableShadow.position = CGPoint(x: table.centerX, y: table.centerY - 2)
                tableShadow.name = "table_shadow_\(table.id)"
                tableShadow.zPosition = 0
                parent.addChild(tableShadow)

                let tableNode = SKShapeNode(rectOf: CGSize(width: tableWidth, height: 36), cornerRadius: 8)
                tableNode.fillColor = theme.tableColor
                tableNode.strokeColor = theme.tableAccentColor
                tableNode.lineWidth = 2
                tableNode.position = CGPoint(x: table.centerX, y: table.centerY)
                tableNode.name = "table_\(table.id)"
                tableNode.zPosition = 1
                parent.addChild(tableNode)

                let mossStrip = SKShapeNode(rectOf: CGSize(width: max(28, tableWidth * 0.28), height: 8), cornerRadius: 4)
                mossStrip.fillColor = theme.tableAccentColor.withAlphaComponent(0.9)
                mossStrip.strokeColor = .clear
                mossStrip.position = CGPoint(x: -tableWidth * 0.18, y: 8)
                mossStrip.zPosition = 2
                tableNode.addChild(mossStrip)

                let crackStrip = SKShapeNode(rectOf: CGSize(width: tableWidth - 30, height: 2), cornerRadius: 1)
                crackStrip.fillColor = SKColor(red: 0.18, green: 0.20, blue: 0.18, alpha: 0.9)
                crackStrip.strokeColor = .clear
                crackStrip.position = CGPoint(x: 0, y: -4)
                crackStrip.zPosition = 2
                tableNode.addChild(crackStrip)
            }
        }

        for desk in layout.desks {
            let seatNode = SKNode()
            seatNode.position = desk.position
            seatNode.name = "desk_\(desk.id)"
            parent.addChild(seatNode)

            let seatOffsetY = desk.chairPosition.y - desk.position.y
            let chairNode: SKSpriteNode
            let chairPosition: CGPoint
            switch layout.deskRenderStyle {
            case .classicBench:
                chairNode = SKSpriteNode(
                    texture: tm.texture(for: TextureManager.furnitureChair),
                    size: CGSize(width: 24, height: 32)
                )
                chairPosition = CGPoint(x: 0, y: seatOffsetY)

            case .zenChabudai:
                chairNode = SKSpriteNode(
                    texture: tm.texture(for: TextureManager.zenZabutonCushion),
                    size: CGSize(width: 28, height: 28)
                )
                chairPosition = CGPoint(x: 0, y: seatOffsetY + 4)

            case .ruinsWorkbench:
                chairNode = SKSpriteNode(
                    texture: tm.texture(for: TextureManager.ruinsTiltedDesk),
                    size: CGSize(width: 34, height: 26)
                )
                chairNode.zRotation = desk.id.isMultiple(of: 2) ? -.pi / 48 : .pi / 48
                chairPosition = CGPoint(x: 0, y: seatOffsetY + 8)
            }

            chairNode.position = chairPosition
            chairNode.name = "chair_\(desk.id)"
            seatNode.addChild(chairNode)

            let laptopTexture = tm.texture(for: TextureManager.furnitureLaptopOff)
            let laptopNode = SKSpriteNode(texture: laptopTexture, size: CGSize(width: 30, height: 24))
            laptopNode.position = CGPoint(x: 0, y: layout.deskRenderStyle == .zenChabudai ? 8 : 10)
            laptopNode.name = "monitor_\(desk.id)"
            laptopNode.zPosition = 2
            laptopNode.isHidden = true
            seatNode.addChild(laptopNode)

            let glowNode = SKShapeNode(rectOf: CGSize(width: 30, height: 24), cornerRadius: 3)
            glowNode.fillColor = .clear
            glowNode.strokeColor = .clear
            glowNode.position = laptopNode.position
            glowNode.name = "monitorGlow_\(desk.id)"
            glowNode.zPosition = 3
            glowNode.alpha = 0
            seatNode.addChild(glowNode)
        }
    }

    // MARK: - 6.17: Decorations

    /// Adds static decoration nodes to the office — scaled up pixel art.
    private func setupDecorations(parent: SKNode) {
        let tm = TextureManager.shared

        for spec in layout.decorations {
            let node = SKSpriteNode(texture: tm.texture(for: spec.textureName), size: spec.size)
            node.position = spec.position
            node.name = "decoration_\(spec.id)"
            node.zPosition = spec.zPosition
            parent.addChild(node)
        }
    }

    // MARK: - 8.1-8.5: Ambient Animations

    /// Sets up all ambient animations: clock second hand, plant sway, window daylight, dust motes, rain.
    private func setupAmbientAnimations(theme: WorldTheme, parent: SKNode) {
        setupClockSecondHand(parent: parent)
        setupPlantSway(parent: parent)
        applyWindowDaylight(hour: currentHour())
        setupDustMotes(theme: theme, parent: parent)
        updateRainState()
    }

    /// 8.1: Adds a ticking second hand to the wall clock.
    private func setupClockSecondHand(parent: SKNode) {
        guard let clockNode = matchingEnvironmentNodes(for: ["clock"]).first else { return }

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
    private func setupPlantSway(parent: SKNode) {
        for plantNode in matchingEnvironmentNodes(for: ["plant", "bonsai", "cherry_blossom", "wildflower"]) {
            let swayLeft = SKAction.rotate(byAngle: CGFloat.pi / 90, duration: 1.5) // ~2 degrees
            swayLeft.timingMode = .easeInEaseOut
            let swayRight = swayLeft.reversed()
            let sway = SKAction.sequence([swayLeft, swayRight])
            plantNode.run(SKAction.repeatForever(sway), withKey: "sway")
        }
    }

    /// Floating dust motes that drift through sunbeams near the windows.
    private func setupDustMotes(theme: WorldTheme, parent: SKNode) {
        let hour = currentHour()
        // Only show dust motes during daytime (6am-6pm) when sunlight streams in
        guard hour >= 6 && hour < 18 else { return }

        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 0.8
        emitter.particleLifetime = 8.0
        emitter.particleLifetimeRange = 4.0
        emitter.particleColor = SKColor(white: 1.0, alpha: theme.dustMoteAlpha)
        emitter.particleColorAlphaSpeed = -0.03
        emitter.particleSpeed = 3
        emitter.particleSpeedRange = 2
        emitter.emissionAngle = -.pi / 6 // drift slightly downward-right
        emitter.emissionAngleRange = .pi / 4
        emitter.particleScale = 0.15
        emitter.particleScaleRange = 0.1
        emitter.particleScaleSpeed = 0.01
        emitter.particleAlpha = theme.dustMoteAlpha
        emitter.particleAlphaRange = 0.15
        emitter.xAcceleration = 0.5
        emitter.yAcceleration = -0.3
        // Spread across the upper portion of the scene near windows
        emitter.particlePositionRange = CGVector(dx: layout.sceneSize.width * 0.6, dy: layout.sceneSize.height * 0.3)
        emitter.position = CGPoint(x: layout.sceneSize.width / 2, y: layout.sceneSize.height * 0.75)
        emitter.name = "dust_motes"
        emitter.zPosition = 50
        parent.addChild(emitter)
    }

    // MARK: - Rain on Windows at Night

    /// Adds rain particle emitters to window nodes during nighttime hours.
    private func setupRainOnWindows() {
        guard false else { return }  // Disabled: was hour >= 21 || hour < 6

        for windowNode in matchingEnvironmentNodes(for: ["window"]) {
            // Don't add duplicates
            guard windowNode.childNode(withName: "rain_emitter") == nil else { continue }

            let emitter = SKEmitterNode()
            emitter.particleBirthRate = 4
            emitter.particleLifetime = 0.6
            emitter.particleLifetimeRange = 0.2
            emitter.particleColor = SKColor(red: 0.7, green: 0.8, blue: 1.0, alpha: 0.5)
            emitter.particleColorAlphaSpeed = -0.5
            emitter.particleSpeed = 80
            emitter.particleSpeedRange = 20
            emitter.emissionAngle = -(3 * .pi / 8) // angled downward-right
            emitter.emissionAngleRange = .pi / 16
            emitter.particleScale = 0.08
            emitter.particleScaleSpeed = 0.02
            emitter.particleAlpha = 0.5
            emitter.particleAlphaRange = 0.2
            emitter.particlePositionRange = CGVector(dx: 80, dy: 10)
            emitter.position = CGPoint(x: 0, y: 30)
            emitter.name = "rain_emitter"
            emitter.zPosition = 3
            windowNode.addChild(emitter)
        }
    }

    /// Removes rain emitters from window nodes with a fade-out.
    private func removeRainFromWindows() {
        for windowNode in matchingEnvironmentNodes(for: ["window"]) {
            guard let rain = windowNode.childNode(withName: "rain_emitter") else { continue }
            rain.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 1.0),
                SKAction.removeFromParent()
            ]))
        }
    }

    /// Updates rain state based on current hour. Called from ambient update cycle.
    private func updateRainState() {
        if false {  // Disabled: was hour >= 21 || hour < 6
            setupRainOnWindows()
        } else {
            removeRainFromWindows()
        }
    }

    /// Returns the daylight color for a given hour and world preset.
    /// Public for testing.
    public static func daylightColor(for hour: Int, worldPreset: WorldPreset = .classicBullpen) -> SKColor {
        let theme = WorldTheme.theme(for: worldPreset)
        return theme.daylightColor(for: hour)
    }

    /// Returns the current hour (0-23).
    private func currentHour() -> Int {
        Calendar.current.component(.hour, from: dateProvider())
    }

    /// 8.4: Applies daylight color to all window decoration nodes.
    /// Accepts an hour parameter for testability.
    public func applyWindowDaylight(hour: Int) {
        let color = Self.daylightColor(for: hour, worldPreset: worldPreset)
        let blendFactor = activeTheme.windowBlendFactor
        for windowNode in matchingEnvironmentNodes(for: ["window"]).compactMap({ $0 as? SKSpriteNode }) {
            windowNode.removeAction(forKey: "daylight")
            windowNode.color = color
            let colorize = SKAction.colorize(with: color, colorBlendFactor: blendFactor, duration: 2.0)
            windowNode.run(colorize, withKey: "daylight")
        }
    }

    // MARK: - 8.9-8.13: Office Cat

    /// Sets up the office cat sprite in the actor root.
    private func setupCat() {
        guard let actors = actorRoot else { return }
        let cat = CatSprite()
        cat.navigationLayout = layout
        cat.position = layout.catStartPosition
        actors.addChild(cat)
        catSprite = cat
    }

    // MARK: - Office Dog - Pancake the Maltipoo

    /// Sets up the office dog sprite, bowl, and toys in the actor root.
    private func setupDog() {
        guard let actors = actorRoot else { return }

        // Dog bowl
        let bowlTexture = TextureManager.shared.texture(for: TextureManager.dogBowl)
        let bowl = SKSpriteNode(texture: bowlTexture, size: CGSize(width: 40, height: 24))
        bowl.position = layout.dogBowlPosition
        bowl.zPosition = 2
        bowl.name = "dog_bowl"
        actors.addChild(bowl)

        // Pancake the dog
        let dog = DogSprite()
        dog.navigationLayout = layout
        dog.position = layout.dogSleepPosition
        dog.bowlPosition = layout.dogBowlPosition
        actors.addChild(dog)
        dogSprite = dog

        // Scatter some toys around the office for Pancake
        let toyTextureNames = [TextureManager.dogToyBall, TextureManager.dogToyBone, TextureManager.dogToyRope]
        let toyPositions = layout.dogToyPositions
        for (index, toyPos) in toyPositions.enumerated() {
            let textureName = toyTextureNames[index % toyTextureNames.count]
            let toyTexture = TextureManager.shared.texture(for: textureName)
            let toy = SKSpriteNode(texture: toyTexture, size: CGSize(width: 32, height: 24))
            toy.position = toyPos
            toy.zPosition = 2
            toy.name = "dog_toy_\(index)"
            actors.addChild(toy)
        }

        dog.toyPositions = toyPositions
    }

    // MARK: - Feature Decorations Setup

    /// Sets up feature decorations and rebinds stored sprite references.
    private func setupFeatureDecorations(parent: SKNode) {
        let radio = RadioSprite()
        radio.position = layout.radioPosition
        radio.zPosition = 2
        parent.addChild(radio)
        radioSprite = radio

        let plant = GrowingPlantSprite()
        plant.position = layout.growingPlantPosition
        plant.zPosition = 2
        parent.addChild(plant)
        growingPlantSprite = plant

        if let whiteboard = matchingEnvironmentNodes(for: ["whiteboard"]).first {
            let overlay = WhiteboardStatsOverlay()
            overlay.zPosition = 3
            whiteboard.addChild(overlay)
            whiteboardOverlay = overlay
        }

        let shelf = AchievementShelfSprite()
        shelf.position = layout.achievementShelfPosition
        shelf.zPosition = 2
        parent.addChild(shelf)
        shelf.displayUnlocked(achievementTracker.unlockedAchievements)
        achievementShelf = shelf

        weekendVibesManager.update(scene: self, catSprite: catSprite)

        let birdCage = BirdCageSprite()
        birdCage.position = layout.birdCagePosition
        birdCage.zPosition = 2
        parent.addChild(birdCage)
        birdCageSprite = birdCage

        let stationTexture = TextureManager.shared.texture(for: TextureManager.decorationCoffeeStation)
        let station = SKSpriteNode(texture: stationTexture, size: CGSize(width: 90, height: 54))
        station.position = layout.coffeeStationPosition
        station.name = "decoration_coffee_station"
        station.zPosition = 2
        parent.addChild(station)

        let barista = BaristaSprite()
        barista.position = layout.baristaPosition
        barista.zPosition = 2
        parent.addChild(barista)
        baristaSprite = barista

        let rugTexture = TextureManager.shared.texture(for: TextureManager.decorationSmallRug)
        let rug = SKSpriteNode(texture: rugTexture, size: CGSize(width: 96, height: 48))
        rug.position = layout.coffeeRugPosition
        rug.name = "rug_coffee"
        rug.zPosition = -6
        parent.addChild(rug)
    }

    private func setupCollisionGeometry() {
        let edgeLoop = SKPhysicsBody(edgeLoopFrom: layout.walkableArea)
        edgeLoop.isDynamic = false
        edgeLoop.categoryBitMask = PhysicsMask.environment
        edgeLoop.collisionBitMask = PhysicsMask.agent
        edgeLoop.contactTestBitMask = PhysicsMask.agent
        physicsBody = edgeLoop

        let collisionLayer = SKNode()
        collisionLayer.name = "collision_layer"
        collisionLayer.zPosition = 0
        addChild(collisionLayer)

        for (index, rect) in layout.collisionObstacles.enumerated() {
            let node = SKNode()
            node.name = "collision_\(index)"
            node.position = CGPoint(x: rect.midX, y: rect.midY)

            let body = SKPhysicsBody(rectangleOf: rect.size)
            body.isDynamic = false
            body.categoryBitMask = PhysicsMask.environment
            body.collisionBitMask = PhysicsMask.agent
            body.contactTestBitMask = PhysicsMask.agent
            node.physicsBody = body

            collisionLayer.addChild(node)
        }
    }

    // MARK: - Agent Management

    /// Synchronizes the scene with the current list of agents.
    /// Call this from the main update loop whenever AgentMonitorService publishes changes.
    public func updateAgents(_ agents: [AgentInfo]) {
        // Resume if scene was auto-paused and agents appear
        if !agents.isEmpty && self.isPaused {
            self.isPaused = false
            emptySceneTimer = 0
        }

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
            } else if !fadingOutAgentIDs.contains(agent.id) {
                addAgentSprite(for: agent)
            }
        }

        // Clear transient desk items for agents that are no longer working at their claimed seat.
        for agent in agents {
            guard let sprite = agentSprites[agent.id] else { continue }
            if (agent.state == .idle || agent.state == .deepThinking), let deskID = sprite.assignedDeskID {
                deskClutterManager.clearClutter(forDeskID: deskID, scene: self)
                coffeeRunManager.removeCup(deskID: deskID, scene: self)
            }
        }

        // Assign desks to active agents that don't have one
        for agent in agents {
            guard agent.state != .idle && agent.state != .finished && agent.state != .deepThinking else { continue }
            if let sprite = agentSprites[agent.id] {
                // Agent is in the scene but has no desk
                if sprite.assignedDeskID == nil {
                    let occupiedDeskIDs = Set(deskAssignments.keys)
                    if let desk = layout.nextAvailableDesk(occupiedDeskIDs: occupiedDeskIDs) {
                        sprite.cancelDesklessPacing()
                        reserveDesk(desk, for: sprite, agentID: agent.id)
                        sprite.cancelIdleRoaming()
                        moveAgent(sprite, toClaim: desk, state: agent.state)
                    }
                }
            } else if !fadingOutAgentIDs.contains(agent.id) {
                // Agent is not in the scene — try adding (maybe desk is available now)
                addAgentSprite(for: agent)
            }
        }

        // Update monitor states based on desk assignments
        updateMonitorStates(agents: agents)

        // Detect finished transitions for growing plant (1C)
        for agent in agents {
            if let sprite = agentSprites[agent.id] {
                if agent.state == .finished && sprite.agentInfo.state != .finished {
                    growingPlantSprite?.recordCompletion()
                }
            }
        }

        // Update cached data for the update loop to avoid per-frame allocations
        cachedAgentInfos = agentSprites.values.map(\.agentInfo)
        cachedActiveAgentCount = cachedAgentInfos.filter { $0.state.isActive }.count
        cachedDeskPositions = layout.desks.map { (id: $0.id, position: $0.chairPosition) }
        cachedActiveDeskIDs = Set(deskAssignments.keys)
    }

    /// Creates and adds a new agent sprite to the scene.
    private func addAgentSprite(for agent: AgentInfo) {
        let sprite = AgentSprite(agentInfo: agent)
        sprite.navigationLayout = layout
        let occupiedDeskIDs = Set(deskAssignments.keys)
        let assignedDesk = layout.nextAvailableDesk(occupiedDeskIDs: occupiedDeskIDs)

        if assignedDesk == nil && !agent.state.isActive {
            return
        }

        let entrancePoint = layout.doorPosition
        sprite.position = entrancePoint
        sprite.zPosition = 5

        addChild(sprite)
        agentSprites[agent.id] = sprite
        sprite.playAnimation(for: agent.state)

        if let desk = assignedDesk {
            reserveDesk(desk, for: sprite, agentID: agent.id)
            moveAgent(sprite, toClaim: desk, state: agent.state)
        }
    }

    /// Removes an agent sprite from the scene by walking it to the door.
    private func removeAgentSprite(id: String) {
        guard let sprite = agentSprites.removeValue(forKey: id) else { return }

        // Free up the desk, remove its laptop, and clean up desk items
        if let deskID = sprite.assignedDeskID {
            deskAssignments.removeValue(forKey: deskID)
            hideDeskLaptop(deskID: deskID)
            deskClutterManager.clearClutter(forDeskID: deskID, scene: self)
            coffeeRunManager.removeCup(deskID: deskID, scene: self)
        }
        sprite.releaseDeskClaim()

        // Track this ID as fading out so updateAgents won't re-add it
        fadingOutAgentIDs.insert(id)

        // Stop any idle roaming and reset state
        sprite.idleBehaviorManager.reset()
        sprite.stopWalking()
        sprite.removeActionBubble()

        // Walk to the door, then fade out through it
        let exitPos = layout.doorExitPosition
        let doorPos = layout.doorPosition
        let path = layout.findPath(from: sprite.position, to: exitPos)
        sprite.walk(to: exitPos, via: path) { [weak self, weak sprite] in
            guard let sprite else { return }
            // Arrived at the door — walk into it and fade out
            sprite.run(SKAction.sequence([
                SKAction.move(to: doorPos, duration: 0.3),
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.run {
                    self?.fadingOutAgentIDs.remove(id)
                },
                SKAction.removeFromParent()
            ]))
        }
    }

    // MARK: - Monitor Management — task 4.4, 4.11, 6.3

    private func reserveDesk(_ desk: OfficeLayout.DeskPosition, for sprite: AgentSprite, agentID: String) {
        sprite.assignedDeskID = desk.id
        deskAssignments[desk.id] = agentID
        hideDeskLaptop(deskID: desk.id)
    }

    private func moveAgent(_ sprite: AgentSprite, toClaim desk: OfficeLayout.DeskPosition, state: AgentState) {
        let path = layout.findPath(from: sprite.position, to: desk.chairPosition)
        let hustle: CGFloat = state.isActive ? 1.5 : 1.0
        sprite.walk(to: desk.chairPosition, via: path, speedMultiplier: hustle) { [weak self, weak sprite] in
            guard let self, let sprite else { return }
            sprite.dockLaptopAtDesk()
            self.applyMonitorState(deskID: desk.id, state: state)
            sprite.playAnimation(for: state)
        }
    }

    private func applyMonitorState(deskID: Int, state: AgentState) {
        switch state {
        case .idle, .deepThinking:
            turnOffMonitor(deskID: deskID)
        default:
            turnOnMonitor(deskID: deskID, state: state)
        }
    }

    /// Shows the claimed laptop on a desk with the "on" texture.
    private func turnOnMonitor(deskID: Int, state: AgentState) {
        guard let deskNode = envNode(withName: "desk_\(deskID)") else { return }
        let onTexture = TextureManager.shared.texture(for: TextureManager.furnitureLaptopOn)
        if let monitor = deskNode.childNode(withName: "monitor_\(deskID)") as? SKSpriteNode {
            monitor.isHidden = false
            monitor.texture = onTexture
        }
        updateMonitorGlow(deskID: deskID, state: state)
    }

    /// Shows the claimed laptop on a desk with the "off" texture.
    private func turnOffMonitor(deskID: Int) {
        guard let deskNode = envNode(withName: "desk_\(deskID)") else { return }
        let offTexture = TextureManager.shared.texture(for: TextureManager.furnitureLaptopOff)
        if let monitor = deskNode.childNode(withName: "monitor_\(deskID)") as? SKSpriteNode {
            monitor.isHidden = false
            monitor.texture = offTexture
        }
        if let glow = deskNode.childNode(withName: "monitorGlow_\(deskID)") as? SKShapeNode {
            glow.removeAllActions()
            glow.alpha = 0
            glow.fillColor = .clear
        }
    }

    /// Hides the laptop entirely for an unclaimed desk.
    private func hideDeskLaptop(deskID: Int) {
        guard let deskNode = envNode(withName: "desk_\(deskID)") else { return }
        if let monitor = deskNode.childNode(withName: "monitor_\(deskID)") as? SKSpriteNode {
            monitor.isHidden = true
            monitor.texture = TextureManager.shared.texture(for: TextureManager.furnitureLaptopOff)
        }
        if let glow = deskNode.childNode(withName: "monitorGlow_\(deskID)") as? SKShapeNode {
            glow.removeAllActions()
            glow.alpha = 0
            glow.fillColor = .clear
        }
    }

    /// Updates monitor glow color/opacity based on agent state — task 4.11
    private func updateMonitorGlow(deskID: Int, state: AgentState) {
        guard let deskNode = envNode(withName: "desk_\(deskID)") else { return }
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
        case .supervisingAgents:
            glow.fillColor = SKColor(red: 0.251, green: 0.690, blue: 0.690, alpha: 1.0)
            glow.alpha = 0.12
        default:
            glow.fillColor = SKColor(red: 0.376, green: 0.565, blue: 0.816, alpha: 1.0)
            glow.alpha = 0.05
        }
    }

    /// Updates all desk laptops based on current agent assignments.
    private func updateMonitorStates(agents: [AgentInfo]) {
        for (deskID, agentID) in deskAssignments {
            if let sprite = agentSprites[agentID], !sprite.hasDockedLaptopAtDesk {
                hideDeskLaptop(deskID: deskID)
            } else if let agent = agents.first(where: { $0.id == agentID }) {
                applyMonitorState(deskID: deskID, state: agent.state)
            }
        }
    }

    // MARK: - Node Lookup Helpers

    /// Finds a named node in the environment root (where desks, decorations etc. live).
    private func envNode(withName name: String) -> SKNode? {
        environmentRoot?.childNode(withName: name)
    }

    /// Returns environment nodes whose names contain any of the provided tokens.
    private func matchingEnvironmentNodes(for tokens: [String]) -> [SKNode] {
        guard let environmentRoot else { return [] }

        var matches: [SKNode] = []
        environmentRoot.enumerateChildNodes(withName: "//*") { node, _ in
            guard let name = node.name else { return }
            if tokens.contains(where: { name.contains($0) }) {
                matches.append(node)
            }
        }
        return matches
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

    /// Returns the currently visible agent IDs in stable sorted order.
    public var visibleAgentIDs: [String] {
        agentSprites.keys.sorted()
    }

    /// Returns the current desk assignments (for cat update)
    public var currentDeskAssignments: [Int: String] {
        deskAssignments
    }

    /// Moves sprites into a stable post-replay pose for deterministic screenshot capture.
    public func settleForDeterministicCapture() {
        featureUpdatesEnabled = false

        for desk in layout.desks {
            hideDeskLaptop(deskID: desk.id)
        }
        deskAssignments.removeAll()

        let sortedSprites = agentSprites.values.sorted { $0.agentInfo.id < $1.agentInfo.id }
        for (sprite, desk) in zip(sortedSprites, layout.desks.sorted(by: { $0.id < $1.id })) {
            sprite.assignedDeskID = desk.id
            deskAssignments[desk.id] = sprite.agentInfo.id
        }

        for sprite in agentSprites.values {
            sprite.stopWalking()
            sprite.cancelIdleRoaming()
            sprite.cancelDeepThinkingPacing()
            sprite.cancelDesklessPacing()

            if let deskID = sprite.assignedDeskID,
               let desk = layout.desks.first(where: { $0.id == deskID }) {
                sprite.position = desk.chairPosition
                sprite.dockLaptopAtDesk()
                applyMonitorState(deskID: deskID, state: sprite.agentInfo.state)
            }

            sprite.playAnimation(for: sprite.agentInfo.state)
        }

        cachedAgentInfos = agentSprites.values.map(\.agentInfo)
        cachedActiveAgentCount = cachedAgentInfos.filter { $0.state.isActive }.count
        cachedDeskPositions = layout.desks.map { (id: $0.id, position: $0.chairPosition) }
        cachedActiveDeskIDs = Set(deskAssignments.keys)
    }

    public func makeManifest(
        scenarioID: String,
        seed: UInt64,
        tickCount: Int
    ) -> OfficeSceneManifest {
        let visibleAgentIDs = agentSprites.keys.sorted()
        let agents = agentSprites.values.map(\.agentInfo)
        var stateCounts = Dictionary(uniqueKeysWithValues: AgentState.allCases.map { ($0.rawValue, 0) })
        for agent in agents {
            stateCounts[agent.state.rawValue, default: 0] += 1
        }
        let occupiedDeskAssignments = deskAssignments
            .map { OfficeSceneManifest.DeskAssignment(deskID: $0.key, agentID: $0.value) }
            .sorted { $0.deskID < $1.deskID }
        let featureFlags = [
            "featureUpdatesEnabled": featureUpdatesEnabled,
            "hasCatSprite": childNode(withName: "//office_cat") != nil,
            "hasDogSprite": childNode(withName: "//office_dog") != nil,
            "hasActiveAgents": agents.contains(where: { $0.state.isActive }),
            "hasSubagents": agents.contains(where: \.isSubagent),
            "hasErrors": agents.contains(where: { $0.state == .error }),
            "hasFinishedAgents": agents.contains(where: { $0.state == .finished }),
        ]

        return OfficeSceneManifest(
            scenarioID: scenarioID,
            worldPreset: worldPreset.rawValue,
            seed: seed,
            tickCount: tickCount,
            visibleAgentIDs: visibleAgentIDs,
            stateCounts: stateCounts,
            occupiedDeskAssignments: occupiedDeskAssignments,
            featureFlags: featureFlags
        )
    }

    // MARK: - Parallax Effect

    /// Shifts the background container slightly for a depth illusion when the window moves.
    public func applyParallax(dx: CGFloat, dy: CGFloat) {
        guard let container = childNode(withName: "background_container") else { return }
        let factor: CGFloat = 0.03
        let maxOffset: CGFloat = 8.0
        let targetX = max(-maxOffset, min(maxOffset, dx * factor))
        let targetY = max(-maxOffset, min(maxOffset, dy * factor))
        container.removeAction(forKey: "parallax")
        let move = SKAction.move(to: CGPoint(x: targetX, y: targetY), duration: 0.08)
        move.timingMode = .easeOut
        container.run(move, withKey: "parallax")
    }

    /// Animates the background container back to its default position.
    public func resetParallax() {
        guard let container = childNode(withName: "background_container") else { return }
        container.removeAction(forKey: "parallax")
        let reset = SKAction.move(to: .zero, duration: 0.4)
        reset.timingMode = .easeOut
        container.run(reset, withKey: "parallax")
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

    // MARK: - Idle Roaming Behavior

    /// Updates idle roaming behavior for a single agent sprite.
    private func updateIdleBehavior(for sprite: AgentSprite, deltaTime: TimeInterval) {
        // Only drive idle behavior when agent is actually idle
        guard sprite.agentInfo.state == .idle else { return }
        // Don't update when walking — the walk completion callback advances the state machine
        guard !sprite.isWalking else { return }

        let context = buildIdleContext(for: sprite)
        if let action = sprite.idleBehaviorManager.update(deltaTime: deltaTime, context: context) {
            if case .leaveOffice = action {
                removeAgentSprite(id: sprite.agentInfo.id)
                return
            }
            sprite.handleIdleAction(action, layout: layout)

            // Trigger cat heart when agent pets the cat
            if case .showEffect(.petTheCat) = action {
                catSprite?.showHeartParticle()
            }

            // Trigger dog tail wag when agent pets the dog
            if case .showEffect(.petTheDog) = action {
                dogSprite?.showHeartParticle()
            }

            // Trigger fetch when agent throws ball for the dog
            if case .showEffect(.fetchWithDog) = action {
                dogSprite?.startFetch(throwerPosition: sprite.position)
            }
        }
    }

    /// Builds the context struct that the idle behavior manager needs.
    private func buildIdleContext(for sprite: AgentSprite) -> IdleContext {
        let deskChairPosition: CGPoint
        if let deskID = sprite.assignedDeskID,
           let desk = layout.desks.first(where: { $0.id == deskID }) {
            deskChairPosition = desk.chairPosition
        } else {
            deskChairPosition = sprite.position
        }

        // Gather positions of other idle agents at their desks
        var otherIdleDeskPositions: [CGPoint] = []
        for (_, otherSprite) in agentSprites where otherSprite !== sprite {
            if otherSprite.agentInfo.state == .idle,
               !otherSprite.isRoaming,
               let deskID = otherSprite.assignedDeskID,
               let desk = layout.desks.first(where: { $0.id == deskID }) {
                otherIdleDeskPositions.append(
                    CGPoint(x: desk.chairPosition.x + 40, y: desk.chairPosition.y)
                )
            }
        }

        // Gather positions of other roaming/pacing agents (for social distancing)
        var otherRoamingPositions: [CGPoint] = []
        // Gather destinations that other agents are walking toward or performing at
        var occupiedActivityPositions: [CGPoint] = []
        for (_, otherSprite) in agentSprites where otherSprite !== sprite {
            if otherSprite.isRoaming || otherSprite.isDeepThinkingPacing {
                otherRoamingPositions.append(otherSprite.position)
            }
            // Track reserved destinations — where agents are headed or performing
            if let dest = otherSprite.idleBehaviorManager.targetDestination {
                occupiedActivityPositions.append(dest)
            }
        }

        // Cat position (only if cat is idle, not walking)
        let catPos: CGPoint?
        if let cat = catSprite, cat.catState == .idle {
            catPos = cat.position
        } else {
            catPos = nil
        }

        // Dog position (only if dog is idle or wagging, not fetching/walking/sleeping)
        let dogPos: CGPoint?
        if let dog = dogSprite, (dog.dogState == .idle || dog.dogState == .wagging) {
            dogPos = dog.position
        } else {
            dogPos = nil
        }

        return IdleContext(
            deskChairPosition: deskChairPosition,
            waterCoolerStandPosition: layout.waterCoolerStandPosition,
            bookshelfStandPosition: layout.bookshelfStandPosition,
            bulletinBoardStandPosition: layout.bulletinBoardStandPosition,
            windowStandPosition: layout.windowStandPosition,
            whiteboardStandPosition: layout.whiteboardStandPosition,
            plantPositions: layout.plantStandPositions,
            catPosition: catPos,
            dogPosition: dogPos,
            otherIdleAgentDeskPositions: otherIdleDeskPositions,
            loungePosition: layout.loungePosition,
            radioStandPosition: layout.radioStandPosition,
            printerStandPosition: layout.printerStandPosition,
            otherRoamingAgentPositions: otherRoamingPositions,
            occupiedActivityPositions: occupiedActivityPositions
        )
    }

    // MARK: - Deep Thinking Pacing Behavior

    /// Updates deep thinking pacing behavior for a single agent sprite.
    private func updateDeepThinkingBehavior(for sprite: AgentSprite, deltaTime: TimeInterval) {
        guard sprite.agentInfo.state == .deepThinking else { return }
        guard !sprite.isWalking else { return }

        // Gather waypoints from recreation areas
        let waypoints = [
            layout.waterCoolerStandPosition,
            layout.bookshelfStandPosition,
            layout.bulletinBoardStandPosition,
            layout.windowStandPosition,
            layout.whiteboardStandPosition,
        ] + layout.plantStandPositions

        // Gather other roaming/pacing agent positions for social distancing
        var otherPositions: [CGPoint] = []
        for (_, otherSprite) in agentSprites where otherSprite !== sprite {
            if otherSprite.isRoaming || otherSprite.isDeepThinkingPacing {
                otherPositions.append(otherSprite.position)
            }
        }

        if !sprite.isDeepThinkingPacing {
            // Start pacing for the first time
            sprite.startDeepThinkingPacing(waypoints: waypoints, otherAgentPositions: otherPositions)
        } else {
            // Continue pacing — pump the state machine
            if let action = sprite.deepThinkingBehaviorManager.update(
                deltaTime: deltaTime,
                waypoints: waypoints,
                otherAgentPositions: otherPositions
            ) {
                sprite.handleDeepThinkingAction(action, layout: layout)
            }
        }
    }

    /// Updates pacing behavior for active agents that have not yet claimed a desk.
    private func updateDesklessPacing(for sprite: AgentSprite) {
        guard sprite.assignedDeskID == nil, sprite.agentInfo.state.isActive else { return }

        let occupiedPositions: [CGPoint] = agentSprites.values.compactMap { otherSprite -> CGPoint? in
            guard otherSprite !== sprite else { return nil }
            return otherSprite.position
        }

        sprite.updateDesklessPacing(in: layout, occupiedPositions: occupiedPositions)
    }

    // MARK: - Update Loop

    public override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)

        guard featureUpdatesEnabled else { return }

        // Calculate delta time
        let deltaTime = lastUpdateTime > 0 ? currentTime - lastUpdateTime : 0
        lastUpdateTime = currentTime

        // Auto-pause when no agents for 30+ seconds (saves CPU/GPU).
        // Cap deltaTime contribution to 1s to prevent single large-delta frames from triggering pause.
        if agentSprites.isEmpty {
            emptySceneTimer += min(deltaTime, 1.0)
            if emptySceneTimer > 30.0 {
                self.isPaused = true
                return
            }
        } else {
            emptySceneTimer = 0
        }

        // Use cached data from updateAgents(_:) instead of allocating per-frame
        let agents = cachedAgentInfos
        let activeAgentCount = cachedActiveAgentCount

        // Per-frame updates: idle ZZZ, idle roaming, deep thinking, depth sorting
        for sprite in agentSprites.values {
            sprite.updateIdleZZZ(currentTime: currentTime)
            updateIdleBehavior(for: sprite, deltaTime: deltaTime)
            updateDeepThinkingBehavior(for: sprite, deltaTime: deltaTime)
            updateDesklessPacing(for: sprite)

            // Y-based depth sorting: agents closer to bottom (lower Y) render in front
            let normalizedDepth = 1.0 - min(max(sprite.position.y, 0), 700) / 700.0
            let newZ = 5.0 + CGFloat(normalizedDepth) * 0.9
            if abs(sprite.zPosition - newZ) > 0.001 { sprite.zPosition = newZ }
        }

        // Per-frame: cat/dog updates (use cached desk positions)
        if let cat = catSprite {
            cat.update(deltaTime: deltaTime, agents: agents, deskPositions: cachedDeskPositions, activeDeskIDs: cachedActiveDeskIDs)
        }
        if let dog = dogSprite {
            dog.update(deltaTime: deltaTime, agents: agents, deskPositions: cachedDeskPositions, activeDeskIDs: cachedActiveDeskIDs)
        }

        // Per-frame: empty office manager, radio, bird
        emptyOfficeManager.update(deltaTime: deltaTime, agentCount: agentSprites.count, scene: self)
        radioSprite?.updateWaves(hasActiveAgents: activeAgentCount > 0)
        birdCageSprite?.update(hasActiveAgents: activeAgentCount > 0)

        // Throttled feature managers (every 2 seconds)
        if currentTime - lastManagerUpdateTime > 2.0 {
            lastManagerUpdateTime = currentTime

            // Rubber duck debugging (2A)
            rubberDuckManager.update(agents: agents, deskAssignments: deskAssignments, scene: self)

            // Desk clutter accumulation (2B)
            deskClutterManager.update(deltaTime: 2.0, agents: agents, deskAssignments: deskAssignments, scene: self)

            // Office stats tracker (2C)
            officeStatsTracker.update(deltaTime: 2.0, agents: agents)

            // Coffee runs (3A)
            let coffeeTriggered = coffeeRunManager.update(deltaTime: 2.0, agents: agents, deskAssignments: deskAssignments)
            for agentID in coffeeTriggered {
                if let sprite = agentSprites[agentID], let deskID = sprite.assignedDeskID {
                    let coffeeDest = layout.baristaCustomerPosition
                    let path = layout.findPath(from: sprite.position, to: coffeeDest)
                    sprite.walk(to: coffeeDest, via: path) { [weak self, weak sprite] in
                        guard let self, let sprite else { return }
                        self.baristaSprite?.serveCustomer()
                        sprite.run(SKAction.wait(forDuration: 5.0)) {
                            let desk = self.layout.desks.first { $0.id == deskID }
                            if let chairPos = desk?.chairPosition {
                                let returnPath = self.layout.findPath(from: sprite.position, to: chairPos)
                                sprite.walk(to: chairPos, via: returnPath) { [weak self] in
                                    guard let self else { return }
                                    self.coffeeRunManager.coffeeRunCompleted(agentID: agentID)
                                    self.coffeeRunManager.placeCup(deskID: deskID, scene: self)
                                }
                            }
                        }
                    }
                }
            }

            // Water cooler chats (3B)
            if let chatRequest = waterCoolerChatManager.update(
                deltaTime: 2.0,
                agents: agents,
                chatPositions: layout.waterCoolerChatPositions
            ) {
                if let spriteA = agentSprites[chatRequest.agentA],
                   let spriteB = agentSprites[chatRequest.agentB] {
                    let pathA = layout.findPath(from: spriteA.position, to: chatRequest.posA)
                    spriteA.walk(to: chatRequest.posA, via: pathA)
                    let pathB = layout.findPath(from: spriteB.position, to: chatRequest.posB)
                    spriteB.walk(to: chatRequest.posB, via: pathB)
                }
            }

            // Pair programming (3C)
            if let pairRequest = pairProgrammingManager.update(
                deltaTime: 2.0,
                agents: agents,
                deskAssignments: deskAssignments,
                layout: layout
            ) {
                if let visitor = agentSprites[pairRequest.visitorID] {
                    let path = layout.findPath(from: visitor.position, to: pairRequest.observePosition)
                    visitor.walk(to: pairRequest.observePosition, via: path)
                }
            }

            // Pizza delivery (4A)
            pizzaDeliveryManager.update(
                deltaTime: 2.0,
                activeAgentCount: activeAgentCount,
                scene: self,
                layout: layout,
                doorPosition: layout.doorPosition,
                dropPosition: layout.pizzaDropPosition
            )

            // Standup meeting (4B)
            let hour = currentHour()
            let minute = Calendar.current.component(.minute, from: dateProvider())
            if let standupAssignments = standupMeetingManager.update(
                deltaTime: 2.0,
                currentHour: hour,
                currentMinute: minute,
                agents: agents,
                huddlePositions: layout.standupHuddlePositions
            ) {
                for assignment in standupAssignments {
                    if let sprite = agentSprites[assignment.agentID] {
                        let path = layout.findPath(from: sprite.position, to: assignment.position)
                        sprite.walk(to: assignment.position, via: path)
                    }
                }
            }

            // Achievement tracking (5B)
            let newAchievements = achievementTracker.update(agents: agents)
            for achievement in newAchievements {
                achievementShelf?.unlockTrophy(for: achievement)
            }
        }

        // Periodically update window daylight, stats overlay, night mode (every 60 seconds)
        if currentTime - lastDaylightUpdate > 60.0 {
            lastDaylightUpdate = currentTime
            let hour = currentHour()
            applyWindowDaylight(hour: hour)
            updateRainState()
            nightOwlManager.update(hour: hour, scene: self, agentSprites: Array(agentSprites.values))
            weekendVibesManager.update(scene: self, catSprite: catSprite)
        }

        // Update stats overlay every 30 seconds
        if currentTime - lastStatsUpdate > 30.0 {
            lastStatsUpdate = currentTime
            whiteboardOverlay?.updateStats(
                totalAgentsToday: officeStatsTracker.totalAgentsToday,
                activeCount: officeStatsTracker.activeCount,
                activityHistory: officeStatsTracker.activityHistory
            )
        }
    }
}
