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

    /// The latest pending text waiting to be shown after cooldown expires
    private var pendingText: String?

    /// The state associated with the pending text
    private var pendingState: AgentState?

    /// Timestamp when the bubble was last shown (for cooldown enforcement)
    private var lastShownTime: TimeInterval = 0

    /// Cooldown duration between bubble displays (5s ± 500ms jitter)
    private var cooldownDuration: TimeInterval = 5.0

    /// Whether we're currently in cooldown
    private var inCooldown: Bool {
        guard lastShownTime > 0 else { return false }
        let elapsed = CACurrentMediaTime() - lastShownTime
        return elapsed < cooldownDuration
    }

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
    /// Enforces a 5s ± 500ms cooldown between displays. Only the latest message is kept;
    /// no queuing occurs. If the latest message matches the last displayed text, it is skipped.
    public func update(text: String?, for state: AgentState) {
        guard let text, !text.isEmpty, state != .idle && state != .finished && state != .deepThinking else {
            hide()
            pendingText = nil
            pendingState = nil
            return
        }

        // Don't show if the message is the same as what was last displayed
        guard text != lastDisplayedText else {
            pendingText = nil
            pendingState = nil
            return
        }

        if inCooldown {
            // Replace any previous pending text with the latest (no queue)
            pendingText = text
            pendingState = state
            schedulePendingCheck()
        } else {
            displayBubble(text: text)
        }
    }

    /// Actually shows the bubble with the given text, records cooldown, and schedules auto-hide.
    private func displayBubble(text: String) {
        lastDisplayedText = text
        label.text = text
        updateBubblePath()
        show()
        setupScrollIfNeeded()

        // Record show time and pick a new jittered cooldown for next time
        lastShownTime = CACurrentMediaTime()
        cooldownDuration = 5.0 + Double.random(in: -0.5...0.5)

        scheduleAutoHide()
    }

    /// Schedules a single check to display the pending text once cooldown expires.
    private func schedulePendingCheck() {
        removeAction(forKey: "pendingCheck")
        let remaining = cooldownDuration - (CACurrentMediaTime() - lastShownTime)
        guard remaining > 0 else {
            showPendingIfNeeded()
            return
        }
        let wait = SKAction.wait(forDuration: remaining)
        let check = SKAction.run { [weak self] in
            self?.showPendingIfNeeded()
        }
        run(SKAction.sequence([wait, check]), withKey: "pendingCheck")
    }

    /// Shows the pending text if it differs from the last displayed text.
    private func showPendingIfNeeded() {
        guard let text = pendingText, let state = pendingState else { return }
        pendingText = nil
        pendingState = nil

        // Re-validate: state may have changed while waiting
        guard state != .idle && state != .finished && state != .deepThinking else { return }
        guard text != lastDisplayedText else { return }

        displayBubble(text: text)
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

    /// Shows the bubble with a fade-in animation.
    public func show() {
        guard isHidden else { return }
        isHidden = false
        alpha = 0
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.2)
        run(fadeIn, withKey: "bubbleAlpha")
    }

    /// Hides the bubble with a fade-out animation.
    public func hide() {
        removeAction(forKey: "autoHide")
        guard !isHidden else { return }
        let fadeOut = SKAction.fadeAlpha(to: 0, duration: 0.2)
        let markHidden = SKAction.run { [weak self] in
            self?.isHidden = true
        }
        run(SKAction.sequence([fadeOut, markHidden]), withKey: "bubbleAlpha")
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

    /// The current visible bubble text after truncation.
    public var displayedText: String? {
        label.text
    }

    // MARK: - Auto-Hide

    /// Schedules the bubble to fade out after 2.5 seconds.
    private func scheduleAutoHide() {
        removeAction(forKey: "autoHide")
        let wait = SKAction.wait(forDuration: 2.5)
        let doHide = SKAction.run { [weak self] in
            self?.hide()
        }
        run(SKAction.sequence([wait, doHide]), withKey: "autoHide")
    }
}
