import Foundation
import CoreGraphics

// MARK: - WorldPathfinder

/// A* pathfinding that works with any `WorldLayout`.
///
/// Computes paths on a grid derived from the layout's walkable area and
/// collision obstacles. The grid cell size is fixed at 32 points.
///
/// Usage:
/// ```swift
/// let pathfinder = WorldPathfinder(layout: myLayout)
/// let waypoints = pathfinder.findPath(from: agentPos, to: destination)
/// ```
public struct WorldPathfinder: Sendable {

    private let walkableArea: CGRect
    private let collisionObstacles: [CGRect]
    private let sceneSize: CGSize

    private let cellSize: CGFloat = 32

    private var gridWidth: Int {
        Int(ceil(sceneSize.width / cellSize))
    }

    private var gridHeight: Int {
        Int(ceil(sceneSize.height / cellSize))
    }

    // MARK: - Initialization

    /// Creates a pathfinder from any world layout.
    public init(layout: any WorldLayout) {
        self.walkableArea = layout.walkableArea
        self.collisionObstacles = layout.collisionObstacles
        self.sceneSize = layout.sceneSize
    }

    /// Creates a pathfinder from explicit geometry (useful for testing).
    public init(sceneSize: CGSize, walkableArea: CGRect, collisionObstacles: [CGRect]) {
        self.sceneSize = sceneSize
        self.walkableArea = walkableArea
        self.collisionObstacles = collisionObstacles
    }

    // MARK: - Public API

    /// Finds a path from `start` to `end`, avoiding obstacles.
    /// Returns an array of waypoints the agent should walk through (not including `start`).
    /// If no path exists, returns the end point directly as a fallback.
    public func findPath(from start: CGPoint, to end: CGPoint) -> [CGPoint] {
        let resolvedStart = nearestWalkablePoint(to: start)
        let resolvedEnd = nearestWalkablePoint(to: end)

        guard hypot(resolvedEnd.x - resolvedStart.x, resolvedEnd.y - resolvedStart.y) > 8 else {
            return [resolvedEnd]
        }

        if canTravelDirectly(from: resolvedStart, to: resolvedEnd) {
            return [resolvedEnd]
        }

        let startCell = nearestWalkableCell(to: resolvedStart)
        let endCell = nearestWalkableCell(to: resolvedEnd)
        let cells = aStarPath(from: startCell, to: endCell)

        guard !cells.isEmpty else { return [resolvedEnd] }
        return condensedWaypoints(from: cells, start: resolvedStart, end: resolvedEnd)
    }

    /// Returns the nearest point that is walkable (not inside an obstacle).
    public func nearestWalkablePoint(to point: CGPoint) -> CGPoint {
        if isWalkablePoint(point) {
            return point
        }
        return centerOfCell(nearestWalkableCell(to: point))
    }

    /// Tests whether a point is walkable (inside walkable area and not inside any obstacle).
    public func isWalkablePoint(_ point: CGPoint, clearance: CGFloat = 12) -> Bool {
        guard walkableArea.insetBy(dx: clearance, dy: clearance).contains(point) else { return false }
        return !collisionObstacles.contains(where: { obstacle in
            obstacle.insetBy(dx: -clearance, dy: -clearance).contains(point)
        })
    }

    /// Tests whether a straight line between two points is free of obstacles.
    public func canTravelDirectly(from start: CGPoint, to end: CGPoint, sampleStep: CGFloat = 12) -> Bool {
        guard isWalkablePoint(start), isWalkablePoint(end) else { return false }

        let distance = hypot(end.x - start.x, end.y - start.y)
        let steps = max(Int(ceil(distance / sampleStep)), 1)

        for step in 0...steps {
            let progress = CGFloat(step) / CGFloat(steps)
            let sample = CGPoint(
                x: start.x + (end.x - start.x) * progress,
                y: start.y + (end.y - start.y) * progress
            )
            if !isWalkablePoint(sample) {
                return false
            }
        }

        return true
    }

    // MARK: - Grid

    private struct GridCell: Hashable {
        let x: Int
        let y: Int
    }

