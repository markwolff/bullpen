import Foundation
import SpriteKit

/// Defines the layout of the office world: desk positions, rooms,
/// collision geometry, and pathfinding for agent sprites.
public struct OfficeLayout: Sendable {
    public struct DeskPosition: Sendable, Identifiable {
        public let id: Int
        public let position: CGPoint
        public let chairPosition: CGPoint
        public let facingDirection: CGFloat

        public init(id: Int, position: CGPoint, chairPosition: CGPoint, facingDirection: CGFloat = 0) {
            self.id = id
            self.position = position
            self.chairPosition = chairPosition
            self.facingDirection = facingDirection
        }
    }

    public struct TableDefinition: Sendable {
        public let id: Int
        public let centerY: CGFloat
        public let seatXPositions: [CGFloat]

        public var leftX: CGFloat { (seatXPositions.first ?? 0) - 40 }
        public var rightX: CGFloat { (seatXPositions.last ?? 0) + 40 }
        public var width: CGFloat { rightX - leftX }
        public var centerX: CGFloat { (leftX + rightX) / 2 }
    }

    public struct RoomDefinition: Sendable, Identifiable {
        public let id: String
        public let name: String
        public let frame: CGRect

        public init(id: String, name: String, frame: CGRect) {
            self.id = id
            self.name = name
            self.frame = frame
        }
    }

    public struct Barrier: Sendable, Identifiable {
        public enum Kind: String, Sendable {
            case solidWall
            case glassWall
            case furniture
        }

        public let id: String
        public let kind: Kind
        public let rect: CGRect

        public init(id: String, kind: Kind, rect: CGRect) {
            self.id = id
            self.kind = kind
            self.rect = rect
        }
    }

    private struct GridCell: Hashable {
        let x: Int
        let y: Int
    }

    public let sceneSize: CGSize
    public let desks: [DeskPosition]
    public let tables: [TableDefinition]
    public let rooms: [RoomDefinition]
    public let walkableArea: CGRect
    public let barriers: [Barrier]

    public init(
        sceneSize: CGSize,
        desks: [DeskPosition],
        tables: [TableDefinition],
        rooms: [RoomDefinition],
        walkableArea: CGRect,
        barriers: [Barrier]
    ) {
        self.sceneSize = sceneSize
        self.desks = desks
        self.tables = tables
        self.rooms = rooms
        self.walkableArea = walkableArea
        self.barriers = barriers
    }

