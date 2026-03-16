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
        let sceneSize = CGSize(width: 1280, height: 768)

        // Dense startup layout: 4 rows x 4 columns = 16 laptop desks
        var desks: [DeskPosition] = []
        let columnX: [CGFloat] = [200, 450, 700, 950]
        let rowY: [CGFloat] = [520, 400, 280, 160]

        var deskID = 0
        for y in rowY {
            for x in columnX {
                desks.append(DeskPosition(
                    id: deskID,
                    position: CGPoint(x: x, y: y),
                    chairPosition: CGPoint(x: x, y: y - 30)
                ))
                deskID += 1
            }
        }

        return OfficeLayout(
            sceneSize: sceneSize,
            desks: desks,
            walkableArea: CGRect(x: 50, y: 50, width: 1180, height: 668)
        )
    }

    /// Returns the nearest unoccupied desk position.
    /// - Parameter occupiedDeskIDs: IDs of desks that already have an agent assigned
    /// - Returns: An available desk, or nil if the office is full
    public func nextAvailableDesk(occupiedDeskIDs: Set<Int>) -> DeskPosition? {
        desks.first { !occupiedDeskIDs.contains($0.id) }
    }

    // MARK: - Desk Obstacles

    /// Bounding rectangles for desk+chair obstacles (for pathfinding)
    public var deskObstacles: [CGRect] {
        desks.map { desk in
            CGRect(
                x: desk.position.x - 30,
                y: desk.chairPosition.y - 10,
                width: 60,
                height: desk.position.y - desk.chairPosition.y + 20
            )
        }
    }

    // MARK: - Aisles

    /// Y coordinates of horizontal aisles between desk rows
    public var aisleYPositions: [CGFloat] {
        [580, 460, 340, 220, 100]
    }

    /// X coordinates of vertical corridors (left wall, center aisle, right wall)
    public var corridorXPositions: [CGFloat] {
        [100, 575, 1180]
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

    /// Position for the lounge couch
    public var loungePosition: CGPoint {
        CGPoint(x: 80, y: 80)
    }

    /// Position to stand near the radio
    public var radioStandPosition: CGPoint {
        CGPoint(x: 130, y: sceneSize.height - 100)
    }

    /// Position to stand near the printer
    public var printerStandPosition: CGPoint {
        CGPoint(x: sceneSize.width - 120, y: 130)
    }

    /// Position for coffee machine (near water cooler)
    public var coffeeMachinePosition: CGPoint {
        CGPoint(x: sceneSize.width - 140, y: sceneSize.height * 2 / 3 - 50)
    }

    /// Chat positions flanking the water cooler
    public var waterCoolerChatPositions: (left: CGPoint, right: CGPoint) {
        let base = waterCoolerStandPosition
        return (
            left: CGPoint(x: base.x - 25, y: base.y),
            right: CGPoint(x: base.x + 25, y: base.y)
        )
    }

    /// Pizza drop position (center of rug area)
    public var pizzaDropPosition: CGPoint {
        CGPoint(x: sceneSize.width / 2, y: 270)
    }

    /// Standup huddle positions (circle formation near center-right)
    public var standupHuddlePositions: [CGPoint] {
        let center = CGPoint(x: sceneSize.width * 0.65, y: 340)
        let radius: CGFloat = 50
        return (0..<8).map { i in
            let angle = CGFloat(i) * (.pi * 2 / 8)
            return CGPoint(x: center.x + cos(angle) * radius,
                          y: center.y + sin(angle) * radius)
        }
    }

    /// Achievement shelf position
    public var achievementShelfPosition: CGPoint {
        CGPoint(x: sceneSize.width * 0.75, y: sceneSize.height - 75)
    }

    /// Radio position
    public var radioPosition: CGPoint {
        CGPoint(x: 130, y: sceneSize.height - 80)
    }

    // MARK: - Pathfinding

    /// Generates a corridor-based path from one point to another, routing through aisles.
    /// - Returns: Array of waypoints the sprite should walk through
    public func findPath(from start: CGPoint, to end: CGPoint) -> [CGPoint] {
        let startAisle = nearestAisleY(to: start.y)
        let endAisle = nearestAisleY(to: end.y)

        if startAisle == endAisle {
            return [
                CGPoint(x: start.x, y: startAisle),
                CGPoint(x: end.x, y: startAisle)
            ]
        }

        // Route through nearest vertical corridor
        let corridor = nearestCorridorX(to: start.x)
        return [
            CGPoint(x: start.x, y: startAisle),
            CGPoint(x: corridor, y: startAisle),
            CGPoint(x: corridor, y: endAisle),
            CGPoint(x: end.x, y: endAisle)
        ]
    }

    /// Returns the nearest aisle Y coordinate to the given Y position.
    private func nearestAisleY(to y: CGFloat) -> CGFloat {
        aisleYPositions.min(by: { abs($0 - y) < abs($1 - y) }) ?? y
    }

    private func nearestCorridorX(to x: CGFloat) -> CGFloat {
        corridorXPositions.min(by: { abs($0 - x) < abs($1 - x) }) ?? x
    }
}
