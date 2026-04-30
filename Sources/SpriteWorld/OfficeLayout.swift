import Foundation
import SpriteKit
import Models

/// Defines the layout of the office world: desk positions, rooms,
/// collision geometry, and pathfinding for agent sprites.
public struct OfficeLayout: Sendable {
    enum LivingOfficeStage: String, CaseIterable, Sendable {
        case seedling
        case scaling
        case bustling

        var tableCount: Int {
            switch self {
            case .seedling: return 2
            case .scaling:  return 4
            case .bustling: return 6
            }
        }
    }

    public enum DeskRenderStyle: Sendable, Equatable {
        case classicBench
        case zenChabudai
        case ruinsWorkbench
    }

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

    public let preset: WorldPreset
    public let sceneSize: CGSize
    public let desks: [DeskPosition]
    public let tables: [TableDefinition]
    public let rooms: [RoomDefinition]
    public let walkableArea: CGRect
    public let barriers: [Barrier]

    /// Pre-computed collision rectangles (barriers + desk tops). Avoids recomputing on every pathfinding call.
    public let collisionObstacles: [CGRect]

    /// Pre-computed desk-top obstacle rectangles.
    public let deskObstacles: [CGRect]

    /// Pre-computed furniture obstacle rectangles.
    public let furnitureObstacles: [CGRect]

    private let pathfinder: WorldPathfinder

    public init(
        preset: WorldPreset,
        sceneSize: CGSize,
        desks: [DeskPosition],
        tables: [TableDefinition],
        rooms: [RoomDefinition],
        walkableArea: CGRect,
        barriers: [Barrier]
    ) {
        self.preset = preset
        self.sceneSize = sceneSize
        self.desks = desks
        self.tables = tables
        self.rooms = rooms
        self.walkableArea = walkableArea
        self.barriers = barriers

        // Pre-compute obstacle arrays once
        let deskObstacles = tables.map { table in
            CGRect(x: table.leftX, y: table.centerY - 12, width: table.width, height: 24)
        }
        let furnitureObstacles = barriers.compactMap { barrier in
            barrier.kind == .furniture ? barrier.rect : nil
        }
        let collisionObstacles = barriers.map(\.rect) + deskObstacles

        self.deskObstacles = deskObstacles
        self.furnitureObstacles = furnitureObstacles
        self.collisionObstacles = collisionObstacles
        self.pathfinder = WorldPathfinder(
            sceneSize: sceneSize,
            walkableArea: walkableArea,
            collisionObstacles: collisionObstacles
        )
    }

