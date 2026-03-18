import Foundation

// MARK: - POIAnimationHint

/// Tells AgentSprite what posture/animation to use at a POI.
///
/// The sprite maps these to existing frame sets — no per-POI code needed.
/// New worlds add new POIs without touching AgentSprite.
public enum POIAnimationHint: String, Sendable, Codable {
    case stand       // Default: agent stands facing the POI
    case sit         // Agent sits (couch, bench, cushion)
    case inspect     // Agent looks up/around (bookshelf, poster, window, koi pond)
    case interact    // Agent reaches forward (water cooler, plant, printer)
    case kneel       // Agent crouches (pet cat/dog, garden)
    case pace        // Agent paces in a small area (whiteboard brainstorm)
}

// MARK: - PointOfInterest

/// A location in the world where an idle agent can spend time.
///
/// Created by each world layout and fed to the idle behavior system.
/// The idle manager knows nothing about specific furniture — just categories.
public struct PointOfInterest: Sendable, Identifiable {
    public let id: String
    public let category: POICategory
    public let label: String             // Thought bubble text: "Getting water"
    public let emoji: String             // Action bubble emoji: "💧"
    public let position: CGPoint
    public let capacity: Int             // Max simultaneous agents (default 2)
    public let animationHint: POIAnimationHint

    public init(
        id: String,
        category: POICategory,
        label: String,
        emoji: String,
        position: CGPoint,
        capacity: Int = 2,
        animationHint: POIAnimationHint = .stand
    ) {
        self.id = id
        self.category = category
        self.label = label
        self.emoji = emoji
        self.position = position
        self.capacity = capacity
        self.animationHint = animationHint
    }
}

// MARK: - DecorationSpec

/// Tells the scene builder what decoration to place and where.
///
/// Each world layout provides an array of these. The scene builder
/// iterates them and creates SKSpriteNodes — no hardcoded decoration
/// placement in OfficeScene.
public struct DecorationSpec: Sendable {
    public let textureName: String
    public let position: CGPoint
    public let size: CGSize
    public let zPosition: CGFloat
    public let name: String?             // Optional node name for lookup

    public init(
        textureName: String,
        position: CGPoint,
        size: CGSize,
        zPosition: CGFloat = 2,
        name: String? = nil
    ) {
        self.textureName = textureName
        self.position = position
        self.size = size
        self.zPosition = zPosition
        self.name = name
    }
}
