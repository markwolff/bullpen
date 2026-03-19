import Foundation

public func classicBullpenRugs() -> [RugSpec] {
    [
        RugSpec(
            id: "gallery_runner",
            position: CGPoint(x: 868, y: 352),
            size: CGSize(width: 520, height: 92),
            cornerRadius: 18,
            colorSlot: .gallery
        ),
        RugSpec(
            id: "lounge_border",
            position: CGPoint(x: 280, y: 122),
            size: CGSize(width: 184, height: 88),
            cornerRadius: 18,
            colorSlot: .loungeBorder
        ),
        RugSpec(
            id: "lounge",
            position: CGPoint(x: 280, y: 122),
            size: CGSize(width: 170, height: 74),
            cornerRadius: 16,
            colorSlot: .lounge
        ),
        RugSpec(
            id: "focus",
            position: CGPoint(x: 220, y: 521),
            size: CGSize(width: 200, height: 60),
            cornerRadius: 14,
            colorSlot: .focus
        ),
        RugSpec(
            id: "build",
            position: CGPoint(x: 860, y: 170),
            size: CGSize(width: 280, height: 50),
            cornerRadius: 12,
            colorSlot: .build
        ),
        RugSpec(
            id: "collab",
            position: CGPoint(x: 830, y: 570),
            size: CGSize(width: 280, height: 50),
            cornerRadius: 12,
            colorSlot: .collab
        ),
    ]
}

public func classicBullpenDecorations() -> [DecorationSpec] {
    [
        DecorationSpec(id: "plant_0", textureName: TextureManager.decorationPlant,
                       position: CGPoint(x: 86, y: 714), size: CGSize(width: 48, height: 80)),
        DecorationSpec(id: "plant_1", textureName: TextureManager.decorationPlant,
                       position: CGPoint(x: 1152, y: 714), size: CGSize(width: 48, height: 80)),
        DecorationSpec(id: "plant_2", textureName: TextureManager.decorationPlant,
                       position: CGPoint(x: 92, y: 96), size: CGSize(width: 40, height: 68)),
        DecorationSpec(id: "plant_3", textureName: TextureManager.decorationPlant,
                       position: CGPoint(x: 1140, y: 96), size: CGSize(width: 40, height: 68)),
        DecorationSpec(id: "window", textureName: TextureManager.decorationWindow,
                       position: CGPoint(x: 246, y: 706), size: CGSize(width: 100, height: 80)),
        DecorationSpec(id: "window_2", textureName: TextureManager.decorationWindow,
                       position: CGPoint(x: 898, y: 706), size: CGSize(width: 100, height: 80)),
        DecorationSpec(id: "whiteboard", textureName: TextureManager.decorationWhiteboard,
                       position: CGPoint(x: 592, y: 396), size: CGSize(width: 120, height: 80)),
        DecorationSpec(id: "clock", textureName: TextureManager.decorationClock,
                       position: CGPoint(x: 988, y: 720), size: CGSize(width: 40, height: 40)),
        DecorationSpec(id: "poster", textureName: TextureManager.decorationPoster,
                       position: CGPoint(x: 306, y: 680), size: CGSize(width: 56, height: 72)),
        DecorationSpec(id: "bookshelf", textureName: TextureManager.decorationBookshelf,
                       position: CGPoint(x: 130, y: 710), size: CGSize(width: 80, height: 64)),
        DecorationSpec(id: "bulletin_board", textureName: TextureManager.decorationBulletinBoard,
                       position: CGPoint(x: 900, y: 420), size: CGSize(width: 80, height: 56)),
        DecorationSpec(id: "water_cooler", textureName: TextureManager.decorationWaterCooler,
                       position: CGPoint(x: 720, y: 348), size: CGSize(width: 40, height: 80)),
        DecorationSpec(id: "door", textureName: TextureManager.decorationDoor,
                       position: CGPoint(x: 1238, y: 352), size: CGSize(width: 56, height: 96)),
        DecorationSpec(id: "couch", textureName: TextureManager.decorationCouch,
                       position: CGPoint(x: 280, y: 140), size: CGSize(width: 60, height: 36)),
        DecorationSpec(id: "printer", textureName: TextureManager.decorationPrinter,
                       position: CGPoint(x: 580, y: 114), size: CGSize(width: 30, height: 30)),
        DecorationSpec(id: "collab_plant", textureName: TextureManager.decorationPlant,
                       position: CGPoint(x: 1170, y: 490), size: CGSize(width: 44, height: 72)),
        DecorationSpec(id: "lounge_shelf", textureName: TextureManager.decorationBookshelf,
                       position: CGPoint(x: 90, y: 220), size: CGSize(width: 56, height: 48)),
        DecorationSpec(id: "lounge_plant", textureName: TextureManager.decorationPlant,
                       position: CGPoint(x: 350, y: 220), size: CGSize(width: 32, height: 52)),
    ]
}

