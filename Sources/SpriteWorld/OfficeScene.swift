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

    /// Agent IDs that are currently fading out (removed but still animating).
    /// Prevents duplicate sprite creation during the fade-out period.
    private var fadingOutAgentIDs: Set<String> = []

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
        setupRug()
        setupDesks()
        setupDecorations()
        setupTitleLabel()
        setupAmbientAnimations()
        setupCat()
    }

    // MARK: - 6.4: Tiled Background

    /// Tiles the background with repeating pixel-art tiles, scaled up for chunky look.
    private func setupTiledBackground() {
        // Pixel art tiles are 16x16, scaled 3x for a chunky Stardew Valley look
        let tileDisplaySize: CGFloat = 48

        // Background container for parallax effect — all visible tiles go here
        let bgContainer = SKNode()
        bgContainer.name = "background_container"
        bgContainer.zPosition = -12
        addChild(bgContainer)

        // Wall (top 1/3) — warm plaster tiles
        let wallTexture = TextureManager.shared.texture(for: TextureManager.tileWall)
        let wallHeight = layout.sceneSize.height / 3
        let wallBottom = layout.sceneSize.height - wallHeight

        var x: CGFloat = tileDisplaySize / 2
        while x < layout.sceneSize.width {
            var y = wallBottom + tileDisplaySize / 2
            while y < layout.sceneSize.height {
                let tile = SKSpriteNode(texture: wallTexture, size: CGSize(width: tileDisplaySize, height: tileDisplaySize))
                tile.position = CGPoint(x: x, y: y)
                tile.zPosition = -10
                bgContainer.addChild(tile)
                y += tileDisplaySize
            }
            x += tileDisplaySize
        }

        // Baseboard trim at the wall-floor boundary
        let trimColor = SKColor(red: 0.55, green: 0.42, blue: 0.30, alpha: 1.0)
        let trim = SKShapeNode(rect: CGRect(x: 0, y: wallBottom - 3, width: layout.sceneSize.width, height: 6))
        trim.fillColor = trimColor
        trim.strokeColor = .clear
        trim.zPosition = -8
        bgContainer.addChild(trim)

        // Add a single named wall node for test compatibility (direct scene child)
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

        // Floor (bottom 2/3) — wood plank tiles
        let floorTexture = TextureManager.shared.texture(for: TextureManager.tileFloor)
        let floorHeight = layout.sceneSize.height * 2 / 3

        x = tileDisplaySize / 2
        while x < layout.sceneSize.width {
            var y: CGFloat = tileDisplaySize / 2
            while y < floorHeight {
                let tile = SKSpriteNode(texture: floorTexture, size: CGSize(width: tileDisplaySize, height: tileDisplaySize))
                tile.position = CGPoint(x: x, y: y)
                tile.zPosition = -10
                bgContainer.addChild(tile)
                y += tileDisplaySize
            }
            x += tileDisplaySize
        }

        // Add a single named floor node for test compatibility (direct scene child)
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
    }

    // MARK: - Cozy Rug

    /// Adds a warm-colored area rug in the center of the office.
    private func setupRug() {
        let rugWidth: CGFloat = 700
        let rugHeight: CGFloat = 280
        let rugCenter = CGPoint(x: layout.sceneSize.width / 2, y: 270)

        // Rug border (darker)
        let rugBorder = SKShapeNode(rectOf: CGSize(width: rugWidth + 12, height: rugHeight + 12), cornerRadius: 8)
        rugBorder.fillColor = SKColor(red: 0.55, green: 0.25, blue: 0.18, alpha: 0.6)
        rugBorder.strokeColor = .clear
        rugBorder.position = rugCenter
        rugBorder.zPosition = -8
        addChild(rugBorder)

        // Rug body (warm red/terracotta)
        let rug = SKShapeNode(rectOf: CGSize(width: rugWidth, height: rugHeight), cornerRadius: 4)
        rug.fillColor = SKColor(red: 0.65, green: 0.32, blue: 0.22, alpha: 0.45)
        rug.strokeColor = .clear
        rug.position = rugCenter
        rug.zPosition = -7
        addChild(rug)

        // Rug pattern — simple diamond shapes
        let patternColor = SKColor(red: 0.72, green: 0.40, blue: 0.28, alpha: 0.35)
        for dx in stride(from: -280.0, through: 280.0, by: 140.0) {
            for dy in stride(from: -80.0, through: 80.0, by: 80.0) {
                let diamond = SKShapeNode(rectOf: CGSize(width: 20, height: 20))
                diamond.fillColor = patternColor
                diamond.strokeColor = .clear
                diamond.zRotation = .pi / 4
                diamond.position = CGPoint(x: rugCenter.x + CGFloat(dx), y: rugCenter.y + CGFloat(dy))
                diamond.zPosition = -6
                addChild(diamond)
            }
        }
    }

    // MARK: - 6.3: Furniture Textures

    /// Sets up desks with pixel art textures scaled up for Stardew Valley feel.
    private func setupDesks() {
        let tm = TextureManager.shared

        for desk in layout.desks {
            // Desk — 24x16 pixel art scaled 4x = 96x64 display
            let deskTexture = tm.texture(for: TextureManager.furnitureDesk)
            let deskNode = SKSpriteNode(texture: deskTexture, size: CGSize(width: 96, height: 64))
            deskNode.position = desk.position
            deskNode.name = "desk_\(desk.id)"
            deskNode.zPosition = 1
            addChild(deskNode)

            // Chair — 12x16 pixel art scaled 3x = 36x48 display
            let chairTexture = tm.texture(for: TextureManager.furnitureChair)
            let chairNode = SKSpriteNode(texture: chairTexture, size: CGSize(width: 36, height: 48))
            chairNode.position = CGPoint(x: 0, y: -60)
            chairNode.name = "chair_\(desk.id)"
            deskNode.addChild(chairNode)

            // Monitor — 12x10 pixel art scaled 3x = 36x30 display
            let monitorTexture = tm.texture(for: TextureManager.furnitureMonitorOff)
            let monitorNode = SKSpriteNode(texture: monitorTexture, size: CGSize(width: 36, height: 30))
            monitorNode.position = CGPoint(x: 0, y: 20)
            monitorNode.name = "monitor_\(desk.id)"
            monitorNode.zPosition = 2
            deskNode.addChild(monitorNode)

            // Monitor glow node (initially invisible)
            let glowNode = SKShapeNode(rectOf: CGSize(width: 44, height: 36), cornerRadius: 4)
            glowNode.fillColor = .clear
            glowNode.strokeColor = .clear
            glowNode.position = CGPoint(x: 0, y: 20)
            glowNode.name = "monitorGlow_\(desk.id)"
            glowNode.zPosition = 3
            glowNode.alpha = 0
            deskNode.addChild(glowNode)

            // Coffee mug — 8x8 pixel art scaled 3x = 24x24 display
            let mugTexture = tm.texture(for: TextureManager.furnitureCoffeeMug)
            let mugNode = SKSpriteNode(texture: mugTexture, size: CGSize(width: 24, height: 24))
            mugNode.position = CGPoint(x: 34, y: 10)
            mugNode.name = "coffeeMug_\(desk.id)"
            mugNode.zPosition = 2
            deskNode.addChild(mugNode)

            // Steam emitter
            let steam = createSteamEmitter()
            steam.position = CGPoint(x: 34, y: 24)
            steam.name = "steamEmitter_\(desk.id)"
            steam.zPosition = 4
            deskNode.addChild(steam)

            // Lamp on alternating desks — 8x16 pixel art scaled 3x = 24x48
            if desk.id % 2 == 0 {
                let lampTexture = tm.texture(for: TextureManager.furnitureLamp)
                let lampNode = SKSpriteNode(texture: lampTexture, size: CGSize(width: 24, height: 48))
                lampNode.position = CGPoint(x: -34, y: 16)
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

    /// Adds static decoration nodes to the office — scaled up pixel art.
    private func setupDecorations() {
        let tm = TextureManager.shared

        // Plants at corners — 12x20 pixel art scaled 4x = 48x80
        let plantTexture = tm.texture(for: TextureManager.decorationPlant)

        let plant1 = SKSpriteNode(texture: plantTexture, size: CGSize(width: 48, height: 80))
        plant1.position = CGPoint(x: 50, y: layout.sceneSize.height - 100)
        plant1.name = "decoration_plant_0"
        plant1.zPosition = 2
        addChild(plant1)

        let plant2 = SKSpriteNode(texture: plantTexture, size: CGSize(width: 48, height: 80))
        plant2.position = CGPoint(x: layout.sceneSize.width - 50, y: layout.sceneSize.height - 100)
        plant2.name = "decoration_plant_1"
        plant2.zPosition = 2
        addChild(plant2)

        // Additional plants on the floor for coziness
        let plant3 = SKSpriteNode(texture: plantTexture, size: CGSize(width: 40, height: 68))
        plant3.position = CGPoint(x: 40, y: 80)
        plant3.name = "decoration_plant_2"
        plant3.zPosition = 2
        addChild(plant3)

        let plant4 = SKSpriteNode(texture: plantTexture, size: CGSize(width: 40, height: 68))
        plant4.position = CGPoint(x: layout.sceneSize.width - 40, y: 80)
        plant4.name = "decoration_plant_3"
        plant4.zPosition = 2
        addChild(plant4)

        // Window on back wall — 20x16 pixel art scaled 5x = 100x80
        let windowTexture = tm.texture(for: TextureManager.decorationWindow)
        let windowNode = SKSpriteNode(texture: windowTexture, size: CGSize(width: 100, height: 80))
        windowNode.position = CGPoint(x: layout.sceneSize.width / 2, y: layout.sceneSize.height - 80)
        windowNode.name = "decoration_window"
        windowNode.zPosition = 2
        addChild(windowNode)

        // Second window
        let windowNode2 = SKSpriteNode(texture: windowTexture, size: CGSize(width: 100, height: 80))
        windowNode2.position = CGPoint(x: layout.sceneSize.width * 0.8, y: layout.sceneSize.height - 80)
        windowNode2.name = "decoration_window_2"
        windowNode2.zPosition = 2
        addChild(windowNode2)

        // Whiteboard — 24x16 pixel art scaled 5x = 120x80
        let whiteboardTexture = tm.texture(for: TextureManager.decorationWhiteboard)
        let whiteboardNode = SKSpriteNode(texture: whiteboardTexture, size: CGSize(width: 120, height: 80))
        whiteboardNode.position = CGPoint(x: layout.sceneSize.width * 0.2, y: layout.sceneSize.height - 80)
        whiteboardNode.name = "decoration_whiteboard"
        whiteboardNode.zPosition = 2
        addChild(whiteboardNode)

        // Clock — 10x10 pixel art scaled 4x = 40x40
        let clockTexture = tm.texture(for: TextureManager.decorationClock)
        let clockNode = SKSpriteNode(texture: clockTexture, size: CGSize(width: 40, height: 40))
        clockNode.position = CGPoint(x: layout.sceneSize.width - 100, y: layout.sceneSize.height - 30)
        clockNode.name = "decoration_clock"
        clockNode.zPosition = 2
        addChild(clockNode)

        // Poster — 14x18 pixel art scaled 4x = 56x72, between whiteboard and bookshelf
        let posterTexture = tm.texture(for: TextureManager.decorationPoster)
        let posterNode = SKSpriteNode(texture: posterTexture, size: CGSize(width: 56, height: 72))
        posterNode.position = CGPoint(x: 327, y: layout.sceneSize.height - 80)
        posterNode.name = "decoration_poster"
        posterNode.zPosition = 2
        addChild(posterNode)

        // Bookshelf — 20x16 pixel art scaled 4x = 80x64, on the wall between desks
        let bookshelfTexture = tm.texture(for: TextureManager.decorationBookshelf)
        let bookshelfNode = SKSpriteNode(texture: bookshelfTexture, size: CGSize(width: 80, height: 64))
        bookshelfNode.position = CGPoint(x: layout.sceneSize.width * 0.42, y: layout.sceneSize.height - 80)
        bookshelfNode.name = "decoration_bookshelf"
        bookshelfNode.zPosition = 2
        addChild(bookshelfNode)

        // Bulletin board — 20x14 pixel art scaled 4x = 80x56, on the wall
        let bulletinTexture = tm.texture(for: TextureManager.decorationBulletinBoard)
        let bulletinNode = SKSpriteNode(texture: bulletinTexture, size: CGSize(width: 80, height: 56))
        bulletinNode.position = CGPoint(x: layout.sceneSize.width * 0.62, y: layout.sceneSize.height - 75)
        bulletinNode.name = "decoration_bulletin_board"
        bulletinNode.zPosition = 2
        addChild(bulletinNode)

        // Water cooler — 10x20 pixel art scaled 4x = 40x80, on the floor near wall
        let coolerTexture = tm.texture(for: TextureManager.decorationWaterCooler)
        let coolerNode = SKSpriteNode(texture: coolerTexture, size: CGSize(width: 40, height: 80))
        coolerNode.position = CGPoint(x: layout.sceneSize.width - 60, y: layout.sceneSize.height * 2 / 3 - 10)
        coolerNode.name = "decoration_water_cooler"
        coolerNode.zPosition = 2
        addChild(coolerNode)

        // Office door on right wall — 14x24 pixel art scaled 4x = 56x96
        let doorTexture = tm.texture(for: TextureManager.decorationDoor)
        let doorNode = SKSpriteNode(texture: doorTexture, size: CGSize(width: 56, height: 96))
        doorNode.position = layout.doorPosition
        doorNode.name = "decoration_door"
        doorNode.zPosition = 2
        addChild(doorNode)
    }

    /// Sets up the title label with a cozy pixel-font feel.
    private func setupTitleLabel() {
        let titleLabel = SKLabelNode(text: "The Bullpen")
        titleLabel.fontName = "Menlo-Bold"
        titleLabel.fontSize = 14
        titleLabel.fontColor = SKColor(red: 0.45, green: 0.35, blue: 0.25, alpha: 1.0)
        titleLabel.position = CGPoint(x: layout.sceneSize.width / 2, y: layout.sceneSize.height - 20)
        titleLabel.zPosition = 10
        addChild(titleLabel)
    }

    // MARK: - 8.1-8.5: Ambient Animations

    /// Sets up all ambient animations: clock second hand, plant sway, window daylight, dust motes, rain.
    private func setupAmbientAnimations() {
        setupClockSecondHand()
        setupPlantSway()
        applyWindowDaylight(hour: currentHour())
        setupDustMotes()
        updateRainState()
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

    /// Floating dust motes that drift through sunbeams near the windows.
    private func setupDustMotes() {
        let hour = currentHour()
        // Only show dust motes during daytime (6am-6pm) when sunlight streams in
        guard hour >= 6 && hour < 18 else { return }

        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 0.8
        emitter.particleLifetime = 8.0
        emitter.particleLifetimeRange = 4.0
        emitter.particleColor = SKColor(white: 1.0, alpha: 0.25)
        emitter.particleColorAlphaSpeed = -0.03
        emitter.particleSpeed = 3
        emitter.particleSpeedRange = 2
        emitter.emissionAngle = -.pi / 6 // drift slightly downward-right
        emitter.emissionAngleRange = .pi / 4
        emitter.particleScale = 0.15
        emitter.particleScaleRange = 0.1
        emitter.particleScaleSpeed = 0.01
        emitter.particleAlpha = 0.25
        emitter.particleAlphaRange = 0.15
        emitter.xAcceleration = 0.5
        emitter.yAcceleration = -0.3
        // Spread across the upper portion of the scene near windows
        emitter.particlePositionRange = CGVector(dx: layout.sceneSize.width * 0.6, dy: layout.sceneSize.height * 0.3)
        emitter.position = CGPoint(x: layout.sceneSize.width / 2, y: layout.sceneSize.height * 0.75)
        emitter.name = "dust_motes"
        emitter.zPosition = 50
        addChild(emitter)
    }

    // MARK: - Rain on Windows at Night

    /// Adds rain particle emitters to window nodes during nighttime hours.
    private func setupRainOnWindows() {
        let hour = currentHour()
        guard hour >= 21 || hour < 6 else { return }

        for windowName in ["decoration_window", "decoration_window_2"] {
            guard let windowNode = childNode(withName: windowName) else { continue }
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
        for windowName in ["decoration_window", "decoration_window_2"] {
            guard let windowNode = childNode(withName: windowName) else { continue }
            guard let rain = windowNode.childNode(withName: "rain_emitter") else { continue }
            rain.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 1.0),
                SKAction.removeFromParent()
            ]))
        }
    }

    /// Updates rain state based on current hour. Called from ambient update cycle.
    private func updateRainState() {
        let hour = currentHour()
        if hour >= 21 || hour < 6 {
            setupRainOnWindows()
        } else {
            removeRainFromWindows()
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

    /// 8.4: Applies daylight color to all window decoration nodes.
    /// Accepts an hour parameter for testability.
    public func applyWindowDaylight(hour: Int) {
        let color = Self.daylightColor(for: hour)
        for windowName in ["decoration_window", "decoration_window_2"] {
            guard let windowNode = childNode(withName: windowName) as? SKSpriteNode else { continue }
            windowNode.removeAction(forKey: "daylight")
            windowNode.color = color
            let colorize = SKAction.colorize(with: color, colorBlendFactor: 0.4, duration: 2.0)
            windowNode.run(colorize, withKey: "daylight")
        }
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
            } else if !fadingOutAgentIDs.contains(agent.id) {
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
            sprite.zPosition = 5

            addChild(sprite)
            agentSprites[agent.id] = sprite

            // Walk to assigned desk
            let path = layout.findPath(from: entrancePoint, to: desk.chairPosition)
            sprite.walk(to: desk.chairPosition, via: path) { [weak sprite] in
                guard let sprite else { return }
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
            sprite.zPosition = 5
            addChild(sprite)
            agentSprites[agent.id] = sprite
        }
    }

    /// Removes an agent sprite from the scene by walking it to the door.
    private func removeAgentSprite(id: String) {
        guard let sprite = agentSprites.removeValue(forKey: id) else { return }

        // Free up the desk and turn off monitor
        if let deskID = sprite.assignedDeskID {
            deskAssignments.removeValue(forKey: deskID)
            turnOffMonitor(deskID: deskID)
        }

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
            sprite.handleIdleAction(action, layout: layout)

            // Trigger cat heart when agent pets the cat
            if case .showEffect(.petTheCat) = action {
                catSprite?.showHeartParticle()
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

        // Gather positions of other idle agents at their desks (for visitColleague)
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

        // Cat position (only if cat is idle, not walking)
        let catPos: CGPoint?
        if let cat = catSprite, cat.catState == .idle {
            catPos = cat.position
        } else {
            catPos = nil
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
            otherIdleAgentDeskPositions: otherIdleDeskPositions
        )
    }

    // MARK: - Update Loop

    public override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)

        // Calculate delta time
        let deltaTime = lastUpdateTime > 0 ? currentTime - lastUpdateTime : 0
        lastUpdateTime = currentTime

        // Update idle ZZZ and idle roaming behaviors for all agent sprites
        for sprite in agentSprites.values {
            sprite.updateIdleZZZ(currentTime: currentTime)
            updateIdleBehavior(for: sprite, deltaTime: deltaTime)
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
            updateRainState()
        }
    }
}
