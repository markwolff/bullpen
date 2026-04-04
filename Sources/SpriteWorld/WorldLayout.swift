import Foundation
import CoreGraphics

// MARK: - WorldLayout Protocol

/// Defines the spatial layout for a world: rooms, desks, barriers, points of interest,
/// decorations, and pathfinding. Each world provides its own unique geometry.
///
/// The scene builder queries a `WorldLayout` to know what to build and where.
/// Pathfinding and collision are derived from the layout's barriers and walkable area.
public protocol WorldLayout: Sendable {

    /// The scene size in points.
    var sceneSize: CGSize { get }

    /// The rectangular region agents can walk within.
    var walkableArea: CGRect { get }

    // MARK: - Rooms

    /// Room definitions (visual panels with labels).
    var rooms: [RoomDefinition] { get }

    // MARK: - Desks

    /// All desk positions where agents can sit and work.
    var desks: [DeskPosition] { get }

    /// Table surfaces that desks sit at. Used for rendering table sprites
    /// and computing desk-top collision rectangles.
    var tables: [TableDefinition] { get }

    // MARK: - Barriers

    /// Collision barriers (walls, glass partitions, furniture footprints).
    var barriers: [Barrier] { get }

    // MARK: - Points of Interest

    /// All points of interest in the world. Idle behaviors pick from these
    /// by category rather than by name, so any world can define its own set.
    var pointsOfInterest: [PointOfInterest] { get }

    // MARK: - Decorations

    /// Specifications for all decorations to place in the world.
    /// The scene builder iterates these and creates sprite nodes accordingly.
    var decorations: [DecorationSpec] { get }

    // MARK: - Rug Specs

    /// Area rugs to render under furniture. Separated from decorations because
    /// rugs use shape nodes with theme colors rather than pixel-art textures.
    var rugs: [RugSpec] { get }

    // MARK: - Navigation

    /// The position where agents enter and exit the scene (the door).
    var doorPosition: CGPoint { get }

    /// The position just inside the door where agents stand after entering
    /// (or walk to before exiting). Slightly offset from `doorPosition`.
    var doorExitPosition: CGPoint { get }

    /// Y positions of horizontal aisles for deskless pacing navigation.
    var aisleYPositions: [CGFloat] { get }

    /// X positions of vertical corridors for deskless pacing navigation.
    var corridorXPositions: [CGFloat] { get }

    // MARK: - Pets

    /// Where the dog bowl is placed. Nil if this world has no dog.
    var dogBowlPosition: CGPoint? { get }

    /// Where the dog sleeps. Nil if this world has no dog.
    var dogSleepPosition: CGPoint? { get }

    /// Positions where dog toys are scattered. Empty if no dog.
    var dogToyPositions: [CGPoint] { get }

    /// Initial position for the office cat. Nil if this world has no cat.
    var catStartPosition: CGPoint? { get }
}

// MARK: - WorldLayout Default Implementations

extension WorldLayout {

    /// Computed from barriers: all glass partition barriers.
    public var glassPartitions: [Barrier] {
        barriers.filter { $0.kind == .glassWall }
    }

    /// Computed from barriers: all solid wall barriers.
    public var solidPartitions: [Barrier] {
        barriers.filter { $0.kind == .solidWall }
    }

    /// Pre-computed desk-top obstacle rectangles derived from table definitions.
    public var deskObstacles: [CGRect] {
        tables.map { table in
            CGRect(x: table.leftX, y: table.centerY - 12, width: table.width, height: 24)
        }
    }

    /// Pre-computed furniture obstacle rectangles.
    public var furnitureObstacles: [CGRect] {
        barriers.compactMap { $0.kind == .furniture ? $0.rect : nil }
    }

    /// All collision rectangles (barriers + desk tops) for pathfinding.
    public var collisionObstacles: [CGRect] {
        barriers.map(\.rect) + deskObstacles
    }

    /// Finds a random unoccupied desk.
    public func nextAvailableDesk(occupiedDeskIDs: Set<Int>) -> DeskPosition? {
        desks.filter { !occupiedDeskIDs.contains($0.id) }.randomElement()
    }