    private func nearestWalkableCell(to point: CGPoint) -> GridCell {
        var bestCell = GridCell(
            x: max(0, min(gridWidth - 1, Int(point.x / cellSize))),
            y: max(0, min(gridHeight - 1, Int(point.y / cellSize)))
        )
        var bestDistance = CGFloat.greatestFiniteMagnitude

        for y in 0..<gridHeight {
            for x in 0..<gridWidth {
                let cell = GridCell(x: x, y: y)
                guard isWalkable(cell) else { continue }
                let center = centerOfCell(cell)
                let distance = hypot(center.x - point.x, center.y - point.y)
                if distance < bestDistance {
                    bestDistance = distance
                    bestCell = cell
                }
            }
        }

        return bestCell
    }

    private func isWalkable(_ cell: GridCell) -> Bool {
        isWalkablePoint(centerOfCell(cell))
    }

    private func centerOfCell(_ cell: GridCell) -> CGPoint {
        CGPoint(
            x: CGFloat(cell.x) * cellSize + cellSize / 2,
            y: CGFloat(cell.y) * cellSize + cellSize / 2
        )
    }

    private func neighbors(of cell: GridCell) -> [GridCell] {
        let candidates = [
            GridCell(x: cell.x + 1, y: cell.y),
            GridCell(x: cell.x - 1, y: cell.y),
            GridCell(x: cell.x, y: cell.y + 1),
            GridCell(x: cell.x, y: cell.y - 1),
        ]

        return candidates.filter { candidate in
            candidate.x >= 0 && candidate.x < gridWidth &&
            candidate.y >= 0 && candidate.y < gridHeight &&
            isWalkable(candidate)
        }
    }

    // MARK: - A* Algorithm

    private func aStarPath(from start: GridCell, to goal: GridCell) -> [GridCell] {
        var openSet: Set<GridCell> = [start]
        var cameFrom: [GridCell: GridCell] = [:]
        var gScore: [GridCell: Int] = [start: 0]
        var fScore: [GridCell: Int] = [start: heuristic(from: start, to: goal)]

        while let current = openSet.min(by: {
            (fScore[$0] ?? .max) < (fScore[$1] ?? .max)
        }) {
            if current == goal {
                return reconstructPath(cameFrom: cameFrom, current: current)
            }

            openSet.remove(current)

            for neighbor in neighbors(of: current) {
                let tentative = (gScore[current] ?? .max) + 1
                if tentative < (gScore[neighbor] ?? .max) {
                    cameFrom[neighbor] = current
                    gScore[neighbor] = tentative
                    fScore[neighbor] = tentative + heuristic(from: neighbor, to: goal)
                    openSet.insert(neighbor)
                }
            }
        }

        return [start, goal]
    }

    private func reconstructPath(cameFrom: [GridCell: GridCell], current: GridCell) -> [GridCell] {
        var path = [current]
        var cursor = current
        while let previous = cameFrom[cursor] {
            cursor = previous
            path.append(previous)
        }
        return path.reversed()
    }

    private func heuristic(from start: GridCell, to end: GridCell) -> Int {
        abs(start.x - end.x) + abs(start.y - end.y)
    }

    // MARK: - Path Smoothing

    private func condensedWaypoints(from cells: [GridCell], start: CGPoint, end: CGPoint) -> [CGPoint] {
        let checkpoints = PathMovement.deduplicated([start] + cells.map(centerOfCell) + [end])
        return smoothedPath(checkpoints)
    }

    private func smoothedPath(_ checkpoints: [CGPoint]) -> [CGPoint] {
        guard checkpoints.count > 1 else { return checkpoints }

        var result: [CGPoint] = []
        var anchorIndex = 0

        while anchorIndex < checkpoints.count - 1 {
            var furthestReachable = anchorIndex + 1

            while furthestReachable + 1 < checkpoints.count,
                  canTravelDirectly(from: checkpoints[anchorIndex], to: checkpoints[furthestReachable + 1]) {
                furthestReachable += 1
            }

            result.append(checkpoints[furthestReachable])
            anchorIndex = furthestReachable
        }

        return PathMovement.deduplicated(result)
    }
}
