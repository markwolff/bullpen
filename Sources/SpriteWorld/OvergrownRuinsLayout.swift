import Foundation
import SpriteKit

// MARK: - Overgrown Ruins Layout

/// A derelict research facility where nature is winning.
///
/// L-shaped structure with a massive tree growing through the center
/// where corridors meet. Server room still hums with power but vines
/// snake through racks. Some areas lit by flickering fluorescents,
/// others by bioluminescent mushrooms and sunbeams through broken ceiling.
extension OfficeLayout {

    /// Cached layout for the Overgrown Ruins world.
    public static let overgrownRuins: OfficeLayout = {
        let sceneSize = CGSize(width: 1280, height: 768)

        // MARK: Rooms

        let greenhouseBreach = RoomDefinition(
            id: "greenhouse_breach",
            name: "Greenhouse Breach",
            frame: CGRect(x: 52, y: 370, width: 350, height: 346)
        )
        let collapsedWing = RoomDefinition(
            id: "collapsed_wing",
            name: "Collapsed Wing",
            frame: CGRect(x: 52, y: 52, width: 350, height: 314)
        )
        let treeAtrium = RoomDefinition(
            id: "tree_atrium",
            name: "The Big Tree",
            frame: CGRect(x: 406, y: 200, width: 150, height: 516)
        )
        let mushroomGrove = RoomDefinition(
            id: "mushroom_grove",
            name: "Mushroom Grove",
            frame: CGRect(x: 406, y: 52, width: 150, height: 144)
        )
        let rooftopOpening = RoomDefinition(
            id: "rooftop_opening",
            name: "Rooftop Opening",
            frame: CGRect(x: 560, y: 436, width: 668, height: 280)
        )
        let serverRoom = RoomDefinition(
            id: "server_room",
            name: "Server Room",
            frame: CGRect(x: 560, y: 52, width: 668, height: 380)
        )

        // MARK: Tables & Desks

        let tableDefinitions = [
            // Table 0: Collapsed Wing upper row
            TableDefinition(id: 0, centerY: 170, seatXPositions: [140, 230, 320]),
            // Table 1: Collapsed Wing lower row
            TableDefinition(id: 1, centerY: 100, seatXPositions: [140, 230, 320]),
            // Table 2: Server Room upper row
            TableDefinition(id: 2, centerY: 200, seatXPositions: [640, 740, 840, 940, 1040]),
            // Table 3: Server Room lower row
            TableDefinition(id: 3, centerY: 116, seatXPositions: [640, 740, 840, 940, 1040]),
            // Table 4: Rooftop Opening upper row
            TableDefinition(id: 4, centerY: 624, seatXPositions: [640, 740, 840, 940, 1040, 1140]),
            // Table 5: Rooftop Opening lower row
            TableDefinition(id: 5, centerY: 530, seatXPositions: [640, 740, 840, 940, 1040, 1140]),
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

        // MARK: Barriers

        let barriers = [
            // Cracked exterior walls
            Barrier(id: "ruins_wall_west", kind: .solidWall,
                    rect: CGRect(x: 48, y: 52, width: 8, height: 664)),
            Barrier(id: "ruins_wall_south", kind: .solidWall,
                    rect: CGRect(x: 48, y: 48, width: 1184, height: 8)),
            Barrier(id: "ruins_wall_north_left", kind: .solidWall,
                    rect: CGRect(x: 48, y: 712, width: 508, height: 8)),
            Barrier(id: "ruins_wall_north_right", kind: .solidWall,
                    rect: CGRect(x: 556, y: 712, width: 676, height: 8)),

            // Broken glass partitions between rooms
            Barrier(id: "glass_greenhouse_atrium", kind: .glassWall,
                    rect: CGRect(x: 402, y: 500, width: 8, height: 216)),
            Barrier(id: "glass_collapsed_atrium", kind: .glassWall,
                    rect: CGRect(x: 402, y: 52, width: 8, height: 144)),
            Barrier(id: "glass_server_rooftop", kind: .glassWall,
                    rect: CGRect(x: 560, y: 432, width: 250, height: 8)),
            Barrier(id: "glass_server_rooftop_right", kind: .glassWall,
                    rect: CGRect(x: 890, y: 432, width: 338, height: 8)),

            // Tree trunk — large non-walkable central obstacle
            Barrier(id: "tree_trunk", kind: .furniture,
                    rect: CGRect(x: 446, y: 380, width: 70, height: 120)),

            // Rubble pile in collapsed wing
            Barrier(id: "rubble_pile", kind: .furniture,
                    rect: CGRect(x: 100, y: 240, width: 80, height: 40)),

            // Server rack barriers (vine-covered but still bulky)
            Barrier(id: "server_rack_left", kind: .furniture,
                    rect: CGRect(x: 580, y: 300, width: 40, height: 80)),
            Barrier(id: "server_rack_right", kind: .furniture,
                    rect: CGRect(x: 1160, y: 80, width: 40, height: 100)),

            // Puddle — non-walkable wet area
            Barrier(id: "puddle_large", kind: .furniture,
                    rect: CGRect(x: 160, y: 470, width: 64, height: 24)),
        ]

        return OfficeLayout(
            sceneSize: sceneSize,
            desks: desks,
            tables: tableDefinitions,
            rooms: [greenhouseBreach, collapsedWing, treeAtrium,
                    mushroomGrove, rooftopOpening, serverRoom],
            walkableArea: CGRect(x: 40, y: 40, width: 1200, height: 688),
            barriers: barriers
        )
    }()
}

// MARK: - Overgrown Ruins Points of Interest

/// Returns all points of interest for the Overgrown Ruins world.
///
/// Each POI represents a themed location where idle agents can spend time.
/// The massive tree, bioluminescent mushrooms, broken ceiling, and
/// vine-covered server racks all invite exploration.
public func overgrownRuinsPOIs() -> [PointOfInterest] {
    [
        PointOfInterest(
            id: "mushroom_grove",
            category: .nature,
            standPosition: CGPoint(x: 481, y: 100),
            label: "Examine glowing mushrooms",
            emoji: "\u{1F344}",                // 🍄
            animationHint: .faceDown
        ),
        PointOfInterest(
            id: "big_tree",
            category: .nature,
            standPosition: CGPoint(x: 440, y: 360),
            label: "Rest under the tree",
            emoji: "\u{1F333}",                // 🌳
            animationHint: .sit
        ),
        PointOfInterest(
            id: "waterfall_pipe",
            category: .relaxation,
            standPosition: CGPoint(x: 350, y: 550),
            label: "Watch the waterfall",
            emoji: "\u{1F4A7}",                // 💧
            animationHint: .faceUp
        ),
        PointOfInterest(
            id: "bird_nest",
            category: .nature,
            standPosition: CGPoint(x: 780, y: 680),
            label: "Bird watching",
            emoji: "\u{1F426}",                // 🐦
            animationHint: .faceUp
        ),
        PointOfInterest(
            id: "sunbeam_spot",
            category: .relaxation,
            standPosition: CGPoint(x: 900, y: 600),
            label: "Bask in sunbeam",
            emoji: "\u{2600}\u{FE0F}",        // ☀️
            animationHint: .sit
        ),
        PointOfInterest(
            id: "wildflower_patch",
            category: .nature,
            standPosition: CGPoint(x: 200, y: 580),
            label: "Admire wildflowers",
            emoji: "\u{1F338}",                // 🌸
            animationHint: .faceDown
        ),
        PointOfInterest(
            id: "server_rack",
            category: .fidgeting,
            standPosition: CGPoint(x: 620, y: 330),
            label: "Check server logs",
            emoji: "\u{1F5A5}\u{FE0F}",       // 🖥️
            animationHint: .interact
        ),
        PointOfInterest(
            id: "old_whiteboard",
            category: .information,
            standPosition: CGPoint(x: 1080, y: 340),
            label: "Decipher old notes",
            emoji: "\u{1F4CB}",                // 📋
            animationHint: .faceUp
        ),
        PointOfInterest(
            id: "puddle_reflection",
            category: .relaxation,
            standPosition: CGPoint(x: 192, y: 500),
            label: "Gaze at puddle",
            emoji: "\u{1FA9E}",                // 🪞
            animationHint: .faceDown
        ),
        PointOfInterest(
            id: "tree_roots",
            category: .nature,
            standPosition: CGPoint(x: 481, y: 280),
            label: "Explore roots",
            emoji: "\u{1F33F}",                // 🌿
            animationHint: .interact
        ),
        PointOfInterest(
            id: "rubble_pile",
            category: .reading,
            standPosition: CGPoint(x: 140, y: 290),
            label: "Sift through rubble",
            emoji: "\u{1F50D}",                // 🔍
            animationHint: .interact
        ),
    ]
}
