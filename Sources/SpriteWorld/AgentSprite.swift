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

    // MARK: - Initialization

    public init(agentInfo: AgentInfo) {
        self.agentInfo = agentInfo
        self.thoughtBubble = ThoughtBubble()
        self.nameLabel = SKLabelNode()
        self.statusIndicator = SKShapeNode(circleOfRadius: 4)

        // Use state-based color for the sprite body
        let placeholderSize = CGSize(width: 32, height: 48)
        let bodyColor = AgentSprite.colorForState(agentInfo.state)

        super.init(texture: nil, color: bodyColor, size: placeholderSize)

        self.name = "agent_\(agentInfo.id)"
        setupChildNodes()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func setupChildNodes() {
        // Name label below the sprite
        nameLabel.text = agentInfo.name
        nameLabel.fontName = "Helvetica-Bold"
        nameLabel.fontSize = 10
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

        // Thought bubble above the sprite
        thoughtBubble.position = CGPoint(x: 0, y: size.height / 2 + 30)
        addChild(thoughtBubble)
    }

    // MARK: - State Updates

    /// Updates this sprite to reflect new agent info.
    public func update(with newInfo: AgentInfo) {
        let oldState = agentInfo.state
        agentInfo = newInfo

        let stateColor = AgentSprite.colorForState(newInfo.state)

        // Update sprite body color to reflect state
        self.color = stateColor

        // Update status indicator color and shape — task 4.8
        statusIndicator.fillColor = stateColor
        updateStatusIndicatorShape(for: newInfo.state)

        // Update thought bubble
        thoughtBubble.update(text: newInfo.currentTaskDescription, for: newInfo.state)

        // Trigger animation change if state changed
        if oldState != newInfo.state {
            playAnimation(for: newInfo.state)

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

    // MARK: - Animations

    /// Plays the appropriate animation for the given agent state.
    public func playAnimation(for state: AgentState) {
        removeAction(forKey: "stateAnimation")

        switch state {
        case .idle:
            playIdleAnimation()

        case .thinking:
            playThinkingAnimation()

        case .writingCode:
            playTypingAnimation()

        case .readingFiles:
            playReadingAnimation()

        case .runningCommand:
            playTypingAnimation()

        case .searching:
            playThinkingAnimation()

        case .waitingForInput:
            playIdleAnimation()

        case .error:
            playErrorAnimation()

        case .finished:
            playIdleAnimation()
        }
    }

    private func playIdleAnimation() {
        // Gentle bobbing
        let bobUp = SKAction.moveBy(x: 0, y: 2, duration: 1.0)
        bobUp.timingMode = .easeInEaseOut
        let bobDown = bobUp.reversed()
        let bob = SKAction.sequence([bobUp, bobDown])
        run(SKAction.repeatForever(bob), withKey: "stateAnimation")
    }

    private func playThinkingAnimation() {
        // Slight rocking side to side
        let rotateLeft = SKAction.rotate(byAngle: 0.05, duration: 0.5)
        rotateLeft.timingMode = .easeInEaseOut
        let rotateRight = SKAction.rotate(byAngle: -0.1, duration: 1.0)
        rotateRight.timingMode = .easeInEaseOut
        let rotateCenter = SKAction.rotate(byAngle: 0.05, duration: 0.5)
        rotateCenter.timingMode = .easeInEaseOut
        let rock = SKAction.sequence([rotateLeft, rotateRight, rotateCenter])
        run(SKAction.repeatForever(rock), withKey: "stateAnimation")
    }

    private func playTypingAnimation() {
        // Quick little jitter to simulate typing
        let jitterLeft = SKAction.moveBy(x: -1, y: 0, duration: 0.05)
        let jitterRight = SKAction.moveBy(x: 2, y: 0, duration: 0.1)
        let jitterBack = SKAction.moveBy(x: -1, y: 0, duration: 0.05)
        let pause = SKAction.wait(forDuration: 0.1)
        let jitter = SKAction.sequence([jitterLeft, jitterRight, jitterBack, pause])
        run(SKAction.repeatForever(jitter), withKey: "stateAnimation")
    }

    private func playReadingAnimation() {
        // Slow nodding
        let nodDown = SKAction.moveBy(x: 0, y: -1, duration: 0.8)
        nodDown.timingMode = .easeInEaseOut
        let nodUp = nodDown.reversed()
        let nod = SKAction.sequence([nodDown, nodUp, SKAction.wait(forDuration: 0.5)])
        run(SKAction.repeatForever(nod), withKey: "stateAnimation")
    }

    private func playErrorAnimation() {
        // Flash red
        let flashRed = SKAction.colorize(with: .red, colorBlendFactor: 0.8, duration: 0.2)
        let flashBack = SKAction.colorize(withColorBlendFactor: 0, duration: 0.2)
        let flash = SKAction.sequence([flashRed, flashBack])
        run(SKAction.repeat(flash, count: 3), withKey: "stateAnimation")
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

        let sequence = SKAction.sequence(actions)
        run(sequence) { [weak self] in
            self?.isWalking = false
            completion?()
        }
    }

    // MARK: - Helpers

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
}
