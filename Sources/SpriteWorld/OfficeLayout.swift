import Foundation
import SpriteKit

/// Defines the layout of the office world: desk positions, walkable areas,
/// and pathfinding for agent sprites.
public struct OfficeLayout: Sendable {
    /// A position in the office where a desk can be placed
    public struct DeskPosition: Sendable, Identifiable {
        public let id: Int
        public let position: CGPoint       // Center of the desk in scene coordinates
        public let chairPosition: CGPoint  // Where the agent sprite sits
        public let facingDirection: CGFloat // Angle the agent faces when seated (radians)

        public init(id: Int, position: CGPoint, chairPosition: CGPoint, facingDirection: CGFloat = 0) {
            self.id = id
            self.position = position
            self.chairPosition = chairPosition
            self.facingDirection = facingDirection
        }
    }

    /// Size of the office scene in points
    public let sceneSize: CGSize

    /// All available desk positions in the office
    public let desks: [DeskPosition]

    /// Area where agents can walk (simplified as a rect for now)
    public let walkableArea: CGRect

    /// Creates the default office layout with Stardew Valley-proportioned desk spacing.
    public static func defaultLayout() -> OfficeLayout {
        let sceneSize = CGSize(width: 1024, height: 768)

        // Desks arranged in two rows with wider spacing for larger sprites
        var desks: [DeskPosition] = []
        let deskSpacing: CGFloat = 220
        let rowY: [CGFloat] = [370, 170]
        let startX: CGFloat = 170

        var deskID = 0
        for y in rowY {
            for col in 0..<4 {
                let x = startX + CGFloat(col) * deskSpacing
                desks.append(DeskPosition(
                    id: deskID,
                    position: CGPoint(x: x, y: y),
                    chairPosition: CGPoint(x: x, y: y - 60)
                ))
                deskID += 1
            }
        }

        return OfficeLayout(
            sceneSize: sceneSize,
            desks: desks,
            walkableArea: CGRect(x: 50, y: 50, width: 924, height: 668)
        )
    }

    /// Returns the nearest unoccupied desk position.
    /// - Parameter occupiedDeskIDs: IDs of desks that already have an agent assigned
    /// - Returns: An available desk, or nil if the office is full
    public func nextAvailableDesk(occupiedDeskIDs: Set<Int>) -> DeskPosition? {
        desks.first { !occupiedDeskIDs.contains($0.id) }
    }

    /// Generates a simple path from one point to another, avoiding obstacles.
    /// - Returns: Array of waypoints the sprite should walk through
    public func findPath(from start: CGPoint, to end: CGPoint) -> [CGPoint] {
        // TODO: Implement proper A* pathfinding on a grid
        // For now, just do a simple L-shaped path through the walkable area
        let midPoint = CGPoint(x: end.x, y: start.y)
        return [start, midPoint, end]
    }
}
