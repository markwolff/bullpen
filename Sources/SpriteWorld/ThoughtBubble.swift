import SpriteKit
import Models

/// A thought/speech bubble that appears above an agent sprite to show
/// what the agent is currently doing.
public class ThoughtBubble: SKNode {
    public enum Style: String, Sendable, CaseIterable {
        case response
        case thought
        case toolUse
        case report
        case plan
        case waiting
        case error
    }

    private struct Palette {
        let fillColor: SKColor
        let strokeColor: SKColor
        let textColor: SKColor
        let accentColor: SKColor
    }

    /// The background bubble shape
    private let bubbleBackground: SKShapeNode

    /// Accent decoration inside the bubble
    private let accentShape: SKShapeNode

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

    /// The style associated with the pending text
    private var pendingStyle: Style?

    /// Timestamp when the bubble was last shown (for cooldown enforcement)
    private var lastShownTime: TimeInterval = 0

    /// Cooldown duration between bubble displays (5s ± 500ms jitter)
    private var cooldownDuration: TimeInterval = 5.0

    /// The style currently visible in the bubble
    public private(set) var currentStyle: Style = .response

    /// Whether we're currently in cooldown
    private var inCooldown: Bool {
        guard lastShownTime > 0 else { return false }
        let elapsed = CACurrentMediaTime() - lastShownTime
        return elapsed < cooldownDuration
    }

    public override init() {
        bubbleBackground = SKShapeNode()
        accentShape = SKShapeNode()
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
        bubbleBackground.lineJoin = .round
        bubbleBackground.lineCap = .round

        accentShape.lineWidth = 0
        accentShape.alpha = 0.8
        accentShape.isAntialiased = false

        // Add the bubble background as a direct child (not clipped)
        addChild(bubbleBackground)
        addChild(accentShape)

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
    public func update(text: String?, for state: AgentState, style: Style? = nil) {
        let resolvedStyle = style ?? Self.defaultStyle(for: state)

        guard let text, !text.isEmpty, state != .idle && state != .finished else {
            hide()
            pendingText = nil
            pendingState = nil
            pendingStyle = nil
            return
        }

        // Don't show if the message and style are the same as what was last displayed
        guard text != lastDisplayedText || resolvedStyle != currentStyle else {
            pendingText = nil
            pendingState = nil
            pendingStyle = nil
            return
        }

        let shouldBypassCooldown = resolvedStyle != currentStyle

        if inCooldown && !shouldBypassCooldown {
            // Replace any previous pending text with the latest (no queue)
            pendingText = text
            pendingState = state
            pendingStyle = resolvedStyle
            schedulePendingCheck()
        } else {
            displayBubble(text: text, style: resolvedStyle)
        }
    }

    /// Actually shows the bubble with the given text, records cooldown, and schedules auto-hide.
    private func displayBubble(text: String, style: Style) {
        lastDisplayedText = text
        currentStyle = style
        label.text = text
        applyPalette(for: style)
        updateBubblePath(for: style)
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
        let style = pendingStyle ?? Self.defaultStyle(for: state)
        pendingStyle = nil

        // Re-validate: state may have changed while waiting
        guard state != .idle && state != .finished else { return }
        guard text != lastDisplayedText || style != currentStyle else { return }

        displayBubble(text: text, style: style)
    }

    /// Rebuilds the bubble shape to fit the current label text.
    private func updateBubblePath(for style: Style) {
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

        let bubbleWidth = max(textWidth + padding * 2, style == .toolUse ? 96 : 60)
        let bubbleHeight = max(textHeight + padding * 2, 30)

        let rect = CGRect(
            x: -bubbleWidth / 2,
            y: -bubbleHeight / 2,
            width: bubbleWidth,
            height: bubbleHeight
        )

        bubbleBackground.path = bubblePath(for: style, rect: rect)
        accentShape.path = accentPath(for: style, rect: rect)

        // Update the crop mask to match the bubble rect
        let maskNode = SKShapeNode()
        maskNode.path = maskPath(for: style, rect: rect)
        maskNode.fillColor = .white
        cropNode.maskNode = maskNode
    }

    /// Shows the bubble with a fade-in animation.
    public func show() {
        removeAction(forKey: "styleMotion")
        isHidden = false
        setScale(1.0)
        zRotation = 0
        position.x = 0
        alpha = 0
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.2)
        let popIn = SKAction.scale(to: 1.03, duration: 0.12)
        popIn.timingMode = .easeOut
        let settle = SKAction.scale(to: 1.0, duration: 0.12)
        settle.timingMode = .easeIn
        run(SKAction.group([fadeIn, SKAction.sequence([popIn, settle])]), withKey: "bubbleAlpha")
        applyStyleMotion()
    }