    /// All POIs matching a given category.
    public func pointsOfInterest(for category: POICategory) -> [PointOfInterest] {
        pointsOfInterest.filter { $0.category == category }
    }

    /// A single random POI for a category, or nil if none exist.
    public func randomPointOfInterest(for category: POICategory) -> PointOfInterest? {
        pointsOfInterest(for: category).randomElement()
    }

    /// Positions suitable for deskless pacing — aisle intersections, room centers, and POI stand positions.
    public var desklessPacingPositions: [CGPoint] {
        let aisleIntersections = corridorXPositions.flatMap { x in
            aisleYPositions.map { y in CGPoint(x: x, y: y) }
        }
        let roomCenters = rooms.map { CGPoint(x: $0.frame.midX, y: $0.frame.midY) }
        let poiPositions = pointsOfInterest.map(\.standPosition)
        return Array(Set(aisleIntersections + roomCenters + poiPositions))
    }

    /// Roomier pacing anchors used for calmer active wandering.
    public var spaciousPacingPositions: [CGPoint] {
        let aisleIntersections = corridorXPositions.flatMap { x in
            aisleYPositions.map { y in CGPoint(x: x, y: y) }
        }
        let roomCenters = rooms.map { CGPoint(x: $0.frame.midX, y: $0.frame.midY) }
        let reflectivePOIs = pointsOfInterest
            .filter { [.relaxation, .nature, .creative, .reading].contains($0.category) }
            .map(\.standPosition)
        return Array(Set(aisleIntersections + roomCenters + reflectivePOIs))
    }

    /// Reflective anchors used for slower deep-thinking pacing.
    public var deepThinkingPositions: [CGPoint] {
        let roomCenters = rooms.map { CGPoint(x: $0.frame.midX, y: $0.frame.midY) }
        let reflectivePOIs = pointsOfInterest
            .filter { [.relaxation, .nature, .creative, .reading].contains($0.category) }
            .map(\.standPosition)
        return Array(Set(roomCenters + reflectivePOIs))
    }

    // MARK: - Default Pet Positions (no pets)

    public var dogBowlPosition: CGPoint? { nil }
    public var dogSleepPosition: CGPoint? { nil }
    public var dogToyPositions: [CGPoint] { [] }
    public var catStartPosition: CGPoint? { nil }
}

// MARK: - POICategory

/// Categories for points of interest. Idle behaviors select by category,
/// making them world-agnostic — any world can provide its own POIs
/// as long as they use these standard categories.
public enum POICategory: String, CaseIterable, Sendable, Hashable {

    /// Hydration or food — water cooler, coffee machine, vending machine, tea station
    case refreshment

    /// Relaxation — couch, hammock, beanbag, lounge chair, window seat
    case relaxation

    /// Social gathering spot — water cooler chat area, break room table, huddle zone
    case social

    /// Reading or study — bookshelf, magazine rack, reading nook, library corner
    case reading

    /// Creative expression — whiteboard, art wall, idea board, sketch pad station
    case creative

    /// Nature or greenery — potted plant, garden, terrarium, window with a view
    case nature

    /// Fidgeting or restlessness — printer area, supply closet, filing cabinet
    case fidgeting

    /// Music or audio — radio, jukebox, record player, speaker corner
    case music

    /// Pets and animals — cat petting spot, dog play area, bird cage, fish tank
    case pets

    /// Games or recreation — ping pong, foosball, arcade machine, board game table
    case recreation

    /// Information display — bulletin board, status board, announcement wall
    case information
}

// MARK: - PointOfInterest

/// A named location in the world where agents can perform idle activities.
public struct PointOfInterest: Sendable, Identifiable, Hashable {

    public let id: String

    /// The category of activity at this location.
    public let category: POICategory

    /// Where the agent stands when interacting with this POI.
    public let standPosition: CGPoint

    /// Human-readable label shown in the agent's thought/action bubble.
    /// e.g., "Getting water", "Browsing books", "Checking board"
    public let label: String

