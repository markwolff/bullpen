import SpriteKit
import Models

/// A thought/speech bubble that appears above an agent sprite to show
/// what the agent is currently doing.
public class ThoughtBubble: SKNode {

    /// The background bubble shape
    private let bubbleBackground: SKShapeNode

    /// The text label inside the bubble
    private let label: SKLabelNode

    /// Maximum width of the bubble before text wraps
    private let maxWidth: CGFloat = 200

    /// Padding inside the bubble
    private let padding: CGFloat = 12

    /// The last time the text was changed (for fade timer) — task 4.9
    private var lastChangeTime: TimeInterval = 0

    /// Whether the bubble has faded due to inactivity — task 4.9
    private var hasFaded: Bool = false

    /// Duration before fading to 50% opacity — task 4.9
    private let fadeTimeout: TimeInterval = 10.0

    public override init() {
        bubbleBackground = SKShapeNode()
        label = SKLabelNode()
        super.init()
        setupNodes()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func setupNodes() {
        // Configure the label
        label.fontName = "Menlo"
        label.fontSize = 11
        label.fontColor = .black
        label.numberOfLines = 2
        label.preferredMaxLayoutWidth = maxWidth - padding * 2
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center

        // Configure the bubble background
        bubbleBackground.fillColor = SKColor(white: 1.0, alpha: 1.0)
        bubbleBackground.strokeColor = SKColor(white: 0.7, alpha: 1.0)
        bubbleBackground.lineWidth = 1.5
        bubbleBackground.alpha = 1.0

        addChild(bubbleBackground)
        addChild(label)

        // Start hidden
        isHidden = true
    }

    /// Updates the bubble to show the given text.
    /// Pass nil or empty string to hide the bubble.
    public func update(text: String?, for state: AgentState) {
        guard let text, !text.isEmpty, state != .idle && state != .finished else {
            hide()
            return
        }

        // Reset fade timer on text change — task 4.9
        let textChanged = label.text != text
        label.text = text
        updateBubblePath()
        show()

        if textChanged {
            resetFadeTimer()
            setupScrollIfNeeded()
        }
    }

    /// Rebuilds the bubble shape to fit the current label text.
    private func updateBubblePath() {
        let textFrame = label.frame
        let bubbleWidth = max(textFrame.width + padding * 2, 60)
        let bubbleHeight = max(textFrame.height + padding * 2, 30)

        let rect = CGRect(
            x: -bubbleWidth / 2,
            y: -bubbleHeight / 2,
            width: bubbleWidth,
            height: bubbleHeight
        )

        bubbleBackground.path = CGPath(roundedRect: rect, cornerWidth: 8, cornerHeight: 8, transform: nil)
    }

    /// Shows the bubble with a fade-in animation.
    public func show() {
        guard isHidden else { return }
        isHidden = false
        alpha = 0
        run(SKAction.fadeIn(withDuration: 0.2))
        hasFaded = false
    }

    /// Hides the bubble with a fade-out animation.
    public func hide() {
        guard !isHidden else { return }
        removeAction(forKey: "fadeTimeout")
        run(SKAction.fadeOut(withDuration: 0.2)) { [weak self] in
            self?.isHidden = true
        }
    }

    // MARK: - 8.14: Text Scroll for Long Text

    /// Sets up a scrolling animation for text that exceeds the bubble width.
    private func setupScrollIfNeeded() {
        label.removeAction(forKey: "scroll")

        let availableWidth = maxWidth - padding * 2

        // Measure the text as single-line to detect overflow, since numberOfLines=2 causes wrapping
        let textWidth: CGFloat
        if let text = label.text, let font = NSFont(name: label.fontName ?? "Menlo", size: label.fontSize) {
            let size = (text as NSString).size(withAttributes: [.font: font])
            textWidth = size.width
        } else {
            textWidth = label.frame.width
        }

        if textWidth > availableWidth {
            let scrollDistance = textWidth - availableWidth + 20
            let scrollLeft = SKAction.moveBy(x: -scrollDistance, y: 0, duration: TimeInterval(scrollDistance / 30))
            let pause = SKAction.wait(forDuration: 2.0)
            let scrollBack = SKAction.moveBy(x: scrollDistance, y: 0, duration: 0)
            let sequence = SKAction.sequence([pause, scrollLeft, pause, scrollBack])
            label.run(SKAction.repeatForever(sequence), withKey: "scroll")
        }
    }

    /// Whether the label currently has a scroll action (for testing).
    public var hasScrollAction: Bool {
        label.action(forKey: "scroll") != nil
    }

    // MARK: - Fade Timer — task 4.9

    /// Resets the inactivity fade timer. After fadeTimeout seconds with no text change,
    /// the bubble fades to 50% opacity.
    private func resetFadeTimer() {
        hasFaded = false
        removeAction(forKey: "fadeTimeout")

        // Restore full opacity if we had faded
        run(SKAction.fadeAlpha(to: 1.0, duration: 0.1))

        // Schedule fade after timeout
        let wait = SKAction.wait(forDuration: fadeTimeout)
        let fade = SKAction.fadeAlpha(to: 0.5, duration: 0.5)
        let sequence = SKAction.sequence([wait, fade])
        run(sequence, withKey: "fadeTimeout")
    }
}