    /// Hides the bubble with a fade-out animation.
    public func hide() {
        removeAction(forKey: "autoHide")
        removeAction(forKey: "styleMotion")
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
            updateBubblePath(for: currentStyle)
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

    private func applyPalette(for style: Style) {
        let palette = palette(for: style)
        bubbleBackground.fillColor = palette.fillColor
        bubbleBackground.strokeColor = palette.strokeColor
        label.fontColor = palette.textColor
        accentShape.fillColor = palette.accentColor
        accentShape.strokeColor = palette.accentColor
    }

    private func applyStyleMotion() {
        let motion: SKAction?

        switch currentStyle {
        case .response:
            motion = nil
        case .thought:
            let up = SKAction.moveBy(x: 0, y: 3, duration: 0.9)
            up.timingMode = .easeInEaseOut
            motion = SKAction.repeatForever(SKAction.sequence([up, up.reversed()]))
        case .toolUse:
            let nudgeUp = SKAction.moveBy(x: 0, y: 2, duration: 0.18)
            nudgeUp.timingMode = .easeOut
            motion = SKAction.repeatForever(SKAction.sequence([nudgeUp, nudgeUp.reversed(), .wait(forDuration: 0.5)]))
        case .report:
            let tiltLeft = SKAction.rotate(toAngle: -.pi / 64, duration: 0.22)
            tiltLeft.timingMode = .easeInEaseOut
            let tiltRight = SKAction.rotate(toAngle: .pi / 64, duration: 0.22)
            tiltRight.timingMode = .easeInEaseOut
            let reset = SKAction.rotate(toAngle: 0, duration: 0.22)
            reset.timingMode = .easeInEaseOut
            motion = SKAction.sequence([tiltLeft, tiltRight, reset])
        case .plan:
            let driftLeft = SKAction.moveBy(x: -1.5, y: 0, duration: 0.7)
            driftLeft.timingMode = .easeInEaseOut
            motion = SKAction.repeatForever(SKAction.sequence([driftLeft, driftLeft.reversed()]))
        case .waiting:
            let swayLeft = SKAction.rotate(toAngle: -.pi / 90, duration: 0.5)
            swayLeft.timingMode = .easeInEaseOut
            let swayRight = SKAction.rotate(toAngle: .pi / 90, duration: 0.5)
            swayRight.timingMode = .easeInEaseOut
            motion = SKAction.repeatForever(SKAction.sequence([swayLeft, swayRight, .rotate(toAngle: 0, duration: 0.5)]))
        case .error:
            let left = SKAction.moveBy(x: -4, y: 0, duration: 0.05)
            let right = SKAction.moveBy(x: 8, y: 0, duration: 0.05)
            motion = SKAction.sequence([left, right, left, SKAction.moveTo(x: 0, duration: 0.05)])
        }

        if let motion {
            run(motion, withKey: "styleMotion")
        }
    }

    private static func defaultStyle(for state: AgentState) -> Style {
        switch state {
        case .thinking, .deepThinking:
            .thought
        case .readingFiles:
            .report
        case .runningCommand, .searching:
            .toolUse
        case .waitingForInput:
            .waiting
        case .error:
            .error
        case .supervisingAgents:
            .plan
        case .idle, .writingCode, .finished:
            .response
        }
    }

    private func palette(for style: Style) -> Palette {
        switch style {
        case .response:
            return Palette(
                fillColor: SKColor(white: 1.0, alpha: 1.0),
                strokeColor: SKColor(white: 0.72, alpha: 1.0),
                textColor: .black,
                accentColor: SKColor(white: 0.85, alpha: 0.85)
            )
        case .thought:
            return Palette(
                fillColor: SKColor(red: 0.99, green: 0.97, blue: 0.86, alpha: 1.0),
                strokeColor: SKColor(red: 0.83, green: 0.71, blue: 0.34, alpha: 1.0),
                textColor: SKColor(red: 0.27, green: 0.22, blue: 0.08, alpha: 1.0),
                accentColor: SKColor(red: 0.95, green: 0.84, blue: 0.40, alpha: 0.55)
            )
        case .toolUse:
            return Palette(
                fillColor: SKColor(red: 0.12, green: 0.16, blue: 0.18, alpha: 0.96),
                strokeColor: SKColor(red: 0.35, green: 0.84, blue: 0.71, alpha: 1.0),
                textColor: SKColor(red: 0.90, green: 0.98, blue: 0.95, alpha: 1.0),
                accentColor: SKColor(red: 0.23, green: 0.72, blue: 0.59, alpha: 0.6)
            )
        case .report:
            return Palette(
                fillColor: SKColor(red: 0.94, green: 0.98, blue: 1.0, alpha: 1.0),
                strokeColor: SKColor(red: 0.41, green: 0.66, blue: 0.86, alpha: 1.0),
                textColor: SKColor(red: 0.12, green: 0.21, blue: 0.30, alpha: 1.0),
                accentColor: SKColor(red: 0.65, green: 0.83, blue: 0.94, alpha: 0.7)
            )
        case .plan:
            return Palette(
                fillColor: SKColor(red: 0.93, green: 0.96, blue: 1.0, alpha: 1.0),
                strokeColor: SKColor(red: 0.39, green: 0.56, blue: 0.89, alpha: 1.0),
                textColor: SKColor(red: 0.10, green: 0.19, blue: 0.35, alpha: 1.0),
                accentColor: SKColor(red: 0.53, green: 0.69, blue: 0.95, alpha: 0.75)
            )
        case .waiting:
            return Palette(
                fillColor: SKColor(red: 1.0, green: 0.96, blue: 0.90, alpha: 1.0),
                strokeColor: SKColor(red: 0.84, green: 0.63, blue: 0.28, alpha: 1.0),
                textColor: SKColor(red: 0.30, green: 0.21, blue: 0.07, alpha: 1.0),
                accentColor: SKColor(red: 0.95, green: 0.79, blue: 0.42, alpha: 0.7)
            )
        case .error:
            return Palette(
                fillColor: SKColor(red: 1.0, green: 0.92, blue: 0.92, alpha: 1.0),
                strokeColor: SKColor(red: 0.84, green: 0.26, blue: 0.26, alpha: 1.0),
                textColor: SKColor(red: 0.40, green: 0.05, blue: 0.05, alpha: 1.0),
                accentColor: SKColor(red: 0.96, green: 0.46, blue: 0.46, alpha: 0.75)
            )
        }
    }

    private func bubblePath(for style: Style, rect: CGRect) -> CGPath {
        switch style {
        case .response:
            return makeSpeechPath(rect: rect)
        case .thought:
            return makeThoughtPath(rect: rect)
        case .toolUse:
            return makeTerminalPath(rect: rect)
        case .report:
            return makeDocumentPath(rect: rect)
        case .plan:
            return makePlanPath(rect: rect)
        case .waiting:
            return makeWaitingPath(rect: rect)
        case .error:
            return makeErrorBurstPath(rect: rect)
        }
    }

    private func maskPath(for style: Style, rect: CGRect) -> CGPath {
        switch style {
        case .report:
            return CGPath(roundedRect: rect.insetBy(dx: 5, dy: 4), cornerWidth: 6, cornerHeight: 6, transform: nil)
        case .error:
            return CGPath(roundedRect: rect.insetBy(dx: 8, dy: 6), cornerWidth: 10, cornerHeight: 10, transform: nil)
        default:
            return CGPath(roundedRect: rect.insetBy(dx: 4, dy: 3), cornerWidth: 8, cornerHeight: 8, transform: nil)
        }
    }

    private func accentPath(for style: Style, rect: CGRect) -> CGPath? {
        switch style {
        case .response:
            return nil
        case .thought:
            let path = CGMutablePath()
            path.addEllipse(in: CGRect(x: rect.minX + 10, y: rect.maxY - 12, width: 10, height: 6))
            path.addEllipse(in: CGRect(x: rect.midX - 8, y: rect.maxY - 10, width: 16, height: 6))
            path.addEllipse(in: CGRect(x: rect.maxX - 22, y: rect.maxY - 13, width: 12, height: 6))
            return path
        case .toolUse:
            return CGPath(rect: CGRect(x: rect.minX + 10, y: rect.maxY - 9, width: rect.width - 20, height: 3), transform: nil)
        case .report:
            let fold = CGMutablePath()
            let size: CGFloat = 14
            fold.move(to: CGPoint(x: rect.maxX - size, y: rect.maxY))
            fold.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            fold.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - size))
            fold.closeSubpath()
            return fold
        case .plan:
            let path = CGMutablePath()
            path.addRect(CGRect(x: rect.minX + 8, y: rect.maxY - 9, width: rect.width - 16, height: 3))
            path.addRect(CGRect(x: rect.minX + 8, y: rect.midY + 4, width: rect.width * 0.45, height: 2))
            path.addRect(CGRect(x: rect.minX + 8, y: rect.midY - 4, width: rect.width * 0.60, height: 2))
            return path
        case .waiting:
            let path = CGMutablePath()
            for index in 0..<3 {
                path.addEllipse(in: CGRect(x: rect.midX - 14 + CGFloat(index * 10), y: rect.minY + 6, width: 5, height: 5))
            }
            return path
        case .error:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: rect.minX + 10, y: rect.maxY - 10))
            path.addLine(to: CGPoint(x: rect.maxX - 10, y: rect.minY + 10))
            path.addLine(to: CGPoint(x: rect.maxX - 16, y: rect.minY + 10))
            path.addLine(to: CGPoint(x: rect.minX + 4, y: rect.maxY - 10))
            path.closeSubpath()
            return path
        }
    }

    private func makeSpeechPath(rect: CGRect) -> CGPath {
        let path = CGMutablePath()
        path.addRoundedRect(in: rect, cornerWidth: 10, cornerHeight: 10)
        path.move(to: CGPoint(x: rect.midX - 16, y: rect.minY + 2))
        path.addLine(to: CGPoint(x: rect.midX - 3, y: rect.minY - 12))
        path.addLine(to: CGPoint(x: rect.midX + 6, y: rect.minY + 2))
        path.closeSubpath()
        return path
    }

    private func makeThoughtPath(rect: CGRect) -> CGPath {
        let path = CGMutablePath()
        path.addEllipse(in: CGRect(x: rect.minX + 2, y: rect.minY + 4, width: rect.width * 0.34, height: rect.height * 0.72))
        path.addEllipse(in: CGRect(x: rect.minX + rect.width * 0.20, y: rect.minY + 8, width: rect.width * 0.40, height: rect.height * 0.78))
        path.addEllipse(in: CGRect(x: rect.minX + rect.width * 0.48, y: rect.minY + 4, width: rect.width * 0.34, height: rect.height * 0.72))
        path.addEllipse(in: CGRect(x: rect.minX + rect.width * 0.68, y: rect.minY + 8, width: rect.width * 0.22, height: rect.height * 0.60))
        path.addEllipse(in: CGRect(x: rect.midX - 14, y: rect.minY - 10, width: 10, height: 10))
        path.addEllipse(in: CGRect(x: rect.midX - 3, y: rect.minY - 18, width: 8, height: 8))
        return path
    }

    private func makeTerminalPath(rect: CGRect) -> CGPath {
        let inset: CGFloat = 10
        let path = CGMutablePath()
        path.move(to: CGPoint(x: rect.minX + inset, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY + 4))
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + inset + 12, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY - 8))
        path.addLine(to: CGPoint(x: rect.minX + inset, y: rect.midY - 4))
        path.closeSubpath()
        return path
    }

    private func makeDocumentPath(rect: CGRect) -> CGPath {
        let fold: CGFloat = 16
        let path = CGMutablePath()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - fold, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - fold))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }

    private func makePlanPath(rect: CGRect) -> CGPath {
        let cut: CGFloat = 8
        let path = CGMutablePath()
        path.move(to: CGPoint(x: rect.minX + cut, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cut))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + cut))
        path.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + cut, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cut))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cut))
        path.closeSubpath()
        return path
    }

    private func makeWaitingPath(rect: CGRect) -> CGPath {
        let path = CGMutablePath()
        path.addRoundedRect(in: rect, cornerWidth: 12, cornerHeight: 12)
        path.addEllipse(in: CGRect(x: rect.midX - 6, y: rect.minY - 9, width: 6, height: 6))
        path.addEllipse(in: CGRect(x: rect.midX + 2, y: rect.minY - 15, width: 5, height: 5))
        path.addEllipse(in: CGRect(x: rect.midX + 9, y: rect.minY - 21, width: 4, height: 4))
        return path
    }

    private func makeErrorBurstPath(rect: CGRect) -> CGPath {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let path = CGMutablePath()
        let points = 12
        for index in 0..<points {
            let angle = (CGFloat(index) / CGFloat(points)) * .pi * 2
            let radiusX = (index.isMultiple(of: 2) ? rect.width * 0.58 : rect.width * 0.45)
            let radiusY = (index.isMultiple(of: 2) ? rect.height * 0.62 : rect.height * 0.44)
            let point = CGPoint(
                x: center.x + cos(angle) * radiusX,
                y: center.y + sin(angle) * radiusY
            )
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}
