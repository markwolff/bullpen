import SpriteKit
import Models

/// Pancake the apricot Maltipoo - the office dog that wanders around, eats from her bowl,
/// wags her tail when agents visit, plays with toys, gets the zoomies, and occasionally barks.
public class DogSprite: SKSpriteNode {

    /// The possible states of the office dog.
    public enum DogState {
        case idle, walking, sleeping, eating, wagging, playing, zoomies, barking, fetch
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

    /// Positions of toys in the scene (set by OfficeScene).
    public var toyPositions: [CGPoint] = []

    /// Timer for play behavior.
    private var playTimer: TimeInterval = 0

    /// Duration the dog will play before stopping.
    private var playDuration: TimeInterval = 0

    /// Timer for zoomies.
    private var zoomiesTimer: TimeInterval = 0

    /// Number of zoomie laps remaining.
    private var zoomiesLapsRemaining: Int = 0

    /// Timer for bark cooldown.
    private var barkCooldown: TimeInterval = 0

    /// Timer for bark state duration.
    private var barkTimer: TimeInterval = 0

    /// Position to return to after fetching the ball (where the throwing agent stands).
    private var fetchReturnPosition: CGPoint = .zero

    /// Energy level affects behavior probability (0.0 = sleepy, 1.0 = hyper).
    private var energyLevel: Double = 0.5

    /// Base energy set on wake-up, used for sinusoidal fluctuation.
    private var baseEnergy: Double = 0.5

    /// Accumulated time for energy oscillation.
    private var energyTimer: TimeInterval = 0

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

        // Decrease bark cooldown each frame
        if barkCooldown > 0 {
            barkCooldown -= deltaTime
        }

        // Update energy oscillation
        if dogState != .sleeping {
            energyTimer += deltaTime
            energyLevel = min(1.0, max(0.0, baseEnergy + 0.2 * sin(energyTimer * 0.1)))
        }

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
                pickBehavior(deskPositions: deskPositions, activeDeskIDs: activeDeskIDs)
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

        case .playing:
            playTimer += deltaTime
            if playTimer >= playDuration {
                stopPlaying()
                scheduleNextWander()
            }

        case .zoomies:
            zoomiesTimer += deltaTime

        case .barking:
            barkTimer += deltaTime
            if barkTimer >= 1.5 {
                stopBarking()
                scheduleNextWander()
            }

