import SpriteKit
import Models

/// A SpriteKit node representing a single AI agent character in the office.
/// Manages the agent's visual appearance, animations, and movement.
public class AgentSprite: SKSpriteNode {

    /// The agent info this sprite represents
    public private(set) var agentInfo: AgentInfo

    /// The thought bubble floating above this agent
    public let thoughtBubble: ThoughtBubble

    /// The desk this agent is assigned to (if any)
    public var assignedDeskID: Int?

    /// Whether the agent is currently walking to a destination
    public private(set) var isWalking: Bool = false

    /// Name label below the sprite
    private let nameLabel: SKLabelNode

    /// Visual state indicator (colored dot or square)
    public let statusIndicator: SKShapeNode

    /// The current animation state (for transition logic)
    private var currentAnimationState: AgentState?

    /// Timestamp when the agent entered the idle state
    private var idleStartTime: TimeInterval?

    /// The ZZZ emitter node for sleeping idle agents
    private var zzzNode: SKNode?

    /// Timer tracking for ZZZ generation
    private var lastZTime: TimeInterval = 0

    /// Particle emitter attached for the current state (sparkle, spark, confetti)
    private var stateEmitter: SKEmitterNode?

    /// Manages idle roaming behavior when the agent is not working
    public let idleBehaviorManager = IdleBehaviorManager()

    // MARK: - Initialization

    public init(agentInfo: AgentInfo) {
        self.agentInfo = agentInfo
        self.thoughtBubble = ThoughtBubble()
        self.nameLabel = SKLabelNode()
        self.statusIndicator = SKShapeNode(circleOfRadius: 4)

        // Load trait-based texture — 16x24 pixel art scaled 3x = 48x72
        let texture = PixelArtGenerator.shared.character(
            traits: agentInfo.traits,
            state: agentInfo.state.rawValue
        )
        let spriteSize = CGSize(width: 48, height: 72)

        super.init(texture: texture, color: .clear, size: spriteSize)

        self.name = "agent_\(agentInfo.id)"
        self.colorBlendFactor = 0
        setupChildNodes()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func setupChildNodes() {
        // Name label below the sprite — pixel font style
        nameLabel.text = agentInfo.name
        nameLabel.fontName = "Menlo-Bold"
        nameLabel.fontSize = 11
        nameLabel.fontColor = .white
        nameLabel.position = CGPoint(x: 0, y: -size.height / 2 - 14)
        nameLabel.horizontalAlignmentMode = .center
        addChild(nameLabel)

        // Status indicator dot
        statusIndicator.fillColor = AgentSprite.colorForState(agentInfo.state)
        statusIndicator.strokeColor = .clear
        statusIndicator.position = CGPoint(x: size.width / 2 + 6, y: size.height / 2 - 6)
        statusIndicator.name = "statusIndicator"
        addChild(statusIndicator)

        // Thought bubble above the sprite — high z so it renders above all furniture
        thoughtBubble.position = CGPoint(x: 0, y: size.height / 2 + 30)
        thoughtBubble.zPosition = 200
        addChild(thoughtBubble)
    }

    // MARK: - State Updates

    /// Updates this sprite to reflect new agent info.
    public func update(with newInfo: AgentInfo) {
        let oldState = agentInfo.state
        let oldName = agentInfo.name
        agentInfo = newInfo

        let stateColor = AgentSprite.colorForState(newInfo.state)

        // Update name label if name changed (smart naming refinement)
        if newInfo.name != oldName {
            nameLabel.text = newInfo.name
        }

        // Update status indicator color and shape — task 4.8
        statusIndicator.fillColor = stateColor
        updateStatusIndicatorShape(for: newInfo.state)

        // Update thought bubble
        thoughtBubble.update(text: newInfo.currentTaskDescription, for: newInfo.state)

        // Trigger animation change if state changed
        if oldState != newInfo.state {
            transitionToState(newInfo.state, from: oldState)

            // Pulse animation on state change — task 4.8
            pulseStatusIndicator()
        }
    }

    /// Updates status indicator to square for error, circle for everything else — task 4.8
    private func updateStatusIndicatorShape(for state: AgentState) {
        if state == .error {
            statusIndicator.path = CGPath(
                rect: CGRect(x: -4, y: -4, width: 8, height: 8),
                transform: nil
            )
        } else {
            statusIndicator.path = CGPath(
                ellipseIn: CGRect(x: -4, y: -4, width: 8, height: 8),
                transform: nil
            )
        }
    }

    /// Pulse animation on state change — task 4.8
    private func pulseStatusIndicator() {
        let scaleUp = SKAction.scale(to: 1.3, duration: 0.15)
        scaleUp.timingMode = .easeOut
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.15)
        scaleDown.timingMode = .easeIn
        statusIndicator.run(SKAction.sequence([scaleUp, scaleDown]), withKey: "pulse")
    }

