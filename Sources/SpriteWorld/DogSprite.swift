import SpriteKit
import Models

/// Pancake the apricot Maltipoo - the office dog that wanders around, eats from her bowl,
/// wags her tail when agents visit, and occasionally follows agents between desks.
public class DogSprite: SKSpriteNode {

    /// The possible states of the office dog.
    public enum DogState {
        case idle, walking, sleeping, eating, wagging
    }

    /// The dog's current behavioral state.
    public private(set) var dogState: DogState = .sleeping

    /// Timer tracking how long the dog has been in the current non-walking state.
    private var wanderTimer: TimeInterval = 0

    /// When the next wander should occur.
    private var nextWanderTime: TimeInterval = 0

    /// How long the dog has been idle at current spot.
    private var idleTimer: TimeInterval = 0

    /// How long to idle before wandering again.
    private var idleDuration: TimeInterval = 0

    /// Time since no agents have been active (for sleep transition).
    private var noAgentTimer: TimeInterval = 0

    /// Whether a heart/wag has been shown at the current visit.
    private var wagShown: Bool = false

    /// The desk ID the dog is currently visiting (if any).
    private var currentDeskID: Int?

    /// Walk speed in points per second.
    private let walkSpeed: CGFloat = 25.0

    /// Position of the dog bowl in the scene.
    public var bowlPosition: CGPoint = .zero

    /// Timer for eating behavior.
    private var eatTimer: TimeInterval = 0

    /// Timer for tail wag animation.
    private var wagTimer: TimeInterval = 0

    // MARK: - Initialization

