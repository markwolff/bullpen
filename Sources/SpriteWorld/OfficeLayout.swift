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

    /// Long communal table definition — one table surface with multiple seat positions
    public struct TableDefinition: Sendable {
        public let id: Int
        public let centerY: CGFloat
        public let seatXPositions: [CGFloat]

        /// Left edge of the table surface (with margin before first seat)
        public var leftX: CGFloat { (seatXPositions.first ?? 0) - 40 }
        /// Right edge of the table surface (with margin after last seat)
        public var rightX: CGFloat { (seatXPositions.last ?? 0) + 40 }
        /// Width of the table surface
        public var width: CGFloat { rightX - leftX }
        /// Center X of the table surface
        public var centerX: CGFloat { (leftX + rightX) / 2 }
    }

    /// Size of the office scene in points
    public let sceneSize: CGSize

    /// All available seat positions (one per agent) along the communal tables
    public let desks: [DeskPosition]

    /// The communal tables in the office
    public let tables: [TableDefinition]

    /// Area where agents can walk (simplified as a rect for now)
    public let walkableArea: CGRect

    /// Creates the default office layout with two long communal tables.
    public static func defaultLayout() -> OfficeLayout {
        let sceneSize = CGSize(width: 1280, height: 768)

        // Two long communal tables, 8 seats each, tight co-working spacing
        let seatXPositions: [CGFloat] = [200, 300, 400, 500, 600, 700, 800, 900]
        let tableDefinitions = [
            TableDefinition(id: 0, centerY: 430, seatXPositions: seatXPositions),
            TableDefinition(id: 1, centerY: 260, seatXPositions: seatXPositions),
        ]

        var desks: [DeskPosition] = []
        var deskID = 0
        for table in tableDefinitions {
            for x in table.seatXPositions {
                desks.append(DeskPosition(
                    id: deskID,
                    position: CGPoint(x: x, y: table.centerY),
                    chairPosition: CGPoint(x: x, y: table.centerY - 30)
                ))
                deskID += 1
            }
        }

        return OfficeLayout(
            sceneSize: sceneSize,
            desks: desks,
            tables: tableDefinitions,
            walkableArea: CGRect(x: 50, y: 50, width: 1180, height: 668)
        )
    }

    /// Returns the nearest unoccupied desk position.
    /// - Parameter occupiedDeskIDs: IDs of desks that already have an agent assigned
    /// - Returns: An available desk, or nil if the office is full
    public func nextAvailableDesk(occupiedDeskIDs: Set<Int>) -> DeskPosition? {
        desks.first { !occupiedDeskIDs.contains($0.id) }
    }

    // MARK: - Table Obstacles

    /// Bounding rectangles for table+chair obstacles (for pathfinding)
    public var deskObstacles: [CGRect] {
        tables.map { table in
            CGRect(
                x: table.leftX,
                y: table.centerY - 40,
                width: table.width,
                height: 50
            )
        }
    }

    // MARK: - Aisles

    /// Y coordinates of horizontal aisles between/around communal tables
    public var aisleYPositions: [CGFloat] {
        [550, 345, 170, 100]
    }

    /// X coordinates of vertical corridors (left wall, center aisle, right wall)
    public var corridorXPositions: [CGFloat] {
        [100, 550, 1180]
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

    /// Dog bowl position - near the lounge area
    public var dogBowlPosition: CGPoint {
        CGPoint(x: 150, y: 90)
    }

    /// Dog starting/sleep position - near her bowl
    public var dogSleepPosition: CGPoint {
        CGPoint(x: 180, y: 80)
    }

    /// Positions where dog toys can be scattered in the office
    public var dogToyPositions: [CGPoint] {
        [
            CGPoint(x: 120, y: 70),   // Near the dog bowl area
            CGPoint(x: 280, y: 85),   // Middle of the office floor
            CGPoint(x: 420, y: 75),   // Near the far side
        ]
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

    /// Pizza drop position (open area below tables)
    public var pizzaDropPosition: CGPoint {
        CGPoint(x: sceneSize.width / 2, y: 120)
    }

    /// Standup huddle positions (circle formation in open area between tables)
    public var standupHuddlePositions: [CGPoint] {
        let center = CGPoint(x: sceneSize.width * 0.5, y: 345)
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

    // MARK: - New Decoration Positions

    /// Position for the bird cage on the back wall
    public var birdCagePosition: CGPoint {
        CGPoint(x: 1050, y: sceneSize.height - 75)
    }

    /// Position for the coffee station (left wall, between tables)
    public var coffeeStationPosition: CGPoint {
        CGPoint(x: 100, y: 345)
    }

    /// Position where the barista stands (behind the station)
    public var baristaPosition: CGPoint {
        CGPoint(x: 100, y: 330)
    }

    /// Position where an agent stands to order coffee from barista
    public var baristaCustomerPosition: CGPoint {
        CGPoint(x: 150, y: 330)
    }

    /// Position for coat hooks near the door
    public var coatHooksPosition: CGPoint {
        CGPoint(x: sceneSize.width - 50, y: 500)
    }

    /// Position for a small rug under the coffee station
    public var coffeeRugPosition: CGPoint {
        CGPoint(x: 110, y: 330)
    }

    /// Position for motivational poster on left wall
    public var poster2Position: CGPoint {
        CGPoint(x: 30, y: 500)
    }

    /// Position for animated wall clock
    public var wallClockPosition: CGPoint {
        CGPoint(x: 800, y: sceneSize.height - 30)
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
