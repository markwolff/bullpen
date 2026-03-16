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

    /// Role title subtitle below the name label (e.g., "Explorer", "Planner", "Developer")
    private let roleLabel: SKLabelNode

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
    public lazy var idleBehaviorManager = IdleBehaviorManager(isSubagent: agentInfo.isSubagent)

    /// Whether this agent is a subagent (renders smaller)
    private var isSubagent: Bool { agentInfo.isSubagent }

    // MARK: - Initialization

    public init(agentInfo: AgentInfo) {
        self.agentInfo = agentInfo
        self.thoughtBubble = ThoughtBubble()
        self.nameLabel = SKLabelNode()
        self.roleLabel = SKLabelNode()

        let indicatorRadius: CGFloat = agentInfo.isSubagent ? 3 : 4
        self.statusIndicator = SKShapeNode(circleOfRadius: indicatorRadius)

        // Load trait-based texture — 16x24 pixel art
        // Normal agents: scaled 3x = 48x72, Subagents: scaled 2x = 32x48
        let texture = PixelArtGenerator.shared.character(
            traits: agentInfo.traits,
            state: agentInfo.state.rawValue
        )
        let scaleFactor: CGFloat = agentInfo.isSubagent ? 2.5 : 3.0
        let spriteSize = CGSize(width: 16 * scaleFactor, height: 24 * scaleFactor)

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
        // Subagents use smaller font to match their smaller size
        nameLabel.text = agentInfo.name
        nameLabel.fontName = "Menlo-Bold"
        nameLabel.fontSize = isSubagent ? 9 : 11
        nameLabel.fontColor = .white
        nameLabel.position = CGPoint(x: 0, y: -size.height / 2 - (isSubagent ? 10 : 14))
        nameLabel.horizontalAlignmentMode = .center
        addChild(nameLabel)

        // Role title subtitle below name label (e.g., "Explorer", "Developer", "Planner")
        roleLabel.text = agentInfo.roleTitle ?? ""
        roleLabel.fontName = "Menlo"
        roleLabel.fontSize = isSubagent ? 7 : 9
        roleLabel.fontColor = .white
        roleLabel.position = CGPoint(x: 0, y: nameLabel.position.y - (isSubagent ? 10 : 13))
        roleLabel.horizontalAlignmentMode = .center
        if agentInfo.roleTitle != nil {
            addChild(roleLabel)
        }

        // Status indicator dot — smaller for subagents
        statusIndicator.fillColor = AgentSprite.colorForState(agentInfo.state)
        statusIndicator.strokeColor = .clear
        let indicatorOffset: CGFloat = isSubagent ? 5 : 6
        statusIndicator.position = CGPoint(x: size.width / 2 + indicatorOffset, y: size.height / 2 - indicatorOffset)
        statusIndicator.name = "statusIndicator"
        addChild(statusIndicator)

        // Thought bubble above the sprite — high z so it renders above all furniture
        // Proportionally closer for subagents
        thoughtBubble.position = CGPoint(x: 0, y: size.height / 2 + (isSubagent ? 20 : 30))
        thoughtBubble.zPosition = 200
        addChild(thoughtBubble)
    }

    // MARK: - State Updates

    /// Updates this sprite to reflect new agent info.
    public func update(with newInfo: AgentInfo) {
        let oldState = agentInfo.state
        let oldName = agentInfo.name
        let oldRoleTitle = agentInfo.roleTitle
        agentInfo = newInfo

        let stateColor = AgentSprite.colorForState(newInfo.state)

        // Update name label if name changed (smart naming refinement)
        if newInfo.name != oldName {
            nameLabel.text = newInfo.name
        }

        // Update role title label if it changed (e.g., Developer → Planner → Lead)
        if newInfo.roleTitle != oldRoleTitle {
            roleLabel.text = newInfo.roleTitle ?? ""
            if roleLabel.parent == nil && newInfo.roleTitle != nil {
                addChild(roleLabel)
            }
        }

        // Update status indicator color and shape — task 4.8
        // Plan mode overrides status color to purple/indigo
        if newInfo.isPlanMode {
            statusIndicator.fillColor = SKColor(red: 0.502, green: 0.376, blue: 0.816, alpha: 1.0)
        } else {
            statusIndicator.fillColor = stateColor
        }
        updateStatusIndicatorShape(for: newInfo.state)

        // Update planning clipboard overlay
        updatePlanModeOverlay(isPlanMode: newInfo.isPlanMode)

        // Update thought bubble — determine best text once, call bubble once
        let desc = newInfo.currentTaskDescription
        let bubbleText: String
        if !newInfo.recentTools.isEmpty && newInfo.state != .finished && newInfo.state != .idle {
            bubbleText = newInfo.recentTools.first!.summary
        } else if newInfo.isPlanMode && !desc.isEmpty {
            bubbleText = "Planning: \(desc)"
        } else {
            bubbleText = desc
        }
        thoughtBubble.update(text: bubbleText, for: newInfo.state)

        // Trigger animation change if state changed
        if oldState != newInfo.state {
            transitionToState(newInfo.state, from: oldState)

            // Move back to desk when state changes — use proper walk for long distances
            if let deskID = assignedDeskID {
                let layout = OfficeLayout.defaultLayout()
                if let desk = layout.desks.first(where: { $0.id == deskID }) {
                    let isWorking = [.thinking, .writingCode, .readingFiles, .runningCommand, .searching, .supervisingAgents].contains(newInfo.state)
                    let targetY = isWorking ? desk.chairPosition.y + 15 : desk.chairPosition.y
                    let targetPos = CGPoint(x: desk.chairPosition.x, y: targetY)
                    let distance = hypot(targetPos.x - position.x, targetPos.y - position.y)

                    if !isWalking && distance > 2 {
                        if distance > 30 {
                            // Far away (diagonal coworking, supervising, etc.) — proper walk with pathfinding
                            stopWalking()
                            removeAction(forKey: "deskScoot")
                            let path = layout.findPath(from: position, to: targetPos)
                            walk(to: targetPos, via: path, speedMultiplier: 1.5)
                        } else {
                            // Small scoot (forward/back at own desk) — quick slide proportional to distance
                            let duration = TimeInterval(distance / 100.0)
                            let moveAction = SKAction.move(to: targetPos, duration: max(duration, 0.15))
                            moveAction.timingMode = .easeInEaseOut
                            run(moveAction, withKey: "deskScoot")
                        }
                    }
                }
            }

            // Pulse animation on state change — task 4.8
            pulseStatusIndicator()
        }
    }

    /// Updates status indicator to square for error, circle for everything else — task 4.8
    private func updateStatusIndicatorShape(for state: AgentState) {
        let r: CGFloat = isSubagent ? 3 : 4
        if state == .error {
            statusIndicator.path = CGPath(
                rect: CGRect(x: -r, y: -r, width: r * 2, height: r * 2),
                transform: nil
            )
        } else {
            statusIndicator.path = CGPath(
                ellipseIn: CGRect(x: -r, y: -r, width: r * 2, height: r * 2),
                transform: nil
            )
        }
    }

    /// Shows or hides the planning clipboard overlay based on plan mode.
    private func updatePlanModeOverlay(isPlanMode: Bool) {
        let overlayName = "planningClipboard"
        if isPlanMode {
            guard childNode(withName: overlayName) == nil else { return }
            let clipboard = SKSpriteNode(
                texture: TextureManager.shared.texture(for: TextureManager.itemPlanningClipboard),
                size: CGSize(width: 18, height: 24)
            )
            clipboard.position = CGPoint(x: -size.width / 2 - 6, y: 0)
            clipboard.zPosition = 6
            clipboard.name = overlayName
            clipboard.alpha = 0
            addChild(clipboard)
            clipboard.run(SKAction.fadeIn(withDuration: 0.3))
        } else {
            if let clipboard = childNode(withName: overlayName) {
                clipboard.run(SKAction.sequence([
                    SKAction.fadeOut(withDuration: 0.3),
                    SKAction.removeFromParent()
                ]))
            }
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

    /// Handles state transition by swapping animation directly (no cross-fade).
    private func transitionToState(_ newState: AgentState, from oldState: AgentState) {
        // Remove idle ZZZ if leaving idle and reset roaming behavior
        if oldState == .idle {
            removeZZZ()
            idleStartTime = nil
            cancelIdleRoaming()
        }

        // Cancel deep thinking pacing if leaving deepThinking
        if oldState == .deepThinking {
            cancelDeepThinkingPacing()
        }

        // Remove previous state emitter
        removeStateEmitter()

        // Direct animation swap — SpriteKit handles texture changes seamlessly
        playAnimation(for: newState)
        currentAnimationState = newState
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

        case .supervisingAgents:
            // 4 frames, 2.0s per frame, loop forever — arms-crossed watching
            let animate = SKAction.animate(with: frames, timePerFrame: 2.0)
            run(SKAction.repeatForever(animate), withKey: "stateAnimation")

        case .deepThinking:
            // Same as thinking: 4 frames, 2.0s, loop forever + sparkle emitter
            let animate = SKAction.animate(with: frames, timePerFrame: 2.0)
            run(SKAction.repeatForever(animate), withKey: "stateAnimation")
            addSparkleEmitter()
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
        emitter.numParticlesToEmit = 60
        emitter.particleLifetime = 2.0
        emitter.particleLifetimeRange = 0.5
        emitter.particleColor = .green
        emitter.particleColorBlendFactor = 1.0
        emitter.particleColorSequence = nil
        emitter.particleColorRedRange = 1.0
        emitter.particleColorGreenRange = 1.0
        emitter.particleColorBlueRange = 1.0
        emitter.particleColorAlphaSpeed = -0.5
        emitter.particleSpeed = 80
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

        // Brief shake action on celebration
        if self.parent != nil {
            let shakeRight = SKAction.moveBy(x: 2, y: 0, duration: 0.05)
            let shakeLeft = SKAction.moveBy(x: -4, y: 0, duration: 0.05)
            let shakeBack = SKAction.moveBy(x: 2, y: 0, duration: 0.05)
            let shake = SKAction.sequence([shakeRight, shakeLeft, shakeBack, shakeRight, shakeLeft, shakeBack])
            self.run(shake, withKey: "celebrationShake")
        }

        addChild(emitter)
        stateEmitter = emitter

        // Auto-remove after 2 seconds
        emitter.run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.run { [weak self] in
                self?.stateEmitter = nil
            },
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
    public func walk(to destination: CGPoint, via waypoints: [CGPoint], speedMultiplier: CGFloat = 1.0, completion: (() -> Void)? = nil) {
        guard !isWalking else { return }
        isWalking = true

        var actions: [SKAction] = []
        let speed: CGFloat = 100 * speedMultiplier

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
        case .supervisingAgents:
            SKColor(red: 0.251, green: 0.690, blue: 0.690, alpha: 1.0) // #40B0B0 teal
        case .deepThinking:
            SKColor(red: 0.910, green: 0.753, blue: 0.251, alpha: 1.0) // Amber/gold
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

        if wasRoaming {
            stopWalking()

            // Walk back to desk chair if we still have one assigned
            // Hustle (1.5x) if in an active working state
            if let deskID = assignedDeskID {
                let layout = OfficeLayout.defaultLayout()
                if let desk = layout.desks.first(where: { $0.id == deskID }) {
                    let path = layout.findPath(from: position, to: desk.chairPosition)
                    let hustle: CGFloat = agentInfo.state.isActive ? 1.5 : 1.0
                    walk(to: desk.chairPosition, via: path, speedMultiplier: hustle)
                }
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

        case .leaveOffice:
            break
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
        case .petTheDog: emoji = "🐕"
        case .whiteboard: emoji = "💡"
        case .waterPlant: emoji = "🌱"
        case .getCoffee: emoji = "☕️"
        case .loungeCouch: emoji = "🛋"
        case .radioArea: emoji = "🎵"
        case .printerArea: emoji = "🖨"
        case .fetchWithDog: emoji = "🎾"
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
    func removeActionBubble() {
        childNode(withName: "action_bubble")?.removeFromParent()
    }

    // MARK: - Deep Thinking Pacing Behavior

    /// Manages deep thinking pacing behavior when the agent has been thinking for a long time.
    public lazy var deepThinkingBehaviorManager = DeepThinkingBehaviorManager()

    /// Whether the agent is currently pacing during deep thinking.
    public var isDeepThinkingPacing: Bool {
        deepThinkingBehaviorManager.isPacing
    }

    /// Starts the deep thinking pacing cycle and shows the 🤔 emoji.
    public func startDeepThinkingPacing(waypoints: [CGPoint], otherAgentPositions: [CGPoint] = []) {
        let action = deepThinkingBehaviorManager.startPacing(waypoints: waypoints, otherAgentPositions: otherAgentPositions)
        showDeepThinkingEmoji()
        handleDeepThinkingAction(action, layout: OfficeLayout.defaultLayout())
    }

    /// Cancels deep thinking pacing and walks back to desk at 1.5x speed.
    public func cancelDeepThinkingPacing() {
        let wasPacing = deepThinkingBehaviorManager.isPacing
        deepThinkingBehaviorManager.reset()
        removeDeepThinkingEmoji()

        if wasPacing {
            stopWalking()

            // Walk back to desk if assigned
            if let deskID = assignedDeskID {
                let layout = OfficeLayout.defaultLayout()
                if let desk = layout.desks.first(where: { $0.id == deskID }) {
                    let path = layout.findPath(from: position, to: desk.chairPosition)
                    walk(to: desk.chairPosition, via: path, speedMultiplier: 1.5)
                }
            }
        }
    }

    /// Handles a deep thinking action by walking or showing the emoji.
    public func handleDeepThinkingAction(_ action: DeepThinkingBehaviorManager.DeepThinkingAction, layout: OfficeLayout) {
        switch action {
        case .walkTo(let destination):
            let path = layout.findPath(from: position, to: destination)
            walk(to: destination, via: path, speedMultiplier: 0.7) { [weak self] in
                self?.deepThinkingBehaviorManager.walkCompleted()
            }
        case .showThinkingEmoji:
            showDeepThinkingEmoji()
        }
    }

    /// Shows a floating 🤔 emoji above the agent.
    private func showDeepThinkingEmoji() {
        guard childNode(withName: "deep_thinking_emoji") == nil else { return }

        let emoji = SKLabelNode(text: "\u{1F914}")
        emoji.fontSize = 18
        emoji.position = CGPoint(x: 0, y: size.height / 2 + 20)
        emoji.name = "deep_thinking_emoji"
        emoji.zPosition = 190

        // Fade in
        emoji.alpha = 0
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        // Gentle bob
        let bobUp = SKAction.moveBy(x: 0, y: 4, duration: 1.0)
        bobUp.timingMode = .easeInEaseOut
        let bobDown = bobUp.reversed()
        let bob = SKAction.repeatForever(SKAction.sequence([bobUp, bobDown]))
        emoji.run(SKAction.group([fadeIn, bob]))

        addChild(emoji)
    }

    /// Removes the deep thinking emoji.
    private func removeDeepThinkingEmoji() {
        childNode(withName: "deep_thinking_emoji")?.removeFromParent()
    }
}
