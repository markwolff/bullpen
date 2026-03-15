import SpriteKit
import Models

/// The office cat that wanders around the office, visiting agents at their desks.
/// The cat sleeps when no agents are active, wanders between desks when agents are
/// working, and shows affection (heart particle) when visiting an active agent.
public class CatSprite: SKSpriteNode {

    /// The possible states of the office cat.
    public enum CatState {
        case idle, walking, sleeping
    }

    /// The cat's current behavioral state.
    public private(set) var catState: CatState = .sleeping

    /// Timer tracking how long the cat has been in the current non-walking state.
    private var wanderTimer: TimeInterval = 0

    /// When the next wander should occur (seconds from now, relative to wanderTimer).
    private var nextWanderTime: TimeInterval = 0

    /// How long the cat has been idle at a desk.
    private var idleTimer: TimeInterval = 0

    /// How long to idle at a desk before wandering again.
    private var idleDuration: TimeInterval = 0

    /// Time since no agents have been active (for sleep transition).
    private var noAgentTimer: TimeInterval = 0

    /// Whether the cat has shown a heart at the current desk visit.
    private var heartShown: Bool = false

    /// The desk ID the cat is currently visiting (if any).
    private var currentDeskID: Int?

    /// Walk speed in points per second.
    private let walkSpeed: CGFloat = 20.0

    // MARK: - Initialization