    public init() {
        let texture = TextureManager.shared.texture(for: "dog_sleep")
        // 14x12 pixel art scaled 4x = 56x48
        super.init(texture: texture, color: .clear, size: CGSize(width: 56, height: 48))
        self.name = "office_dog"
        self.zPosition = 100
        setupNameLabel()
        startSleeping()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Name Label

    private func setupNameLabel() {
        let label = SKLabelNode(text: "Pancake")
        label.fontName = "Menlo-Bold"
        label.fontSize = 8
        label.fontColor = SKColor(red: 0.91, green: 0.75, blue: 0.56, alpha: 0.9)
        label.position = CGPoint(x: 0, y: size.height / 2 + 6)
        label.zPosition = 101
        label.name = "dog_name_label"
        addChild(label)
    }

    // MARK: - Update Loop

    /// Called each frame from OfficeScene's update loop.
    public func update(
        deltaTime: TimeInterval,
        agents: [AgentInfo],
        deskPositions: [(id: Int, position: CGPoint)],
        activeDeskIDs: Set<Int>
    ) {
        let hasActiveAgents = agents.contains { $0.state != .idle && $0.state != .finished }

        switch dogState {
        case .sleeping:
            if hasActiveAgents {
                wakeUp()
                scheduleNextWander()
            }

        case .idle:
            if !hasActiveAgents {
                noAgentTimer += deltaTime
                if noAgentTimer >= 90.0 {
                    startSleeping()
                    return
                }
            } else {
                noAgentTimer = 0
            }

            idleTimer += deltaTime
            wanderTimer += deltaTime

            if wanderTimer >= nextWanderTime {
                // 20% chance to go eat from bowl, 80% chance to visit a desk
                if Double.random(in: 0...1) < 0.2 && bowlPosition != .zero {
                    startWalking(to: bowlPosition, deskID: -1, isActiveDeskID: false, goingToBowl: true)
                } else {
                    let destination = pickDestination(deskPositions: deskPositions, activeDeskIDs: activeDeskIDs)
                    startWalking(to: destination.position, deskID: destination.id, isActiveDeskID: activeDeskIDs.contains(destination.id))
                }
            }

        case .walking:
            if !hasActiveAgents {
                noAgentTimer += deltaTime
            } else {
                noAgentTimer = 0
            }

        case .eating:
            eatTimer += deltaTime
            if eatTimer >= 8.0 {
                stopEating()
                scheduleNextWander()
            }

        case .wagging:
            wagTimer += deltaTime
            if wagTimer >= 3.0 {
                stopWagging()
                scheduleNextWander()
            }
        }
    }

    // MARK: - State Transitions

    /// Puts the dog to sleep.
    public func startSleeping() {
        dogState = .sleeping
        removeAction(forKey: "walk")
        removeAction(forKey: "walkAnimation")
        removeAction(forKey: "eatAnimation")
        removeAction(forKey: "wagAnimation")
        let sleepTexture = TextureManager.shared.texture(for: "dog_sleep")
        self.texture = sleepTexture
        noAgentTimer = 0
        wanderTimer = 0
        wagShown = false
        addZZZEmitter()
    }

    /// Wakes the dog up from sleeping.
    private func wakeUp() {
        dogState = .idle
        removeZZZEmitter()
        let idleTexture = TextureManager.shared.texture(for: TextureManager.dogIdle)
        self.texture = idleTexture
        noAgentTimer = 0
        wanderTimer = 0
        idleTimer = 0
    }

    /// Schedules the next wander time (20-80 seconds — maltipoos are more active than cats).
    private func scheduleNextWander() {
        wanderTimer = 0
        nextWanderTime = TimeInterval.random(in: 20...80)
    }

    /// Starts walking to a destination point.
    public func startWalking(to destination: CGPoint, deskID: Int, isActiveDeskID: Bool, goingToBowl: Bool = false) {
        dogState = .walking
        wagShown = false
        currentDeskID = deskID

        // Flip xScale based on direction
        if destination.x < position.x {
            xScale = -abs(xScale)
        } else {
            xScale = abs(xScale)
        }

        // Walk animation
        let tm = TextureManager.shared
        let frame0 = tm.texture(for: "dog_walk_frame0")
        let frame1 = tm.texture(for: "dog_walk_frame1")
        let walkAnim = SKAction.animate(with: [frame0, frame1], timePerFrame: 0.25)
        run(SKAction.repeatForever(walkAnim), withKey: "walkAnimation")

        // Movement
        let distance = hypot(destination.x - position.x, destination.y - position.y)
        let duration = TimeInterval(distance / walkSpeed)
        let moveAction = SKAction.move(to: destination, duration: duration)
        moveAction.timingMode = .easeInEaseOut

        let arrive = SKAction.run { [weak self] in
            if goingToBowl {
                self?.startEating()
            } else {
                self?.arriveAtDesk(isActive: isActiveDeskID)
            }
        }
        let sequence = SKAction.sequence([moveAction, arrive])
        run(sequence, withKey: "walk")
    }

    /// Called when the dog arrives at a desk.
    private func arriveAtDesk(isActive: Bool) {
        dogState = .idle
        removeAction(forKey: "walkAnimation")
        let idleTexture = TextureManager.shared.texture(for: TextureManager.dogIdle)
        self.texture = idleTexture
        idleTimer = 0
        idleDuration = TimeInterval.random(in: 8...25)

        // Wag tail and show heart if arriving at active desk
        if isActive && !wagShown {
            wagShown = true
            startWagging()
        } else {
            scheduleNextWander()
        }
    }

    /// Starts eating from the bowl.
    private func startEating() {
        dogState = .eating
        eatTimer = 0
        removeAction(forKey: "walkAnimation")

        let eatTexture = TextureManager.shared.texture(for: TextureManager.dogEat)
        self.texture = eatTexture

        // Bob head up and down while eating
        let bobDown = SKAction.moveBy(x: 0, y: -2, duration: 0.4)
        let bobUp = SKAction.moveBy(x: 0, y: 2, duration: 0.4)
        let bob = SKAction.sequence([bobDown, bobUp])
        run(SKAction.repeatForever(bob), withKey: "eatAnimation")
    }

    /// Stops eating.
    private func stopEating() {
        dogState = .idle
        removeAction(forKey: "eatAnimation")
        let idleTexture = TextureManager.shared.texture(for: TextureManager.dogIdle)
        self.texture = idleTexture
    }

    /// Starts wagging tail (happy reaction to agents).
    private func startWagging() {
        dogState = .wagging
        wagTimer = 0

        // Tail wag animation
        let tm = TextureManager.shared
        let frame0 = tm.texture(for: "dog_wag_frame0")
        let frame1 = tm.texture(for: "dog_wag_frame1")
        let wagAnim = SKAction.animate(with: [frame0, frame1], timePerFrame: 0.15)
        run(SKAction.repeatForever(wagAnim), withKey: "wagAnimation")

        showHeartParticle()
    }

    /// Stops wagging.
    private func stopWagging() {
        dogState = .idle
        removeAction(forKey: "wagAnimation")
        let idleTexture = TextureManager.shared.texture(for: TextureManager.dogIdle)
        self.texture = idleTexture
    }

    // MARK: - Destination Picking

    /// Picks a destination desk: 75% chance active agent desk, 25% random desk.
    /// Maltipoos are very people-oriented!
    private func pickDestination(
        deskPositions: [(id: Int, position: CGPoint)],
        activeDeskIDs: Set<Int>
    ) -> (id: Int, position: CGPoint) {
        guard !deskPositions.isEmpty else {
            return (id: 0, position: .zero)
        }

        let activeDesks = deskPositions.filter { activeDeskIDs.contains($0.id) }

        if !activeDesks.isEmpty && Double.random(in: 0...1) < 0.75 {
            let desk = activeDesks.randomElement()!
            return desk
        } else {
            let desk = deskPositions.randomElement()!
            return desk
        }
    }

    // MARK: - Particles

    /// Adds visible ZZZ text animation for sleeping state.
    private func addZZZEmitter() {
        removeZZZEmitter()

        let container = SKNode()
        container.name = "dog_zzz"
        container.zPosition = 101
        container.position = CGPoint(x: 0, y: size.height / 2 + 4)
        addChild(container)

        let spawnZ = SKAction.run { [weak self] in
            guard let self = self else { return }
            guard let zzz = self.childNode(withName: "dog_zzz") else { return }

            let z = SKLabelNode(text: "Z")
            z.fontName = "Menlo-Bold"
            z.fontSize = 10
            z.fontColor = SKColor(white: 1.0, alpha: 0.7)
            z.position = CGPoint(x: CGFloat.random(in: -2...2), y: 0)
            zzz.addChild(z)

            let drift = SKAction.moveBy(x: CGFloat.random(in: 4...10), y: 20, duration: 2.5)
            let grow = SKAction.scale(to: 1.4, duration: 2.5)
            let fade = SKAction.fadeOut(withDuration: 2.5)
            let group = SKAction.group([drift, grow, fade])
            z.run(SKAction.sequence([group, SKAction.removeFromParent()]))
        }

        let delay = SKAction.wait(forDuration: 1.8, withRange: 0.6)
        let sequence = SKAction.sequence([spawnZ, delay])
        container.run(SKAction.repeatForever(sequence), withKey: "zzz_spawner")
    }

    /// Removes the ZZZ emitter.
    private func removeZZZEmitter() {
        if let zzz = childNode(withName: "dog_zzz") {
            zzz.removeAllActions()
            zzz.removeAllChildren()
            zzz.removeFromParent()
        }
    }

    /// Shows a heart particle above the dog that fades after 2 seconds.
    public func showHeartParticle() {
        let heart = SKLabelNode(text: "\u{2764}")
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

    public var hasWalkAction: Bool {
        action(forKey: "walk") != nil
    }

    public var hasHeartParticle: Bool {
        childNode(withName: "heart_particle") != nil
    }

    public var hasZZZEmitter: Bool {
        childNode(withName: "dog_zzz") != nil
    }

    public var hasEatAnimation: Bool {
        action(forKey: "eatAnimation") != nil
    }

    public var hasWagAnimation: Bool {
        action(forKey: "wagAnimation") != nil
    }
}