/// Returns all points of interest for the Classic Bullpen world.
///
/// Each POI maps to an existing idle-behavior location defined in
/// `OfficeLayout.defaultLayout`. The idle behavior system picks from
/// these when an agent finishes its task and goes exploring.
public func classicBullpenPOIs() -> [PointOfInterest] {
    [
        PointOfInterest(
            id: "water_cooler",
            category: .refreshment,
            standPosition: CGPoint(x: 700, y: 340),
            label: "Water cooler chat",
            emoji: "\u{1F4A7}",          // 💧
            animationHint: .interact
        ),
        PointOfInterest(
            id: "bookshelf",
            category: .reading,
            standPosition: CGPoint(x: 130, y: 674),
            label: "Browse bookshelf",
            emoji: "\u{1F4D6}",          // 📖
            animationHint: .faceUp
        ),
        PointOfInterest(
            id: "bulletin_board",
            category: .information,
            standPosition: CGPoint(x: 900, y: 386),
            label: "Check bulletin board",
            emoji: "\u{1F4CC}",          // 📌
            animationHint: .faceUp
        ),
        PointOfInterest(
            id: "window",
            category: .relaxation,
            standPosition: CGPoint(x: 904, y: 672),
            label: "Look out window",
            emoji: "\u{1FA9F}",          // 🪟
            animationHint: .faceUp
        ),
        PointOfInterest(
            id: "whiteboard",
            category: .creative,
            standPosition: CGPoint(x: 592, y: 352),
            label: "Whiteboard brainstorm",
            emoji: "\u{1F4A1}",          // 💡
            animationHint: .faceUp
        ),
        PointOfInterest(
            id: "plant_0",
            category: .nature,
            standPosition: CGPoint(x: 86, y: 674),
            label: "Water the plant",
            emoji: "\u{1F331}",          // 🌱
            animationHint: .interact
        ),
        PointOfInterest(
            id: "plant_1",
            category: .nature,
            standPosition: CGPoint(x: 1152, y: 674),
            label: "Water the plant",
            emoji: "\u{1F331}",          // 🌱
            animationHint: .interact
        ),
        PointOfInterest(
            id: "plant_2",
            category: .nature,
            standPosition: CGPoint(x: 92, y: 96),
            label: "Water the plant",
            emoji: "\u{1F331}",          // 🌱
            animationHint: .interact
        ),
        PointOfInterest(
            id: "plant_3",
            category: .nature,
            standPosition: CGPoint(x: 1140, y: 96),
            label: "Water the plant",
            emoji: "\u{1F331}",          // 🌱
            animationHint: .interact
        ),
        PointOfInterest(
            id: "coffee_station",
            category: .refreshment,
            standPosition: CGPoint(x: 1012, y: 324),
            label: "Get coffee",
            emoji: "\u{2615}",           // ☕
            animationHint: .interact
        ),
        PointOfInterest(
            id: "lounge_couch",
            category: .relaxation,
            standPosition: CGPoint(x: 280, y: 140),
            label: "Couch break",
            emoji: "\u{1F6CB}\u{FE0F}", // 🛋️
            animationHint: .sit
        ),
        PointOfInterest(
            id: "radio",
            category: .music,
            standPosition: CGPoint(x: 116, y: 218),
            label: "Listen to radio",
            emoji: "\u{1F4FB}",          // 📻
            animationHint: .dance
        ),
        PointOfInterest(
            id: "printer",
            category: .fidgeting,
            standPosition: CGPoint(x: 580, y: 110),
            label: "Use printer",
            emoji: "\u{1F5A8}\u{FE0F}", // 🖨️
            animationHint: .interact
        ),
        PointOfInterest(
            id: "ping_pong",
            category: .recreation,
            standPosition: CGPoint(x: 200, y: 280),
            label: "Ping pong break",
            emoji: "\u{1F3D3}",          // 🏓
            animationHint: .interact
        ),
    ]
}