    /// Creates a multi-room office with three desk rooms and a recreation lounge.
    /// Cached as a static let to avoid reconstructing on every access.
    public static let defaultLayout: OfficeLayout = {
        let sceneSize = CGSize(width: 1280, height: 768)

        let focusRoom = RoomDefinition(
            id: "focus_studio",
            name: "Focus Studio",
            frame: CGRect(x: 52, y: 370, width: 342, height: 346)
        )
        let loungeRoom = RoomDefinition(
            id: "recreation_lounge",
            name: "Recreation Lounge",
            frame: CGRect(x: 52, y: 52, width: 342, height: 314)
        )
        let spineRoom = RoomDefinition(
            id: "circulation_spine",
            name: "Circulation Spine",
            frame: CGRect(x: 398, y: 52, width: 160, height: 664)
        )
        let galleryRoom = RoomDefinition(
            id: "gallery",
            name: "Gallery",
            frame: CGRect(x: 562, y: 268, width: 666, height: 168)
        )
        let collaborationRoom = RoomDefinition(
            id: "collaboration_room",
            name: "Collaboration Room",
            frame: CGRect(x: 562, y: 436, width: 666, height: 280)
        )
        let buildRoom = RoomDefinition(
            id: "build_room",
            name: "Build Room",
            frame: CGRect(x: 562, y: 52, width: 666, height: 212)
        )

        let tableDefinitions = [
            TableDefinition(id: 0, centerY: 576, seatXPositions: [140, 220, 300]),              // Focus Studio, 3 seats
            TableDefinition(id: 1, centerY: 466, seatXPositions: [140, 220, 300]),              // Focus Studio, 3 seats
            TableDefinition(id: 2, centerY: 618, seatXPositions: [650, 740, 830, 920, 1010]),   // Collaboration, 5 seats
            TableDefinition(id: 3, centerY: 520, seatXPositions: [650, 740, 830, 920, 1010]),   // Collaboration, 5 seats
            TableDefinition(id: 4, centerY: 204, seatXPositions: [620, 720, 820, 920, 1020, 1120]), // Build Room, 6 seats
            TableDefinition(id: 5, centerY: 135, seatXPositions: [620, 720, 820, 920, 1020, 1120]), // Build Room, 6 seats
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
            Barrier(id: "focus_glass_upper", kind: .glassWall, rect: CGRect(x: 394, y: 370, width: 8, height: 120)),
            Barrier(id: "focus_glass_lower", kind: .glassWall, rect: CGRect(x: 394, y: 558, width: 8, height: 158)),
            Barrier(id: "lounge_wall_lower", kind: .solidWall, rect: CGRect(x: 394, y: 52, width: 8, height: 86)),
            Barrier(id: "lounge_wall_upper", kind: .solidWall, rect: CGRect(x: 394, y: 180, width: 8, height: 186)),
            Barrier(id: "entry_wall_lower", kind: .solidWall, rect: CGRect(x: 1232, y: 40, width: 8, height: 264)),
            Barrier(id: "entry_wall_upper", kind: .solidWall, rect: CGRect(x: 1232, y: 400, width: 8, height: 328)),
            Barrier(id: "build_glass_left", kind: .glassWall, rect: CGRect(x: 562, y: 264, width: 110, height: 8)),
            Barrier(id: "build_glass_right", kind: .glassWall, rect: CGRect(x: 752, y: 264, width: 476, height: 8)),
            Barrier(id: "collab_glass_left", kind: .glassWall, rect: CGRect(x: 562, y: 436, width: 110, height: 8)),
            Barrier(id: "collab_glass_right", kind: .glassWall, rect: CGRect(x: 752, y: 436, width: 476, height: 8)),
            Barrier(id: "coffee_bar", kind: .furniture, rect: CGRect(x: 1052, y: 300, width: 110, height: 44)),
            Barrier(id: "water_cooler", kind: .furniture, rect: CGRect(x: 680, y: 304, width: 40, height: 72)),
            Barrier(id: "printer", kind: .furniture, rect: CGRect(x: 564, y: 96, width: 36, height: 36)),
            Barrier(id: "ping_pong", kind: .furniture, rect: CGRect(x: 138, y: 248, width: 124, height: 60)),
        ]

        return OfficeLayout(
            preset: .classicBullpen,
            sceneSize: sceneSize,
            desks: desks,
            tables: tableDefinitions,
            rooms: [focusRoom, loungeRoom, spineRoom, galleryRoom, collaborationRoom, buildRoom],
            walkableArea: CGRect(x: 40, y: 40, width: 1200, height: 688),
            barriers: barriers
        )
    }()

    /// Returns the layout for a given world preset.
    public static func layout(for preset: WorldPreset) -> OfficeLayout {
        layout(for: preset, agentCount: 0)
    }

    /// Returns the layout for a given world preset and population.
    public static func layout(for preset: WorldPreset, agentCount: Int) -> OfficeLayout {
        switch preset {
        case .classicBullpen: return .defaultLayout
        case .zenStudio:      return .zenStudio
        case .overgrownRuins: return .overgrownRuins
        case .livingOffice:   return livingOfficeLayout(forAgentCount: agentCount)
        }
    }

    /// Returns the points of interest for a given world preset.
    public static func pointsOfInterest(for preset: WorldPreset) -> [PointOfInterest] {
        switch preset {
        case .classicBullpen: return classicBullpenPOIs()
        case .zenStudio:      return ZenStudioLayout.zenStudioPOIs()
        case .overgrownRuins: return overgrownRuinsPOIs()
        case .livingOffice:   return classicBullpenPOIs()
        }
    }

    static func livingOfficeStage(forAgentCount agentCount: Int) -> LivingOfficeStage {
        switch max(agentCount, 0) {
        case 0...4:
            return .seedling
        case 5...11:
            return .scaling
        default:
            return .bustling
        }
    }

