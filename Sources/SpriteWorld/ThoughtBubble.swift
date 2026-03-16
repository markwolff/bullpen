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

    /// Cycle of recent tool summaries to display
    private var displayCycle: [String] = []

    /// Current index in the display cycle
    private var cycleIndex: Int = 0

    /// Timer for cycling
    private var cycleTimer: TimeInterval = 0

    /// Cycle interval with jitter (5s ± 500ms)
    private var cycleInterval: TimeInterval = TimeInterval.random(in: 4.5...5.5)

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
        guard label.text != text else { return }

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

    /// Shows the bubble with a fade-in animation.
    public func show() {
        guard isHidden else { return }
        isHidden = false
        alpha = 0
        run(SKAction.fadeIn(withDuration: 0.2))
    }

    /// Hides the bubble with a fade-out animation.
    public func hide() {
        removeAction(forKey: "autoHide")
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

    // MARK: - Cycle Display

    /// Updates the cycle array with recent tool summaries.
    public func refreshCycle(recentTools: [String]) {
        guard !recentTools.isEmpty else { return }
        displayCycle = recentTools
        cycleIndex = 0
    }

    /// Called each frame to advance the thought bubble cycle.
    public func updateCycle(deltaTime: TimeInterval) {
        guard displayCycle.count > 1 else { return }

        cycleTimer += deltaTime
        if cycleTimer >= cycleInterval {
            cycleTimer = 0
            cycleInterval = TimeInterval.random(in: 4.5...5.5) // ~5s with jitter

            // Find the next message that differs from the current one
            let startIndex = cycleIndex
            repeat {
                cycleIndex = (cycleIndex + 1) % displayCycle.count
            } while displayCycle[cycleIndex] == label.text && cycleIndex != startIndex

            let newText = displayCycle[cycleIndex]
            // Skip if we looped all the way around and every message is the same
            guard newText != label.text else { return }

            // Cross-fade to new text, then auto-hide after 2s
            isHidden = false
            let fadeOut = SKAction.fadeAlpha(to: 0.3, duration: 0.15)
            let swap = SKAction.run { [weak self] in
                self?.label.text = newText
                self?.updateBubblePath()
            }
            let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.15)
            run(SKAction.sequence([fadeOut, swap, fadeIn]), withKey: "cycleFade")
            scheduleAutoHide()
        }
    }

    // MARK: - Auto-Hide

    /// Schedules the bubble to fade out after 2 seconds.
    private func scheduleAutoHide() {
        removeAction(forKey: "autoHide")
        let wait = SKAction.wait(forDuration: 2.0)
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
