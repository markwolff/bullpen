import SpriteKit

enum PathMovement {
    static func sequence(
        from start: CGPoint,
        points: [CGPoint],
        speed: CGFloat,
        timingMode: SKActionTimingMode = .easeInEaseOut,
        beforeSegment: ((CGPoint, CGPoint) -> Void)? = nil,
        completion: (() -> Void)? = nil
    ) -> SKAction? {
        var actions: [SKAction] = []
        var previous = start

        for point in deduplicated(points) {
            let distance = hypot(point.x - previous.x, point.y - previous.y)
            guard distance > 0.5 else { continue }

            let segmentStart = previous
            let segmentEnd = point
            if let beforeSegment {
                actions.append(SKAction.run {
                    beforeSegment(segmentStart, segmentEnd)
                })
            }

            let move = SKAction.move(to: point, duration: TimeInterval(distance / speed))
            move.timingMode = timingMode
            actions.append(move)
            previous = point
        }

        if let completion {
            actions.append(SKAction.run(completion))
        }

        guard !actions.isEmpty else { return nil }
        return SKAction.sequence(actions)
    }

    static func deduplicated(_ points: [CGPoint]) -> [CGPoint] {
        var result: [CGPoint] = []

        for point in points {
            guard let last = result.last else {
                result.append(point)
                continue
            }

            if hypot(last.x - point.x, last.y - point.y) > 0.5 {
                result.append(point)
            }
        }

        return result
    }
}