    public init() {
        let texture = TextureManager.shared.texture(for: "cat_sleep")
        // 12x12 pixel art scaled 4x = 48x48
        super.init(texture: texture, color: .clear, size: CGSize(width: 48, height: 48))
        self.name = "office_cat"
        self.zPosition = 100
        startSleeping()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Update Loop

    /// Called each frame from OfficeScene's update loop.
    /// - Parameters:
    ///   - deltaTime: Time elapsed since last frame.
    ///   - agents: Current list of agents in the office.
    ///   - deskPositions: All desk positions in the layout, for destination picking.
    ///   - activeDeskIDs: Set of desk IDs that have active agents assigned.
    public func update(
        deltaTime: TimeInterval,
        agents: [AgentInfo],
        deskPositions: [(id: Int, position: CGPoint)],
        activeDeskIDs: Set<Int>
    ) {
        let hasActiveAgents = agents.contains { $0.state != .idle && $0.state != .finished }

        switch catState {
        case .sleeping:
            if hasActiveAgents {
                wakeUp()
                scheduleNextWander()
            }

        case .idle:
            if !hasActiveAgents {
                noAgentTimer += deltaTime
                if noAgentTimer >= 60.0 {
                    startSleeping()
                    return
                }
            } else {
                noAgentTimer = 0
            }

            idleTimer += deltaTime
            wanderTimer += deltaTime

            // Check if it's time to wander
            if wanderTimer >= nextWanderTime {
                let destination = pickDestination(deskPositions: deskPositions, activeDeskIDs: activeDeskIDs)
                startWalking(to: destination.position, deskID: destination.id, isActiveDeskID: activeDeskIDs.contains(destination.id))
            }

        case .walking:
            if !hasActiveAgents {
                noAgentTimer += deltaTime
            } else {
                noAgentTimer = 0
            }
        }
    }

    // MARK: - State Transitions

    /// Puts the cat to sleep.
    public func startSleeping() {
        catState = .sleeping
        removeAction(forKey: "walk")
        removeAction(forKey: "walkAnimation")
        let sleepTexture = TextureManager.shared.texture(for: "cat_sleep")
        self.texture = sleepTexture
        noAgentTimer = 0
        wanderTimer = 0
        heartShown = false
        addZZZEmitter()
    }

    /// Wakes the cat up from sleeping.
    private func wakeUp() {
        catState = .idle
        removeZZZEmitter()
        let idleTexture = TextureManager.shared.texture(for: TextureManager.catIdle)
        self.texture = idleTexture
        noAgentTimer = 0
        wanderTimer = 0
        idleTimer = 0
    }

    /// Schedules the next wander time (30-120 seconds from now).
    private func scheduleNextWander() {
        wanderTimer = 0
        nextWanderTime = TimeInterval.random(in: 30...120)
    }

    /// Starts walking to a destination point.
    public func startWalking(to destination: CGPoint, deskID: Int, isActiveDeskID: Bool) {
        catState = .walking
        heartShown = false
        currentDeskID = deskID

        // Flip xScale based on direction
        if destination.x < position.x {
            xScale = -abs(xScale)
        } else {
            xScale = abs(xScale)
        }

        // Walk animation (2-frame)
        let frame0 = TextureManager.shared.texture(for: TextureManager.catIdle)
        let frame1 = TextureManager.shared.texture(for: "cat_walk")
        let walkAnim = SKAction.animate(with: [frame0, frame1], timePerFrame: 0.3)
        run(SKAction.repeatForever(walkAnim), withKey: "walkAnimation")

        // Movement
        let distance = hypot(destination.x - position.x, destination.y - position.y)
        let duration = TimeInterval(distance / walkSpeed)
        let moveAction = SKAction.move(to: destination, duration: duration)
        moveAction.timingMode = .easeInEaseOut

        let arrive = SKAction.run { [weak self] in
            self?.arriveAtDesk(isActive: isActiveDeskID)
        }
        let sequence = SKAction.sequence([moveAction, arrive])
        run(sequence, withKey: "walk")
    }

    /// Called when the cat arrives at a desk.
    private func arriveAtDesk(isActive: Bool) {
        catState = .idle
        removeAction(forKey: "walkAnimation")
        let idleTexture = TextureManager.shared.texture(for: TextureManager.catIdle)
        self.texture = idleTexture
        idleTimer = 0
        idleDuration = TimeInterval.random(in: 10...30)

        // Show heart if arriving at active desk
        if isActive && !heartShown {
            heartShown = true
            showHeartParticle()
        }

        scheduleNextWander()
    }

    // MARK: - Destination Picking

    /// Picks a destination desk: 70% chance active agent desk, 30% random desk.
    private func pickDestination(
        deskPositions: [(id: Int, position: CGPoint)],
        activeDeskIDs: Set<Int>
    ) -> (id: Int, position: CGPoint) {
        guard !deskPositions.isEmpty else {
            return (id: 0, position: .zero)
        }

        let activeDesks = deskPositions.filter { activeDeskIDs.contains($0.id) }

        if !activeDesks.isEmpty && Double.random(in: 0...1) < 0.7 {
            // Pick a random active desk
            let desk = activeDesks.randomElement()!
            return desk
        } else {
            // Pick a random desk
            let desk = deskPositions.randomElement()!
            return desk
        }
    }

    // MARK: - Particles

    /// Adds ZZZ emitter for sleeping state.
    private func addZZZEmitter() {
        removeZZZEmitter()
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 0.5
        emitter.particleLifetime = 2.0
        emitter.particleColor = SKColor(white: 1.0, alpha: 0.6)
        emitter.particleColorAlphaSpeed = -0.3
        emitter.particleSpeed = 8
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi / 6
        emitter.particleScale = 0.3
        emitter.particleScaleSpeed = 0.1
        emitter.position = CGPoint(x: 0, y: size.height / 2 + 4)
        emitter.name = "cat_zzz"
        emitter.zPosition = 101
        addChild(emitter)
    }

    /// Removes the ZZZ emitter.
    private func removeZZZEmitter() {
        childNode(withName: "cat_zzz")?.removeFromParent()
    }

    /// Shows a heart particle above the cat that fades after 2 seconds.
    public func showHeartParticle() {
        let heart = SKLabelNode(text: "\u{2764}")  // Red heart unicode
        heart.fontSize = 16
        heart.fontColor = SKColor(red: 1.0, green: 0.3, blue: 0.4, alpha: 1.0)
        heart.position = CGPoint(x: 0, y: size.height / 2 + 10)
        heart.name = "heart_particle"
        heart.zPosition = 102
        addChild(heart)

        let drift = SKAction.moveBy(x: 0, y: 15, duration: 2.0)
        let fade = SKAction.fadeOut(withDuration: 2.0)
        let group = SKAction.group([drift, fade])
        heart.run(SKAction.sequence([group, SKAction.removeFromParent()]))
    }

    // MARK: - Public Accessors for Testing

    /// Whether the cat currently has a walk action running.
    public var hasWalkAction: Bool {
        action(forKey: "walk") != nil
    }

    /// Whether the cat has a heart particle child.
    public var hasHeartParticle: Bool {
        childNode(withName: "heart_particle") != nil
    }

    /// Whether the cat has a ZZZ emitter.
    public var hasZZZEmitter: Bool {
        childNode(withName: "cat_zzz") != nil
    }
}