    /// Creates a multi-room office with three desk rooms and a recreation lounge.
    public static func defaultLayout() -> OfficeLayout {
        let sceneSize = CGSize(width: 1280, height: 768)

        let focusRoom = RoomDefinition(
            id: "focus_studio",
            name: "Focus Studio",
            frame: CGRect(x: 52, y: 320, width: 374, height: 396)
        )
        let loungeRoom = RoomDefinition(
            id: "recreation_lounge",
            name: "Recreation Lounge",
            frame: CGRect(x: 52, y: 52, width: 336, height: 212)
        )
        let spineRoom = RoomDefinition(
            id: "circulation_spine",
            name: "Circulation Spine",
            frame: CGRect(x: 430, y: 52, width: 92, height: 664)
        )
        let galleryRoom = RoomDefinition(
            id: "gallery",
            name: "Gallery",
            frame: CGRect(x: 524, y: 268, width: 704, height: 168)
        )
        let collaborationRoom = RoomDefinition(
            id: "collaboration_room",
            name: "Collaboration Room",
            frame: CGRect(x: 524, y: 436, width: 704, height: 280)
        )
        let buildRoom = RoomDefinition(
            id: "build_room",
            name: "Build Room",
            frame: CGRect(x: 524, y: 52, width: 704, height: 212)
        )

        let tableDefinitions = [
            TableDefinition(id: 0, centerY: 616, seatXPositions: [110, 165, 220, 275, 330, 385]),
            TableDefinition(id: 1, centerY: 506, seatXPositions: [110, 165, 220, 275, 330, 385]),
            TableDefinition(id: 2, centerY: 618, seatXPositions: [650, 740, 830, 920, 1010]),
            TableDefinition(id: 3, centerY: 520, seatXPositions: [650, 740, 830, 920, 1010]),
            TableDefinition(id: 4, centerY: 194, seatXPositions: [650, 750, 850, 950]),
            TableDefinition(id: 5, centerY: 120, seatXPositions: [650, 750, 850, 950]),
        ]

        var desks: [DeskPosition] = []
        var deskID = 0
        for table in tableDefinitions {
            for x in table.seatXPositions {
                desks.append(
                    DeskPosition(
                        id: deskID,
                        position: CGPoint(x: x, y: table.centerY),
                        chairPosition: CGPoint(x: x, y: table.centerY - 30)
                    )
                )
                deskID += 1
            }
        }

        let barriers = [
            Barrier(id: "focus_glass_upper", kind: .glassWall, rect: CGRect(x: 426, y: 320, width: 8, height: 150)),
            Barrier(id: "focus_glass_lower", kind: .glassWall, rect: CGRect(x: 426, y: 558, width: 8, height: 158)),
            Barrier(id: "lounge_wall_lower", kind: .solidWall, rect: CGRect(x: 388, y: 52, width: 8, height: 86)),
            Barrier(id: "lounge_wall_upper", kind: .solidWall, rect: CGRect(x: 388, y: 180, width: 8, height: 84)),
            Barrier(id: "entry_wall_lower", kind: .solidWall, rect: CGRect(x: 1232, y: 40, width: 8, height: 264)),
            Barrier(id: "entry_wall_upper", kind: .solidWall, rect: CGRect(x: 1232, y: 400, width: 8, height: 328)),
            Barrier(id: "build_glass_left", kind: .glassWall, rect: CGRect(x: 524, y: 264, width: 126, height: 8)),
            Barrier(id: "build_glass_right", kind: .glassWall, rect: CGRect(x: 730, y: 264, width: 498, height: 8)),
            Barrier(id: "collab_glass_left", kind: .glassWall, rect: CGRect(x: 524, y: 436, width: 126, height: 8)),
            Barrier(id: "collab_glass_right", kind: .glassWall, rect: CGRect(x: 730, y: 436, width: 498, height: 8)),
            Barrier(id: "coffee_bar", kind: .furniture, rect: CGRect(x: 1032, y: 300, width: 110, height: 44)),
            Barrier(id: "water_cooler", kind: .furniture, rect: CGRect(x: 1144, y: 312, width: 40, height: 72)),
            Barrier(id: "printer", kind: .furniture, rect: CGRect(x: 1148, y: 96, width: 36, height: 36)),
            Barrier(id: "ping_pong", kind: .furniture, rect: CGRect(x: 136, y: 118, width: 124, height: 60)),
        ]

        return OfficeLayout(
            sceneSize: sceneSize,
            desks: desks,
            tables: tableDefinitions,
            rooms: [focusRoom, loungeRoom, spineRoom, galleryRoom, collaborationRoom, buildRoom],
            walkableArea: CGRect(x: 40, y: 40, width: 1200, height: 688),
            barriers: barriers
        )
    }

    public func nextAvailableDesk(occupiedDeskIDs: Set<Int>) -> DeskPosition? {
        desks.filter { !occupiedDeskIDs.contains($0.id) }.randomElement()
    }

    // MARK: - Rooms and Obstacles

    public var glassPartitions: [Barrier] {
        barriers.filter { $0.kind == .glassWall }
    }

    public var solidPartitions: [Barrier] {
        barriers.filter { $0.kind == .solidWall }
    }

    public var furnitureObstacles: [CGRect] {
        barriers.compactMap { barrier in
            barrier.kind == .furniture ? barrier.rect : nil
        }
    }

    /// Table tops only. Chair landings remain walkable for seated agents.
    public var deskObstacles: [CGRect] {
        tables.map { table in
            CGRect(x: table.leftX, y: table.centerY - 12, width: table.width, height: 24)
        }
    }

    public var collisionObstacles: [CGRect] {
        barriers.map(\.rect) + deskObstacles
    }

    // MARK: - Aisles

    public var aisleYPositions: [CGFloat] {
        [642, 522, 352, 190, 104]
    }

    public var corridorXPositions: [CGFloat] {
        [162, 474, 718, 1036, 1186]
    }

    // MARK: - Door Position

    public var doorPosition: CGPoint {
        CGPoint(x: 1238, y: 352)
    }

    public var doorExitPosition: CGPoint {
        CGPoint(x: 1186, y: 352)
    }

    // MARK: - Points of Interest

    public var waterCoolerStandPosition: CGPoint {
        CGPoint(x: 1112, y: 314)
    }

    public var bookshelfStandPosition: CGPoint {
        CGPoint(x: 130, y: 652)
    }

    public var bulletinBoardStandPosition: CGPoint {
        CGPoint(x: 646, y: 352)
    }

    public var windowStandPosition: CGPoint {
        CGPoint(x: 904, y: 648)
    }