    private static func livingOfficeLayout(forAgentCount agentCount: Int) -> OfficeLayout {
        let stage = livingOfficeStage(forAgentCount: agentCount)
        let base = OfficeLayout.defaultLayout
        let tables = Array(base.tables.prefix(stage.tableCount))
        let deskCount = tables.reduce(into: 0) { partialResult, table in
            partialResult += table.seatXPositions.count
        }

        return OfficeLayout(
            preset: .classicBullpen,
            sceneSize: base.sceneSize,
            desks: Array(base.desks.prefix(deskCount)),
            tables: tables,
            rooms: base.rooms,
            walkableArea: base.walkableArea,
            barriers: base.barriers
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

    // collisionObstacles, deskObstacles, and furnitureObstacles are now stored properties (see init)

    // MARK: - Aisles

    public var aisleYPositions: [CGFloat] {
        [642, 522, 352, 190, 104]
    }

    public var corridorXPositions: [CGFloat] {
        [162, 474, 718, 1036, 1186]
    }

    // MARK: - Door Position

    public var deskRenderStyle: DeskRenderStyle {
        switch preset {
        case .classicBullpen, .livingOffice:
            return .classicBench
        case .zenStudio:
            return .zenChabudai
        case .overgrownRuins:
            return .ruinsWorkbench
        }
    }

    public var rugs: [RugSpec] {
        switch preset {
        case .classicBullpen, .livingOffice:
            return classicBullpenRugs()
        case .zenStudio:
            return ZenStudioLayout.shared.rugs
        case .overgrownRuins:
            return overgrownRuinsRugs()
        }
    }

    public var decorations: [DecorationSpec] {
        switch preset {
        case .classicBullpen, .livingOffice:
            return classicBullpenDecorations()
        case .zenStudio:
            return ZenStudioLayout.shared.decorations
        case .overgrownRuins:
            return overgrownRuinsDecorations()
        }
    }

    public var doorPosition: CGPoint {
        CGPoint(x: 1238, y: 352)
    }

    public var doorExitPosition: CGPoint {
        CGPoint(x: 1186, y: 352)
    }

    // MARK: - Points of Interest

    public var waterCoolerStandPosition: CGPoint {
        switch preset {
        case .classicBullpen, .livingOffice:
            return CGPoint(x: 700, y: 340)
        case .zenStudio:
            return CGPoint(x: 460, y: 560)
        case .overgrownRuins:
            return CGPoint(x: 350, y: 550)
        }
    }

    public var bookshelfStandPosition: CGPoint {
        switch preset {
        case .classicBullpen, .livingOffice:
            return CGPoint(x: 130, y: 674)
        case .zenStudio:
            return CGPoint(x: 1040, y: 176)
        case .overgrownRuins:
            return CGPoint(x: 140, y: 290)
        }
    }

    public var bulletinBoardStandPosition: CGPoint {
        switch preset {
        case .classicBullpen, .livingOffice:
            return CGPoint(x: 900, y: 386)
        case .zenStudio:
            return CGPoint(x: 80, y: 290)
        case .overgrownRuins:
            return CGPoint(x: 1080, y: 340)
        }
    }

    public var windowStandPosition: CGPoint {
        switch preset {
        case .classicBullpen, .livingOffice:
            return CGPoint(x: 904, y: 672)
        case .zenStudio:
            return CGPoint(x: 478, y: 660)
        case .overgrownRuins:
            return CGPoint(x: 900, y: 620)
        }
    }

    public var whiteboardStandPosition: CGPoint {
        switch preset {
        case .classicBullpen, .livingOffice:
            return CGPoint(x: 592, y: 352)
        case .zenStudio:
            return CGPoint(x: 600, y: 356)
        case .overgrownRuins:
            return CGPoint(x: 1080, y: 340)
        }
    }

    public var plantStandPositions: [CGPoint] {
        switch preset {
        case .classicBullpen, .livingOffice:
            return [
                CGPoint(x: 86, y: 674),
                CGPoint(x: 1152, y: 674),
                CGPoint(x: 92, y: 96),
                CGPoint(x: 1140, y: 96),
            ]
        case .zenStudio:
            return [
                CGPoint(x: 86, y: 680),
                CGPoint(x: 360, y: 680),
                CGPoint(x: 420, y: 690),
                CGPoint(x: 530, y: 690),
            ]
        case .overgrownRuins:
            return [
                CGPoint(x: 200, y: 580),
                CGPoint(x: 481, y: 280),
                CGPoint(x: 780, y: 680),
                CGPoint(x: 350, y: 550),
            ]
        }
    }

    public var loungePosition: CGPoint {
        switch preset {
        case .classicBullpen, .livingOffice:
            return CGPoint(x: 280, y: 140)
        case .zenStudio:
            return CGPoint(x: 478, y: 160)
        case .overgrownRuins:
            return CGPoint(x: 900, y: 600)
        }
    }

    public var dogBowlPosition: CGPoint {
        switch preset {
        case .classicBullpen, .livingOffice:
            return CGPoint(x: 160, y: 100)
        case .zenStudio:
            return CGPoint(x: 250, y: 88)
        case .overgrownRuins:
            return CGPoint(x: 230, y: 96)
        }
    }

    public var dogSleepPosition: CGPoint {
        switch preset {
        case .classicBullpen, .livingOffice:
            return CGPoint(x: 200, y: 90)
        case .zenStudio:
            return CGPoint(x: 300, y: 80)
        case .overgrownRuins:
            return CGPoint(x: 280, y: 88)
        }
    }

    public var dogToyPositions: [CGPoint] {
        switch preset {
        case .classicBullpen, .livingOffice:
            return [
                CGPoint(x: 120, y: 80),
                CGPoint(x: 170, y: 100),
                CGPoint(x: 220, y: 80),
            ]
        case .zenStudio:
            return [
                CGPoint(x: 210, y: 88),
                CGPoint(x: 265, y: 110),
                CGPoint(x: 320, y: 92),
            ]
        case .overgrownRuins:
            return [
                CGPoint(x: 200, y: 84),
                CGPoint(x: 250, y: 110),
                CGPoint(x: 305, y: 88),
            ]
        }
    }

    public var radioStandPosition: CGPoint {
        switch preset {
        case .classicBullpen, .livingOffice:
            return CGPoint(x: 116, y: 218)
        case .zenStudio:
            return CGPoint(x: 430, y: 230)
        case .overgrownRuins:
            return CGPoint(x: 620, y: 330)
        }
    }

    public var printerStandPosition: CGPoint {
        switch preset {
        case .classicBullpen, .livingOffice:
            return CGPoint(x: 580, y: 110)
        case .zenStudio:
            return CGPoint(x: 1190, y: 94)
        case .overgrownRuins:
            return CGPoint(x: 1040, y: 112)
        }
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
        switch preset {
        case .classicBullpen, .livingOffice:
            return CGPoint(x: 868, y: 352)
        case .zenStudio:
            return CGPoint(x: 895, y: 574)
        case .overgrownRuins:
            return CGPoint(x: 900, y: 530)
        }
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
        switch preset {
        case .classicBullpen, .livingOffice:
            return CGPoint(x: 1060, y: 680)
        case .zenStudio:
            return CGPoint(x: 1192, y: 376)
        case .overgrownRuins:
            return CGPoint(x: 1168, y: 388)
        }
    }

    public var radioPosition: CGPoint {
        radioStandPosition
    }

    public var birdCagePosition: CGPoint {
        switch preset {
        case .classicBullpen, .livingOffice:
            return CGPoint(x: 1172, y: 690)
        case .zenStudio:
            return CGPoint(x: 1188, y: 700)
        case .overgrownRuins:
            return CGPoint(x: 782, y: 684)
        }
    }

    public var coffeeStationPosition: CGPoint {
        switch preset {
        case .classicBullpen, .livingOffice:
            return CGPoint(x: 1060, y: 324)
        case .zenStudio:
            return CGPoint(x: 240, y: 258)
        case .overgrownRuins:
            return CGPoint(x: 812, y: 560)
        }
    }

    public var baristaPosition: CGPoint {
        switch preset {
        case .classicBullpen, .livingOffice:
            return CGPoint(x: 1108, y: 324)
        case .zenStudio:
            return CGPoint(x: 286, y: 258)
        case .overgrownRuins:
            return CGPoint(x: 860, y: 560)
        }
    }

    public var baristaCustomerPosition: CGPoint {
        switch preset {
        case .classicBullpen, .livingOffice:
            return CGPoint(x: 1012, y: 324)
        case .zenStudio:
            return CGPoint(x: 196, y: 258)
        case .overgrownRuins:
            return CGPoint(x: 764, y: 560)
        }
    }

    public var coffeeRugPosition: CGPoint {
        switch preset {
        case .classicBullpen, .livingOffice:
            return CGPoint(x: 1060, y: 304)
        case .zenStudio:
            return CGPoint(x: 240, y: 240)
        case .overgrownRuins:
            return CGPoint(x: 812, y: 542)
        }
    }

    public var catStartPosition: CGPoint {
        switch preset {
        case .classicBullpen, .livingOffice:
            return CGPoint(x: 80, y: 100)
        case .zenStudio:
            return CGPoint(x: 280, y: 500)
        case .overgrownRuins:
            return CGPoint(x: 440, y: 360)
        }
    }

    public var growingPlantPosition: CGPoint {
        switch preset {
        case .classicBullpen, .livingOffice:
            return CGPoint(x: 760, y: coffeeStationPosition.y - 8)
        case .zenStudio:
            return CGPoint(x: 332, y: 248)
        case .overgrownRuins:
            return CGPoint(x: 720, y: 548)
        }
    }

    public var spaciousPacingPositions: [CGPoint] {
        let anchors = [
            CGPoint(x: corridorXPositions[1], y: aisleYPositions[2]),
            CGPoint(x: corridorXPositions[2], y: aisleYPositions[2]),
            CGPoint(x: corridorXPositions[3], y: aisleYPositions[2]),
            CGPoint(x: corridorXPositions[1], y: aisleYPositions[1]),
            CGPoint(x: corridorXPositions[2], y: aisleYPositions[3]),
            loungePosition,
            windowStandPosition,
            whiteboardStandPosition,
            CGPoint(x: rooms[0].frame.midX, y: rooms[0].frame.midY),
            CGPoint(x: rooms.last?.frame.midX ?? 0, y: rooms.last?.frame.midY ?? 0),
        ]
        return curatedAnchors(from: anchors)
    }

    public var deepThinkingPositions: [CGPoint] {
        let anchors = [
            windowStandPosition,
            whiteboardStandPosition,
            plantStandPositions.first ?? windowStandPosition,
            plantStandPositions.last ?? whiteboardStandPosition,
            CGPoint(x: corridorXPositions[1], y: aisleYPositions[1]),
            CGPoint(x: corridorXPositions[2], y: aisleYPositions[3]),
            CGPoint(x: rooms[0].frame.midX, y: rooms[0].frame.midY),
        ]
        return curatedAnchors(from: anchors)
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
        switch preset {
        case .classicBullpen, .livingOffice:
            return CGPoint(x: 988, y: 720)
        case .zenStudio:
            return CGPoint(x: 1092, y: 704)
        case .overgrownRuins:
            return CGPoint(x: 1096, y: 700)
        }
    }

    // MARK: - Pathfinding

    public func findPath(from start: CGPoint, to end: CGPoint) -> [CGPoint] {
        pathfinder.findPath(from: start, to: end)
    }

    func nearestWalkablePoint(to point: CGPoint) -> CGPoint {
        pathfinder.nearestWalkablePoint(to: point)
    }

    func isWalkablePoint(_ point: CGPoint, clearance: CGFloat = 12) -> Bool {
        pathfinder.isWalkablePoint(point, clearance: clearance)
    }

    func canTravelDirectly(from start: CGPoint, to end: CGPoint, sampleStep: CGFloat = 12) -> Bool {
        pathfinder.canTravelDirectly(from: start, to: end, sampleStep: sampleStep)
    }

    private func curatedAnchors(from points: [CGPoint]) -> [CGPoint] {
        var seen: Set<CGPoint> = []
        var resolved: [CGPoint] = []

        for point in points {
            let walkable = nearestWalkablePoint(to: point)
            if seen.insert(walkable).inserted {
                resolved.append(walkable)
            }
        }

        return resolved
    }
}
