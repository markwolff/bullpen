import Foundation

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