        case .fetch:
            // Walk completion callbacks drive the fetch state machine
            break
        }
    }

    // MARK: - Behavior Selection

    /// Picks a behavior based on the dog's current energy level.
    private func pickBehavior(
        deskPositions: [(id: Int, position: CGPoint)],
        activeDeskIDs: Set<Int>
    ) {
        let roll = Double.random(in: 0...1)

        if energyLevel > 0.7 {
            // High energy: 30% zoomies, 15% play, 15% bark, 20% bowl, 20% wander to desk
            if roll < 0.30 {
                startZoomies()
                return
            } else if roll < 0.45 && !toyPositions.isEmpty {
                let toy = toyPositions.randomElement()!
                startWalking(to: toy, deskID: -1, isActiveDeskID: false, goingToToy: true)
                return
            } else if roll < 0.60 && barkCooldown <= 0 {
                startBarking()
                return
            } else if roll < 0.80 && bowlPosition != .zero {
                startWalking(to: bowlPosition, deskID: -1, isActiveDeskID: false, goingToBowl: true)
                return
            }
            // Fallthrough: wander to a desk
            let destination = pickDestination(deskPositions: deskPositions, activeDeskIDs: activeDeskIDs)
            startWalking(to: destination.position, deskID: destination.id, isActiveDeskID: activeDeskIDs.contains(destination.id))

        } else if energyLevel >= 0.3 {
            // Medium energy: 5% zoomies, 25% play, 10% bark, 20% bowl, 40% wander to desk
            if roll < 0.05 {
                startZoomies()
                return
            } else if roll < 0.30 && !toyPositions.isEmpty {
                let toy = toyPositions.randomElement()!
                startWalking(to: toy, deskID: -1, isActiveDeskID: false, goingToToy: true)
                return
            } else if roll < 0.40 && barkCooldown <= 0 {
                startBarking()
                return
            } else if roll < 0.60 && bowlPosition != .zero {
                startWalking(to: bowlPosition, deskID: -1, isActiveDeskID: false, goingToBowl: true)
                return
            }
            // Fallthrough: wander to a desk
            let destination = pickDestination(deskPositions: deskPositions, activeDeskIDs: activeDeskIDs)
            startWalking(to: destination.position, deskID: destination.id, isActiveDeskID: activeDeskIDs.contains(destination.id))

        } else {
            // Low energy: 0% zoomies, 10% play, 5% bark, 20% bowl (more likely to eat/sleep), 65% wander
            if roll < 0.10 && !toyPositions.isEmpty {
                let toy = toyPositions.randomElement()!
                startWalking(to: toy, deskID: -1, isActiveDeskID: false, goingToToy: true)
                return
            } else if roll < 0.15 && barkCooldown <= 0 {
                startBarking()
                return
            } else if roll < 0.35 && bowlPosition != .zero {
                startWalking(to: bowlPosition, deskID: -1, isActiveDeskID: false, goingToBowl: true)
                return
            }
            // Fallthrough: wander to a desk
            let destination = pickDestination(deskPositions: deskPositions, activeDeskIDs: activeDeskIDs)
            startWalking(to: destination.position, deskID: destination.id, isActiveDeskID: activeDeskIDs.contains(destination.id))
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
        removeAction(forKey: "playAnimation")
        removeAction(forKey: "zoomiesAnimation")
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
        baseEnergy = Double.random(in: 0.4...0.9)
        energyLevel = baseEnergy
        energyTimer = 0
    }

    /// Schedules the next wander time, adjusted by energy level.
    private func scheduleNextWander() {
        wanderTimer = 0
        if energyLevel > 0.7 {
            nextWanderTime = TimeInterval.random(in: 10...40)
        } else if energyLevel < 0.3 {
            nextWanderTime = TimeInterval.random(in: 40...120)
        } else {
            nextWanderTime = TimeInterval.random(in: 20...80)
        }
    }

    /// Returns the energy-adjusted walk speed for normal (non-zoomie) walking.
    var normalWalkSpeed: CGFloat {
        if energyLevel > 0.7 {
            return walkSpeed * 1.3
        } else if energyLevel < 0.3 {
            return walkSpeed * 0.7
        } else {
            return walkSpeed
        }
    }

    /// Returns the speed used during zoomies, relative to the dog's normal walk speed.
    var zoomiesSpeed: CGFloat {
        normalWalkSpeed * 5
    }

    /// Starts walking to a destination point.
    public func startWalking(
        to destination: CGPoint,
        deskID: Int,
        isActiveDeskID: Bool,
        goingToBowl: Bool = false,
        goingToToy: Bool = false,
        isZooming: Bool = false,
        speed: CGFloat? = nil
    ) {
        dogState = isZooming ? .zoomies : .walking
        wagShown = false
        currentDeskID = deskID

        // Flip xScale based on direction
        if destination.x < position.x {
            xScale = -abs(xScale)
        } else {
            xScale = abs(xScale)
        }

        // Walk animation - faster frame rate for zoomies
        let tm = TextureManager.shared
        let frame0 = tm.texture(for: "dog_walk_frame0")
        let frame1 = tm.texture(for: "dog_walk_frame1")
        let frameRate: TimeInterval = isZooming ? 0.1 : 0.25
        let walkAnim = SKAction.animate(with: [frame0, frame1], timePerFrame: frameRate)
        let animKey = isZooming ? "zoomiesAnimation" : "walkAnimation"
        run(SKAction.repeatForever(walkAnim), withKey: animKey)

        // Movement - use provided speed, or current normal walking speed
        let effectiveSpeed = speed ?? normalWalkSpeed
        let distance = hypot(destination.x - position.x, destination.y - position.y)
        let duration = TimeInterval(distance / effectiveSpeed)
        let moveAction = SKAction.move(to: destination, duration: duration)
        moveAction.timingMode = isZooming ? .linear : .easeInEaseOut

        let arrive = SKAction.run { [weak self] in
            if isZooming {
                self?.zoomieNextLap()
            } else if goingToBowl {
                self?.startEating()
            } else if goingToToy {
                self?.beginPlayingAtCurrentPosition()
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

    // MARK: - Playing

    /// Starts walking to a toy position and then plays on arrival.
    public func startPlaying(at toyPosition: CGPoint) {
        startWalking(to: toyPosition, deskID: -1, isActiveDeskID: false, goingToToy: true)
    }

    /// Called when the dog arrives at a toy position; begins the play animation.
    private func beginPlayingAtCurrentPosition() {
        dogState = .playing
        playTimer = 0
        playDuration = TimeInterval.random(in: 6...12)
        removeAction(forKey: "walkAnimation")

        let idleTexture = TextureManager.shared.texture(for: TextureManager.dogIdle)
        self.texture = idleTexture

        // Play animation: rock side to side and small hops
        let flipRight = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.xScale = abs(self.xScale)
        }
        let flipLeft = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.xScale = -abs(self.xScale)
        }
        let waitFlip = SKAction.wait(forDuration: 0.4)
        let hopUp = SKAction.moveBy(x: 0, y: 4, duration: 0.15)
        let hopDown = SKAction.moveBy(x: 0, y: -4, duration: 0.15)
        let hop = SKAction.sequence([hopUp, hopDown])

        let rockRight = SKAction.group([flipRight, hop])
        let rockLeft = SKAction.group([flipLeft, hop])
        let playSequence = SKAction.sequence([rockRight, waitFlip, rockLeft, waitFlip])
        run(SKAction.repeatForever(playSequence), withKey: "playAnimation")
    }

    /// Stops playing with a toy.
    private func stopPlaying() {
        dogState = .idle
        removeAction(forKey: "playAnimation")
        let idleTexture = TextureManager.shared.texture(for: TextureManager.dogIdle)
        self.texture = idleTexture
        // Restore xScale to positive
        xScale = abs(xScale)
    }

    // MARK: - Zoomies

    /// Starts a zoomies burst -- the dog runs around at high speed for 3-5 laps.
    public func startZoomies() {
        dogState = .zoomies
        zoomiesTimer = 0
        zoomiesLapsRemaining = Int.random(in: 3...5)

        // Pick first random target and start running
        let target = randomZoomiePoint()
        startWalking(
            to: target,
            deskID: -1,
            isActiveDeskID: false,
            isZooming: true,
            speed: zoomiesSpeed
        )
    }

    /// Called when the dog arrives at a zoomie waypoint. Picks next point or stops.
    private func zoomieNextLap() {
        zoomiesLapsRemaining -= 1

        if zoomiesLapsRemaining > 0 {
            let target = randomZoomiePoint()
            startWalking(
                to: target,
                deskID: -1,
                isActiveDeskID: false,
                isZooming: true,
                speed: zoomiesSpeed
            )
        } else {
            // Zoomies finished
            dogState = .idle
            removeAction(forKey: "zoomiesAnimation")
            removeAction(forKey: "walk")
            let idleTexture = TextureManager.shared.texture(for: TextureManager.dogIdle)
            self.texture = idleTexture
            scheduleNextWander()
        }
    }

    /// Returns a random point within the scene bounds for zoomie laps.
    private func randomZoomiePoint() -> CGPoint {
        CGPoint(
            x: CGFloat.random(in: 80...500),
            y: CGFloat.random(in: 60...120)
        )
    }

    // MARK: - Barking

    /// Starts barking -- shows "Woof!" or "Arf!" text and pauses briefly.
    public func startBarking() {
        dogState = .barking
        barkTimer = 0
        barkCooldown = TimeInterval.random(in: 30...60)

        removeAction(forKey: "walkAnimation")
        let idleTexture = TextureManager.shared.texture(for: TextureManager.dogIdle)
        self.texture = idleTexture

        // 30% chance of "Arf!" instead of "Woof!"
        let barkText = Double.random(in: 0...1) < 0.3 ? "Arf!" : "Woof!"

        let label = SKLabelNode(text: barkText)
        label.fontName = "Menlo-Bold"
        label.fontSize = 10
        label.fontColor = SKColor(white: 1.0, alpha: 1.0)
        label.position = CGPoint(x: 0, y: size.height / 2 + 10)
        label.zPosition = 102
        label.name = "bark_label"
        addChild(label)

        // Float up and fade out over 1.5 seconds
        let drift = SKAction.moveBy(x: 0, y: 20, duration: 1.5)
        let fade = SKAction.fadeOut(withDuration: 1.5)
        let group = SKAction.group([drift, fade])
        label.run(SKAction.sequence([group, SKAction.removeFromParent()]))
    }

    /// Stops barking and returns to idle.
    private func stopBarking() {
        dogState = .idle
        // Remove bark label if still present
        if let label = childNode(withName: "bark_label") {
            label.removeAllActions()
            label.removeFromParent()
        }
    }

    // MARK: - Fetch

    /// Starts a fetch sequence: dog runs to a random "ball landing" spot, then runs back to the thrower.
    public func startFetch(throwerPosition: CGPoint) {
        guard dogState == .idle || dogState == .wagging else { return }

        dogState = .fetch
        fetchReturnPosition = throwerPosition
        removeAction(forKey: "wagAnimation")

        // Pick a random spot for the "ball" to land — offset from the thrower
        let ballLanding = CGPoint(
            x: throwerPosition.x + CGFloat.random(in: 80...180) * (Bool.random() ? 1 : -1),
            y: CGFloat.random(in: 65...115)
        )

        // Run to the ball at excited speed
        startWalking(to: ballLanding, deskID: -1, isActiveDeskID: false, isZooming: false, speed: walkSpeed * 2)

        // Override the arrival callback: when the walk action completes, run back
        removeAction(forKey: "walk")
        let distance = hypot(ballLanding.x - position.x, ballLanding.y - position.y)
        let duration = TimeInterval(distance / (walkSpeed * 2))
        let move = SKAction.move(to: ballLanding, duration: duration)
        move.timingMode = .easeOut

        let pauseAndReturn = SKAction.run { [weak self] in
            self?.fetchPickUpBall()
        }
        run(SKAction.sequence([move, pauseAndReturn]), withKey: "walk")
    }

    /// Dog pauses briefly at the ball, then runs back to the thrower.
    private func fetchPickUpBall() {
        removeAction(forKey: "walkAnimation")
        let idleTexture = TextureManager.shared.texture(for: TextureManager.dogIdle)
        self.texture = idleTexture

        // Brief sniff/grab pause
        let pause = SKAction.wait(forDuration: 0.6)
        let returnRun = SKAction.run { [weak self] in
            self?.fetchReturnToThrower()
        }
        run(SKAction.sequence([pause, returnRun]), withKey: "walk")
    }

    /// Dog runs back to the agent who threw the ball, then wags.
    private func fetchReturnToThrower() {
        // Flip toward thrower
        if fetchReturnPosition.x < position.x {
            xScale = -abs(xScale)
        } else {
            xScale = abs(xScale)
        }

        // Walk animation
        let tm = TextureManager.shared
        let frame0 = tm.texture(for: "dog_walk_frame0")
        let frame1 = tm.texture(for: "dog_walk_frame1")
        let walkAnim = SKAction.animate(with: [frame0, frame1], timePerFrame: 0.15)
        run(SKAction.repeatForever(walkAnim), withKey: "walkAnimation")

        let distance = hypot(fetchReturnPosition.x - position.x, fetchReturnPosition.y - position.y)
        let duration = TimeInterval(distance / (walkSpeed * 2))
        let move = SKAction.move(to: fetchReturnPosition, duration: duration)
        move.timingMode = .easeIn

        let arrive = SKAction.run { [weak self] in
            self?.fetchComplete()
        }
        run(SKAction.sequence([move, arrive]), withKey: "walk")
    }

    /// Fetch is done — wag tail and show heart.
    private func fetchComplete() {
        removeAction(forKey: "walkAnimation")
        wagShown = false
        startWagging()
        scheduleNextWander()
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

    public var hasPlayAnimation: Bool {
        action(forKey: "playAnimation") != nil
    }

    public var hasZoomiesAnimation: Bool {
        action(forKey: "zoomiesAnimation") != nil
    }

    public var currentEnergyLevel: Double {
        energyLevel
    }
}