    // MARK: - State Transitions (6.14)

    /// Handles state transition with cross-fade blending (except error which is instant).
    private func transitionToState(_ newState: AgentState, from oldState: AgentState) {
        // Remove idle ZZZ if leaving idle and reset roaming behavior
        if oldState == .idle {
            removeZZZ()
            idleStartTime = nil
            cancelIdleRoaming()
        }

        // Remove previous state emitter
        removeStateEmitter()

        // Error transitions are instant (no fade)
        if newState == .error || oldState == .error {
            playAnimation(for: newState)
            currentAnimationState = newState
            return
        }

        // Cross-fade transition: fade out → swap → fade in (0.3s total)
        let fadeOut = SKAction.fadeAlpha(to: 0, duration: 0.15)
        let swap = SKAction.run { [weak self] in
            self?.playAnimation(for: newState)
            self?.currentAnimationState = newState
        }
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.15)
        run(SKAction.sequence([fadeOut, swap, fadeIn]), withKey: "stateTransition")
    }

    // MARK: - Animations (6.5–6.13)

    /// Plays the appropriate texture-frame animation for the given agent state.
    public func playAnimation(for state: AgentState) {
        removeAction(forKey: "stateAnimation")
        removeStateEmitter()
        currentAnimationState = state

        let frames = framesForState(state)

        switch state {
        case .idle:
            // 6.5: 4 frames, timePerFrame 2.0, loop forever
            let animate = SKAction.animate(with: frames, timePerFrame: 2.0)
            run(SKAction.repeatForever(animate), withKey: "stateAnimation")
            idleStartTime = CACurrentMediaTime()

        case .thinking:
            // 6.6: 4 frames, timePerFrame 2.0, loop forever + sparkle emitter
            let animate = SKAction.animate(with: frames, timePerFrame: 2.0)
            run(SKAction.repeatForever(animate), withKey: "stateAnimation")
            addSparkleEmitter()

        case .writingCode:
            // 6.7: 2 frames, timePerFrame 0.125 (8 FPS), loop forever
            let animate = SKAction.animate(with: frames, timePerFrame: 0.125)
            run(SKAction.repeatForever(animate), withKey: "stateAnimation")

        case .readingFiles:
            // 6.8: 3 frames, timePerFrame ~3.33, loop forever
            let animate = SKAction.animate(with: frames, timePerFrame: 3.33)
            run(SKAction.repeatForever(animate), withKey: "stateAnimation")

        case .runningCommand:
            // 6.9: 2 frames, timePerFrame 0.5 (1 FPS), loop forever
            let animate = SKAction.animate(with: frames, timePerFrame: 0.5)
            run(SKAction.repeatForever(animate), withKey: "stateAnimation")

        case .searching:
            // 6.10: 4 frames, timePerFrame 1.0 (1 FPS, 4s cycle), loop forever
            let animate = SKAction.animate(with: frames, timePerFrame: 1.0)
            run(SKAction.repeatForever(animate), withKey: "stateAnimation")

        case .waitingForInput:
            // 6.11: 4 frames, timePerFrame 0.5 (2 FPS, 2s cycle), loop forever
            let animate = SKAction.animate(with: frames, timePerFrame: 0.5)
            run(SKAction.repeatForever(animate), withKey: "stateAnimation")

        case .error:
            // 6.12: 2 frames, timePerFrame 0.5 (2 FPS), loop forever + red spark emitter. INSTANT.
            let animate = SKAction.animate(with: frames, timePerFrame: 0.5)
            run(SKAction.repeatForever(animate), withKey: "stateAnimation")
            addSparkEmitter()

        case .finished:
            // 6.13: 4 frames, plays ONCE, timePerFrame 1.0 (4s total) + confetti burst
            let animate = SKAction.animate(with: frames, timePerFrame: 1.0)
            run(animate, withKey: "stateAnimation")
            addConfettiEmitter()
        }
    }

    /// Returns animation frames for the current agent's traits and given state.
    private func framesForState(_ state: AgentState) -> [SKTexture] {
        return TextureManager.shared.animationFrames(traits: agentInfo.traits, state: state)
    }

    // MARK: - Particle Emitters (6.6, 6.12, 6.13)

    /// Removes the current state-specific particle emitter.
    private func removeStateEmitter() {
        stateEmitter?.removeFromParent()
        stateEmitter = nil
    }

    /// 6.6: Sparkle emitter for thinking state
    private func addSparkleEmitter() {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 5
        emitter.particleLifetime = 1.5
        emitter.particleColor = SKColor(red: 0.941, green: 0.753, blue: 0.251, alpha: 1.0) // Gold
        emitter.particleColorAlphaSpeed = -0.7
        emitter.particleSpeed = 20
        emitter.particleSpeedRange = 10
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi / 4
        emitter.particleScale = 0.3
        emitter.particleScaleSpeed = -0.15
        emitter.position = CGPoint(x: 0, y: size.height / 2 + 8)
        emitter.name = "sparkleEmitter"
        emitter.zPosition = 5
        emitter.targetNode = self
        addChild(emitter)
        stateEmitter = emitter
    }

    /// 6.12: Red spark emitter for error state
    private func addSparkEmitter() {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 8
        emitter.particleLifetime = 0.8
        emitter.particleColor = SKColor(red: 0.878, green: 0.314, blue: 0.314, alpha: 1.0) // Red
        emitter.particleColorAlphaSpeed = -1.0
        emitter.particleSpeed = 30
        emitter.particleSpeedRange = 15
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi
        emitter.particleScale = 0.25
        emitter.particleScaleSpeed = -0.2
        emitter.position = CGPoint(x: 0, y: size.height / 2 + 4)
        emitter.name = "sparkEmitter"
        emitter.zPosition = 5
        emitter.targetNode = self
        addChild(emitter)
        stateEmitter = emitter
    }

    /// 6.13: Confetti burst emitter for finished state (auto-removes after 2s)
    private func addConfettiEmitter() {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 40
        emitter.numParticlesToEmit = 40
        emitter.particleLifetime = 2.0
        emitter.particleLifetimeRange = 0.5
        emitter.particleColor = .green
        emitter.particleColorBlendFactor = 1.0
        emitter.particleColorSequence = nil
        emitter.particleColorRedRange = 1.0
        emitter.particleColorGreenRange = 1.0
        emitter.particleColorBlueRange = 1.0
        emitter.particleColorAlphaSpeed = -0.5
        emitter.particleSpeed = 60
        emitter.particleSpeedRange = 30
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi
        emitter.particleScale = 0.3
        emitter.particleScaleSpeed = -0.1
        emitter.yAcceleration = -40
        emitter.position = CGPoint(x: 0, y: size.height / 2 + 10)
        emitter.name = "confettiEmitter"
        emitter.zPosition = 5
        emitter.targetNode = self
        addChild(emitter)
        stateEmitter = emitter

        // Auto-remove after 2 seconds
        emitter.run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Idle ZZZ Particles (6.16)

    /// Called from the scene's update loop to check idle duration.
    public func updateIdleZZZ(currentTime: TimeInterval) {
        guard agentInfo.state == .idle, let startTime = idleStartTime else {
            return
        }

        let idleDuration = currentTime - startTime
        guard idleDuration > 60.0 else { return }

        // Spawn a new Z every 2 seconds
        if currentTime - lastZTime >= 2.0 {
            lastZTime = currentTime
            spawnZLetter()
        }
    }

    /// Spawns a single "Z" letter node that drifts upward and fades.
    private func spawnZLetter() {
        if zzzNode == nil {
            let container = SKNode()
            container.name = "zzzContainer"
            container.zPosition = 6
            addChild(container)
            zzzNode = container
        }

        let zLabel = SKLabelNode(text: "Z")
        zLabel.fontName = "Helvetica-Bold"
        zLabel.fontSize = 14
        zLabel.fontColor = SKColor(white: 1.0, alpha: 0.8)
        zLabel.position = CGPoint(x: CGFloat.random(in: -4...4), y: size.height / 2 + 16)
        zzzNode?.addChild(zLabel)

        let drift = SKAction.moveBy(x: CGFloat.random(in: -6...6), y: 30, duration: 2.0)
        let fade = SKAction.fadeOut(withDuration: 2.0)
        let group = SKAction.group([drift, fade])
        zLabel.run(SKAction.sequence([group, SKAction.removeFromParent()]))
    }

    /// Removes ZZZ particles immediately.
    private func removeZZZ() {
        zzzNode?.removeAllChildren()
        zzzNode?.removeFromParent()
        zzzNode = nil
    }

    // MARK: - Movement

    /// Walks the agent sprite to a destination point along a path.
    public func walk(to destination: CGPoint, via waypoints: [CGPoint], completion: (() -> Void)? = nil) {
        guard !isWalking else { return }
        isWalking = true

        var actions: [SKAction] = []
        let speed: CGFloat = 100 // points per second

        let allPoints = waypoints + [destination]
        var previous = position

        for point in allPoints {
            let distance = hypot(point.x - previous.x, point.y - previous.y)
            let duration = TimeInterval(distance / speed)
            let move = SKAction.move(to: point, duration: duration)
            move.timingMode = .easeInEaseOut
            actions.append(move)
            previous = point
        }

        let complete = SKAction.run { [weak self] in
            self?.isWalking = false
            completion?()
        }
        actions.append(complete)
        let sequence = SKAction.sequence(actions)
        run(sequence, withKey: "walk")
    }

    /// Stops any in-progress walk immediately.
    public func stopWalking() {
        removeAction(forKey: "walk")
        isWalking = false
    }

    // MARK: - Helpers

    /// Returns the texture name for a given agent type and state.
    public static func textureName(for agentType: AgentType, state: AgentState) -> String {
        let prefix = agentType == .claudeCode ? "char_claude" : "char_codex"
        return "\(prefix)_\(state.rawValue)"
    }

    /// Returns a color representing the agent's current state.
    /// Uses exact hex colors from VISION.md — task 4.7
    public static func colorForState(_ state: AgentState) -> SKColor {
        switch state {
        case .idle:
            SKColor(red: 0.627, green: 0.627, blue: 0.627, alpha: 1.0) // #A0A0A0
        case .thinking:
            SKColor(red: 0.941, green: 0.753, blue: 0.251, alpha: 1.0) // #F0C040
        case .writingCode:
            SKColor(red: 0.314, green: 0.784, blue: 0.471, alpha: 1.0) // #50C878
        case .readingFiles:
            SKColor(red: 0.376, green: 0.690, blue: 0.816, alpha: 1.0) // #60B0D0
        case .runningCommand:
            SKColor(red: 0.910, green: 0.565, blue: 0.251, alpha: 1.0) // #E89040
        case .searching:
            SKColor(red: 0.690, green: 0.502, blue: 0.816, alpha: 1.0) // #B080D0
        case .waitingForInput:
            SKColor(red: 0.376, green: 0.565, blue: 0.816, alpha: 1.0) // #6090D0
        case .error:
            SKColor(red: 0.878, green: 0.314, blue: 0.314, alpha: 1.0) // #E05050
        case .finished:
            SKColor(red: 0.439, green: 0.439, blue: 0.439, alpha: 1.0) // #707070
        }
    }

    /// Whether this sprite currently has a state-specific particle emitter.
    public var hasStateEmitter: Bool {
        stateEmitter != nil && stateEmitter?.parent != nil
    }

    /// Returns the name of the current state emitter, if any.
    public var stateEmitterName: String? {
        stateEmitter?.name
    }

    /// Whether this sprite is performing a cross-fade transition.
    public var isTransitioning: Bool {
        action(forKey: "stateTransition") != nil
    }

    // MARK: - Idle Roaming Behavior

    /// Whether the agent is currently roaming (not at desk) during idle state.
    public var isRoaming: Bool {
        idleBehaviorManager.phase != .atDesk
    }

    /// Cancels idle roaming and walks back to desk if needed.
    public func cancelIdleRoaming() {
        let wasRoaming = isRoaming
        idleBehaviorManager.reset()
        removeActionBubble()

        if wasRoaming, let deskID = assignedDeskID {
            stopWalking()

            // Walk back to desk chair
            let layout = OfficeLayout.defaultLayout()
            if let desk = layout.desks.first(where: { $0.id == deskID }) {
                let path = layout.findPath(from: position, to: desk.chairPosition)
                walk(to: desk.chairPosition, via: path)
            }
        }
    }

    /// Processes an idle action returned by the behavior manager.
    public func handleIdleAction(_ action: IdleAction, layout: OfficeLayout) {
        switch action {
        case .walkTo(let destination, _):
            let path = layout.findPath(from: position, to: destination)
            // Play idle animation while walking (reuse idle frames for casual walk)
            walk(to: destination, via: path) { [weak self] in
                self?.idleBehaviorManager.walkCompleted()
            }

        case .showEffect(let behavior):
            showActionBubble(for: behavior)
        }
    }

    /// Shows a small emoji/text bubble above the agent for the current idle activity.
    private func showActionBubble(for behavior: IdleBehavior) {
        removeActionBubble()

        let emoji: String
        switch behavior {
        case .waterCooler: emoji = "💧"
        case .browseBookshelf: emoji = "📖"
        case .checkBulletinBoard: emoji = "📌"
        case .lookOutWindow: emoji = "🌤"
        case .petTheCat: emoji = "❤️"
        case .whiteboard: emoji = "💡"
        case .visitColleague: emoji = "💬"
        case .stretchAtDesk: emoji = "🙆"
        case .waterPlant: emoji = "🌱"
        case .getCoffee: emoji = "☕️"
        }

        let bubble = SKLabelNode(text: emoji)
        bubble.fontSize = 18
        bubble.position = CGPoint(x: 0, y: size.height / 2 + 20)
        bubble.name = "action_bubble"
        bubble.zPosition = 190

        // Fade in
        bubble.alpha = 0
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        // Gentle bob
        let bobUp = SKAction.moveBy(x: 0, y: 4, duration: 1.0)
        bobUp.timingMode = .easeInEaseOut
        let bobDown = bobUp.reversed()
        let bob = SKAction.repeatForever(SKAction.sequence([bobUp, bobDown]))
        bubble.run(SKAction.group([fadeIn, bob]))

        addChild(bubble)
        idleBehaviorManager.actionBubble = bubble
    }

    /// Removes the action bubble if present.
    private func removeActionBubble() {
        childNode(withName: "action_bubble")?.removeFromParent()
    }
}