    /// Emoji shown in the action bubble while the agent performs this activity.
    public let emoji: String

    /// Optional hint for the agent's animation while at this POI.
    /// Nil means the agent uses a default idle stance.
    public let animationHint: AnimationHint?

    public init(
        id: String,
        category: POICategory,
        standPosition: CGPoint,
        label: String,
        emoji: String,
        animationHint: AnimationHint? = nil
    ) {
        self.id = id
        self.category = category
        self.standPosition = standPosition
        self.label = label
        self.emoji = emoji
        self.animationHint = animationHint
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: PointOfInterest, rhs: PointOfInterest) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - AnimationHint

/// Hints for how the agent should animate while at a POI.
public enum AnimationHint: String, Sendable {
    /// Agent faces the POI (e.g., looking at a bookshelf or whiteboard)
    case faceUp
    /// Agent faces away from the POI (e.g., sitting on a couch facing the room)
    case faceDown
    /// Agent faces left
    case faceLeft
    /// Agent faces right
    case faceRight
    /// Agent performs a reaching/interacting gesture (e.g., watering a plant, using printer)
    case interact
    /// Agent sits down (e.g., lounge couch, chair)
    case sit
    /// Agent bobs/dances (e.g., near radio/jukebox)
    case dance
}

// MARK: - DecorationSpec

/// Specification for a decoration to place in the world.
/// The scene builder creates an `SKSpriteNode` from this spec.
public struct DecorationSpec: Sendable, Identifiable {

    public let id: String

    /// The `TextureManager` constant name for this decoration's texture.
    /// e.g., `TextureManager.decorationPlant`, `TextureManager.decorationClock`
    public let textureName: String

    /// Where to place the decoration in scene coordinates.
    public let position: CGPoint

    /// Display size in points (the texture will be scaled to fit).
    public let size: CGSize

    /// Z-ordering layer. Defaults to 2 (standard decoration layer).
    public let zPosition: CGFloat

    public init(
        id: String,
        textureName: String,
        position: CGPoint,
        size: CGSize,
        zPosition: CGFloat = 2
    ) {
        self.id = id
        self.textureName = textureName
        self.position = position
        self.size = size
        self.zPosition = zPosition
    }
}

// MARK: - RugSpec

/// Specification for an area rug rendered as a rounded-rect shape node.
/// Rugs use theme colors, so they only define geometry here.
public struct RugSpec: Sendable, Identifiable {

    public let id: String

    /// Center position of the rug in scene coordinates.
    public let position: CGPoint

    /// Size of the rug.
    public let size: CGSize

    /// Corner radius for the rounded rectangle.
    public let cornerRadius: CGFloat

    /// Which theme color slot this rug uses (mapped by the theme).
    public let colorSlot: RugColorSlot

    public init(
        id: String,
        position: CGPoint,
        size: CGSize,
        cornerRadius: CGFloat = 16,
        colorSlot: RugColorSlot
    ) {
        self.id = id
        self.position = position
        self.size = size
        self.cornerRadius = cornerRadius
        self.colorSlot = colorSlot
    }
}

// MARK: - RugColorSlot

/// Named color slots that the theme maps to actual colors.
/// Worlds reference these slots; themes provide the actual palette.
public enum RugColorSlot: String, Sendable {
    case gallery
    case lounge
    case loungeBorder
    case focus
    case build
    case collab
    case coffee
    case custom1
    case custom2
    case custom3
}

// MARK: - Shared Spatial Types
//
// DeskPosition, TableDefinition, RoomDefinition, and Barrier are currently
// nested inside OfficeLayout. During migration they will be promoted to
// top-level types here so all WorldLayout conformances can share them.
// For now, the protocol references the existing nested types via typealiases.

/// Convenience typealiases bridging to the existing nested types in OfficeLayout.
/// These will become unnecessary once the types are promoted to top-level.
public typealias DeskPosition = OfficeLayout.DeskPosition
public typealias TableDefinition = OfficeLayout.TableDefinition
public typealias RoomDefinition = OfficeLayout.RoomDefinition
public typealias Barrier = OfficeLayout.Barrier
