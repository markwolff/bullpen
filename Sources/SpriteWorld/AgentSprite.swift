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

    /// Visual state indicator (colored dot)
    private let statusIndicator: SKShapeNode

    // MARK: - Initialization

    public init(agentInfo: AgentInfo) {
        self.agentInfo = agentInfo
        self.thoughtBubble = ThoughtBubble()
        self.nameLabel = SKLabelNode()
        self.statusIndicator = SKShapeNode(circleOfRadius: 4)

        // TODO: Replace with actual sprite texture/atlas
        // For now, use a colored rectangle as placeholder
        let placeholderSize = CGSize(width: 32, height: 48)
        let placeholderColor: SKColor = agentInfo.agentType == .claudeCode
            ? SKColor(red: 0.85, green: 0.45, blue: 0.2, alpha: 1.0)   // Orange for Claude
            : SKColor(red: 0.2, green: 0.6, blue: 0.85, alpha: 1.0)    // Blue for Codex

        super.init(texture: nil, color: placeholderColor, size: placeholderSize)

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
        statusIndicator.fillColor = colorForState(agentInfo.state)
        statusIndicator.strokeColor = .clear
        statusIndicator.position = CGPoint(x: size.width / 2 + 6, y: size.height / 2 - 6)
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

        // Update status indicator color
        statusIndicator.fillColor = colorForState(newInfo.state)

        // Update thought bubble
        thoughtBubble.update(text: newInfo.currentTaskDescription, for: newInfo.state)

        // Trigger animation change if state changed
        if oldState != newInfo.state {
            playAnimation(for: newInfo.state)
        }
    }

    // MARK: - Animations

    /// Plays the appropriate animation for the given agent state.
    func playAnimation(for state: AgentState) {
        removeAction(forKey: "stateAnimation")

        switch state {
        case .idle:
            // TODO: Idle breathing/blinking animation
            playIdleAnimation()

        case .thinking:
            // TODO: Scratching head, looking up animation
            playThinkingAnimation()

        case .writingCode:
            // TODO: Typing animation with keyboard sounds
            playTypingAnimation()

        case .readingFiles:
            // TODO: Reading/scrolling animation
            playReadingAnimation()

        case .runningCommand:
            // TODO: Watching a terminal animation
            playTypingAnimation()

        case .searching:
            // TODO: Looking around animation
            playThinkingAnimation()

        case .waitingForInput:
            // TODO: Looking at camera / tapping foot
            playIdleAnimation()

        case .error:
            // TODO: Distressed animation, red flash
            playErrorAnimation()

        case .finished:
            // TODO: Standing up, stretching
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
    private func colorForState(_ state: AgentState) -> SKColor {
        switch state {
        case .idle: SKColor.gray
        case .thinking: SKColor.yellow
        case .writingCode: SKColor.green
        case .readingFiles: SKColor.cyan
        case .runningCommand: SKColor.orange
        case .searching: SKColor.purple
        case .waitingForInput: SKColor.blue
        case .error: SKColor.red
        case .finished: SKColor.darkGray
        }
    }
}
