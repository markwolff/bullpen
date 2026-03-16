import SpriteKit

/// An overlay on the whiteboard showing live office stats:
/// total agents served today, currently active count, and a sparkline.
public class WhiteboardStatsOverlay: SKNode {

    private let agentCountLabel: SKLabelNode
    private let activeCountLabel: SKLabelNode
    private var sparklineBars: [SKShapeNode] = []

    public override init() {
        agentCountLabel = SKLabelNode()
        activeCountLabel = SKLabelNode()
        super.init()
        setupLabels()
        setupSparkline()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func setupLabels() {
        agentCountLabel.fontName = "Menlo"
        agentCountLabel.fontSize = 6
        agentCountLabel.fontColor = SKColor(red: 0.2, green: 0.2, blue: 0.8, alpha: 1.0)
        agentCountLabel.horizontalAlignmentMode = .left
        agentCountLabel.position = CGPoint(x: -45, y: 15)
        agentCountLabel.text = "Today: 0"
        agentCountLabel.zPosition = 1
        addChild(agentCountLabel)

        activeCountLabel.fontName = "Menlo"
        activeCountLabel.fontSize = 6
        activeCountLabel.fontColor = SKColor(red: 0.2, green: 0.6, blue: 0.2, alpha: 1.0)
        activeCountLabel.horizontalAlignmentMode = .left
        activeCountLabel.position = CGPoint(x: -45, y: 5)
        activeCountLabel.text = "Active: 0"
        activeCountLabel.zPosition = 1
        addChild(activeCountLabel)
    }

    private func setupSparkline() {
        for i in 0..<12 {
            let bar = SKShapeNode(rectOf: CGSize(width: 2, height: 1))
            bar.fillColor = SKColor(red: 0.314, green: 0.784, blue: 0.471, alpha: 1.0)
            bar.strokeColor = .clear
            bar.position = CGPoint(x: -45 + CGFloat(i) * 4, y: -10)
            bar.zPosition = 1
            addChild(bar)
            sparklineBars.append(bar)
        }
    }

    /// Updates the overlay with current stats.
    public func updateStats(totalAgentsToday: Int, activeCount: Int, activityHistory: [Int]) {
        agentCountLabel.text = "Today: \(totalAgentsToday)"
        activeCountLabel.text = "Active: \(activeCount)"

        // Update sparkline bars
        let maxVal = max(1, activityHistory.max() ?? 1)
        for (i, bar) in sparklineBars.enumerated() {
            let value = i < activityHistory.count ? activityHistory[i] : 0
            let height = max(1, CGFloat(value) / CGFloat(maxVal) * 10)
            bar.path = CGPath(rect: CGRect(x: -1, y: 0, width: 2, height: height), transform: nil)
        }
    }
}