    public var whiteboardStandPosition: CGPoint {
        CGPoint(x: 592, y: 352)
    }

    public var plantStandPositions: [CGPoint] {
        [
            CGPoint(x: 86, y: 652),
            CGPoint(x: 1152, y: 648),
            CGPoint(x: 92, y: 96),
            CGPoint(x: 1190, y: 96),
        ]
    }

    public var loungePosition: CGPoint {
        CGPoint(x: 178, y: 146)
    }

    public var dogBowlPosition: CGPoint {
        CGPoint(x: 322, y: 92)
    }

    public var dogSleepPosition: CGPoint {
        CGPoint(x: 266, y: 92)
    }

    public var dogToyPositions: [CGPoint] {
        [
            CGPoint(x: 118, y: 102),
            CGPoint(x: 214, y: 116),
            CGPoint(x: 304, y: 150),
        ]
    }

    public var radioStandPosition: CGPoint {
        CGPoint(x: 116, y: 218)
    }

    public var printerStandPosition: CGPoint {
        CGPoint(x: 1112, y: 110)
    }

    public var coffeeMachinePosition: CGPoint {
        baristaCustomerPosition
    }

    public var waterCoolerChatPositions: (left: CGPoint, right: CGPoint) {
        let base = waterCoolerStandPosition
        return (
            left: CGPoint(x: base.x - 28, y: base.y),
            right: CGPoint(x: base.x + 28, y: base.y)
        )
    }

    public var pizzaDropPosition: CGPoint {
        CGPoint(x: 868, y: 352)
    }

    public var standupHuddlePositions: [CGPoint] {
        let center = pizzaDropPosition
        let radius: CGFloat = 64
        return (0..<8).map { index in
            let angle = CGFloat(index) * (.pi * 2 / 8)
            return CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )
        }
    }

    public var achievementShelfPosition: CGPoint {
        CGPoint(x: 1060, y: 690)
    }

    public var radioPosition: CGPoint {
        CGPoint(x: 100, y: 216)
    }

    public var birdCagePosition: CGPoint {
        CGPoint(x: 1172, y: 690)
    }

    public var coffeeStationPosition: CGPoint {
        CGPoint(x: 1040, y: 324)
    }

    public var baristaPosition: CGPoint {
        CGPoint(x: 1088, y: 324)
    }

    public var baristaCustomerPosition: CGPoint {
        CGPoint(x: 992, y: 324)
    }

    public var coatHooksPosition: CGPoint {
        CGPoint(x: 1170, y: 412)
    }

    public var coffeeRugPosition: CGPoint {
        CGPoint(x: 1040, y: 304)
    }

    public var poster2Position: CGPoint {
        CGPoint(x: 92, y: 614)
    }

    public var desklessPacingPositions: [CGPoint] {
        let aisleIntersections = corridorXPositions.flatMap { x in
            aisleYPositions.map { y in CGPoint(x: x, y: y) }
        }
        let roomCenters = rooms.map { CGPoint(x: $0.frame.midX, y: $0.frame.midY) }
        return Array(
            Set(
                aisleIntersections + roomCenters + [
                    waterCoolerStandPosition,
                    bookshelfStandPosition,
                    bulletinBoardStandPosition,
                    windowStandPosition,
                    whiteboardStandPosition,
                    loungePosition,
                    radioStandPosition,
                    printerStandPosition,
                    baristaCustomerPosition,
                    pizzaDropPosition,
                ]
            )
        )
    }

    public var wallClockPosition: CGPoint {
        CGPoint(x: 988, y: 700)
    }

    // MARK: - Pathfinding

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

    private var cellSize: CGFloat { 32 }

    private var gridWidth: Int {
        Int(ceil(sceneSize.width / cellSize))
    }

    private var gridHeight: Int {
        Int(ceil(sceneSize.height / cellSize))
    }

    func nearestWalkablePoint(to point: CGPoint) -> CGPoint {
        if isWalkablePoint(point) {
            return point
        }

        return centerOfCell(nearestWalkableCell(to: point))
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

    func isWalkablePoint(_ point: CGPoint, clearance: CGFloat = 6) -> Bool {
        guard walkableArea.insetBy(dx: clearance, dy: clearance).contains(point) else { return false }
        return !collisionObstacles.contains(where: { obstacle in
            obstacle.insetBy(dx: -clearance, dy: -clearance).contains(point)
        })
    }

    func canTravelDirectly(from start: CGPoint, to end: CGPoint, sampleStep: CGFloat = 8) -> Bool {
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
