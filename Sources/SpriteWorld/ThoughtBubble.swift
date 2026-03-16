import SpriteKit
import Models

/// A thought/speech bubble that appears above an agent sprite to show
/// what the agent is currently doing.
public class ThoughtBubble: SKNode {

    /// The background bubble shape
    private let bubbleBackground: SKShapeNode

    /// The text label inside the bubble
    private let label: SKLabelNode

    /// Crop node that clips scrolling text to the bubble bounds
    private let cropNode: SKCropNode

    /// Maximum width of the bubble before text wraps
    private let maxWidth: CGFloat = 200

    /// Padding inside the bubble
    private let padding: CGFloat = 12

    /// The last text that was displayed (to avoid re-showing identical content)
    private var lastDisplayedText: String?

    public override init() {
        bubbleBackground = SKShapeNode()
        label = SKLabelNode()
        cropNode = SKCropNode()
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

        // Add the bubble background as a direct child (not clipped)
        addChild(bubbleBackground)

        // Add the label inside a crop node so scrolling text is clipped
        cropNode.addChild(label)
        addChild(cropNode)

        // Start hidden
        isHidden = true
    }

    /// Updates the bubble to show the given text.
    /// Pass nil or empty string to hide the bubble.
    /// Only shows the bubble if the text has changed from the current message.
    public func update(text: String?, for state: AgentState) {
        guard let text, !text.isEmpty, state != .idle && state != .finished else {
            hide()
            return
        }

        // Don't re-show the bubble if the message hasn't changed
        guard text != lastDisplayedText else { return }

        lastDisplayedText = text
        label.text = text
        updateBubblePath()
        show()
        resetFadeTimer()
        setupScrollIfNeeded()
        scheduleAutoHide()
    }

    /// Rebuilds the bubble shape to fit the current label text.
    private func updateBubblePath() {
        // Compute text size manually for accurate multi-line dimensions
        let textWidth: CGFloat
        let textHeight: CGFloat
        if let text = label.text, let font = NSFont(name: label.fontName ?? "Menlo", size: label.fontSize) {
            let constrainedSize = CGSize(width: maxWidth - padding * 2, height: .greatestFiniteMagnitude)
            let boundingRect = (text as NSString).boundingRect(
                with: constrainedSize,
                options: [.usesLineFragmentOrigin],
                attributes: [.font: font]
            )
            textWidth = boundingRect.width
            textHeight = boundingRect.height
        } else {
            let textFrame = label.frame
            textWidth = textFrame.width
            textHeight = textFrame.height
        }

        let bubbleWidth = max(textWidth + padding * 2, 60)
        let bubbleHeight = max(textHeight + padding * 2, 30)

        let rect = CGRect(
            x: -bubbleWidth / 2,
            y: -bubbleHeight / 2,
            width: bubbleWidth,
            height: bubbleHeight
        )

        bubbleBackground.path = CGPath(roundedRect: rect, cornerWidth: 8, cornerHeight: 8, transform: nil)

        // Update the crop mask to match the bubble rect
        let maskNode = SKShapeNode()
        maskNode.path = CGPath(roundedRect: rect, cornerWidth: 8, cornerHeight: 8, transform: nil)
        maskNode.fillColor = .white
        cropNode.maskNode = maskNode
    }

    /// Shows the bubble with a fade-in animation, staggered by a small random delay
    /// so multiple agents spawning together don't all pop bubbles at once.
    public func show() {
        guard isHidden else { return }
        isHidden = false
        alpha = 0
        let delay = SKAction.wait(forDuration: TimeInterval.random(in: 0.0...0.6))
        let fadeIn = SKAction.fadeIn(withDuration: 0.2)
        run(SKAction.sequence([delay, fadeIn]), withKey: "showDelay")
    }

    /// Hides the bubble with a fade-out animation.
    public func hide() {
        removeAction(forKey: "autoHide")
        removeAction(forKey: "showDelay")
        guard !isHidden else { return }
        run(SKAction.fadeOut(withDuration: 0.2)) { [weak self] in
            self?.isHidden = true
        }
    }

    // MARK: - 8.14: Text Truncation for Long Text

    /// Truncates text that exceeds the bubble width instead of scrolling.
    private func setupScrollIfNeeded() {
        label.removeAction(forKey: "scroll")
        // Reset label position in case a previous scroll moved it
        label.position = .zero

        guard let text = label.text, !text.isEmpty else { return }

        let availableWidth = maxWidth - padding * 2

        // Measure single-line width to detect overflow
        guard let font = NSFont(name: label.fontName ?? "Menlo", size: label.fontSize) else { return }
        let fullWidth = (text as NSString).size(withAttributes: [.font: font]).width

        if fullWidth > availableWidth * 2 {
            // Text is too long even for 2 lines — truncate with ellipsis
            var truncated = text
            while truncated.count > 3 {
                truncated = String(truncated.dropLast())
                let w = (truncated as NSString).size(withAttributes: [.font: font]).width
                if w <= availableWidth * 2 {
                    break
                }
            }
            label.text = truncated + "…"
            updateBubblePath()
        }
    }

    /// Whether the label currently has a scroll action (for testing).
    /// Always false now that scrolling is replaced with truncation.
    public var hasScrollAction: Bool {
        false
    }

    // MARK: - Latest Tool Display

    /// Shows only the latest tool summary. No queueing — only the most recent matters.
    public func refreshCycle(recentTools: [String]) {
        // Only care about the very latest tool
        guard let latest = recentTools.first else { return }
        // Don't re-show if the content is the same as what was last displayed
        guard latest != lastDisplayedText else { return }

        lastDisplayedText = latest
        label.text = latest
        updateBubblePath()
        show()
        resetFadeTimer()
        setupScrollIfNeeded()
        scheduleAutoHide()
    }

    /// No-op — cycling is removed. Kept for API compatibility.
    public func updateCycle(deltaTime: TimeInterval) {
        // Intentionally empty — we only show the latest update, no cycling
    }

    // MARK: - Auto-Hide

    /// Schedules the bubble to fade out after 2 seconds.
    private func scheduleAutoHide() {
        removeAction(forKey: "autoHide")
        let wait = SKAction.wait(forDuration: TimeInterval.random(in: 1.8...2.5))
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let markHidden = SKAction.run { [weak self] in
            self?.isHidden = true
        }
        run(SKAction.sequence([wait, fadeOut, markHidden]), withKey: "autoHide")
    }

    // MARK: - Opacity

    /// Restores full opacity and removes any pending fade action.
    private func resetFadeTimer() {
        removeAction(forKey: "fadeTimeout")
        run(SKAction.fadeAlpha(to: 1.0, duration: 0.1))
    }
}
