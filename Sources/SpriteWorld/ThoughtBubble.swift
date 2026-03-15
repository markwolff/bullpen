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
        bubbleBackground.fillColor = .white
        bubbleBackground.strokeColor = SKColor(white: 0.7, alpha: 1.0)
        bubbleBackground.lineWidth = 1.5
        bubbleBackground.alpha = 0.92

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

        label.text = text
        updateBubblePath()
        show()
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

        // TODO: Add a little "tail" pointing down toward the agent sprite
        bubbleBackground.path = CGPath(roundedRect: rect, cornerWidth: 8, cornerHeight: 8, transform: nil)
    }

    /// Shows the bubble with a fade-in animation.
    public func show() {
        guard isHidden else { return }
        isHidden = false
        alpha = 0
        run(SKAction.fadeIn(withDuration: 0.2))
    }

    /// Hides the bubble with a fade-out animation.
    public func hide() {
        guard !isHidden else { return }
        run(SKAction.fadeOut(withDuration: 0.2)) { [weak self] in
            self?.isHidden = true
        }
    }
}
