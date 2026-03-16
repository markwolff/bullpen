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

    // MARK: - Door Position

    /// Position of the office door (right wall, between desk rows)
    public var doorPosition: CGPoint {
        CGPoint(x: sceneSize.width - 30, y: sceneSize.height / 2 + 10)
    }

    /// Position an agent walks to before exiting through the door
    public var doorExitPosition: CGPoint {
        CGPoint(x: sceneSize.width - 60, y: sceneSize.height / 2 + 10)
    }

    // MARK: - Points of Interest (standing positions for idle behaviors)

    /// Position in front of the water cooler
    public var waterCoolerStandPosition: CGPoint {
        CGPoint(x: sceneSize.width - 100, y: sceneSize.height * 2 / 3 - 50)
    }

    /// Position in front of the bookshelf
    public var bookshelfStandPosition: CGPoint {
        CGPoint(x: sceneSize.width * 0.42, y: sceneSize.height - 140)
    }

    /// Position in front of the bulletin board
    public var bulletinBoardStandPosition: CGPoint {
        CGPoint(x: sceneSize.width * 0.62, y: sceneSize.height - 135)
    }

    /// Position in front of a window
    public var windowStandPosition: CGPoint {
        CGPoint(x: sceneSize.width / 2, y: sceneSize.height - 140)
    }

    /// Position in front of the whiteboard
    public var whiteboardStandPosition: CGPoint {
        CGPoint(x: sceneSize.width * 0.2, y: sceneSize.height - 140)
    }

    /// Positions near floor plants (agents can walk to water them)
    public var plantStandPositions: [CGPoint] {
        [
            CGPoint(x: 60, y: sceneSize.height - 140),  // Near top-left plant
            CGPoint(x: sceneSize.width - 60, y: sceneSize.height - 140),  // Near top-right plant
            CGPoint(x: 55, y: 100),  // Near bottom-left plant
            CGPoint(x: sceneSize.width - 55, y: 100),  // Near bottom-right plant
        ]
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
