import Foundation
import CoreGraphics

// MARK: - Zen Studio Layout

/// A serene Japanese-inspired workspace with tatami floors, shoji screens,
/// a koi pond courtyard, and low chabudai tables with zabuton cushions.
///
/// Rooms:
/// - Meditation Garden (top-left): rock garden and bonsai
/// - Tea Room (bottom-left): intimate tea ceremony space
/// - Koi Courtyard (center): the heart of the studio
/// - Engawa (center-bottom): covered veranda with wind chimes
/// - Work Hall (top-right): main workspace with 12 seats
/// - Scroll Library (bottom-right): calligraphy and scrolls with 10 seats
public struct ZenStudioLayout: WorldLayout {

    // MARK: - Singleton

    /// Shared instance. Layout is immutable so one copy suffices.
    public static let shared = ZenStudioLayout()

    // MARK: - Scene Geometry

    public let sceneSize = CGSize(width: 1280, height: 768)
    public let walkableArea = CGRect(x: 40, y: 40, width: 1200, height: 688)

    // MARK: - Rooms

    public let rooms: [RoomDefinition] = [
        RoomDefinition(id: "meditation_garden", name: "Meditation Garden",
                       frame: CGRect(x: 52, y: 370, width: 342, height: 346)),
        RoomDefinition(id: "tea_room", name: "Tea Room",
                       frame: CGRect(x: 52, y: 52, width: 342, height: 314)),
        RoomDefinition(id: "koi_courtyard", name: "Koi Courtyard",
                       frame: CGRect(x: 398, y: 268, width: 160, height: 448)),
        RoomDefinition(id: "engawa", name: "Engawa",
                       frame: CGRect(x: 398, y: 52, width: 160, height: 212)),
        RoomDefinition(id: "main_work_hall", name: "Work Hall",
                       frame: CGRect(x: 562, y: 436, width: 666, height: 280)),
        RoomDefinition(id: "scroll_library", name: "Scroll Library",
                       frame: CGRect(x: 562, y: 52, width: 666, height: 380)),
    ]

    // MARK: - Tables & Desks

    public let tables: [TableDefinition]
    public let desks: [DeskPosition]

    // MARK: - Barriers

    public let barriers: [Barrier]

    // MARK: - Navigation

    public let doorPosition = CGPoint(x: 1238, y: 352)
    public let doorExitPosition = CGPoint(x: 1186, y: 352)

    public let aisleYPositions: [CGFloat] = [640, 550, 340, 180, 100]
    public let corridorXPositions: [CGFloat] = [220, 478, 730, 1000, 1180]

    // MARK: - Pets

    /// The zen studio has a cat but no dog.
    public let catStartPosition: CGPoint? = CGPoint(x: 280, y: 500)
    public let dogBowlPosition: CGPoint? = nil
    public let dogSleepPosition: CGPoint? = nil
    public let dogToyPositions: [CGPoint] = []

    // MARK: - Init

    private init() {
        // Table definitions — low chabudai tables with zabuton seating
        let tableDefinitions: [TableDefinition] = [
            // Tea Room tables (6 seats total)
            TableDefinition(id: 0, centerY: 168, seatXPositions: [140, 220, 300]),
            TableDefinition(id: 1, centerY: 100, seatXPositions: [140, 220, 300]),
            // Scroll Library tables (10 seats total)
            TableDefinition(id: 2, centerY: 200, seatXPositions: [730, 820, 910, 1000, 1090]),
            TableDefinition(id: 3, centerY: 120, seatXPositions: [730, 820, 910, 1000, 1090]),
            // Work Hall tables (12 seats total)
            TableDefinition(id: 4, centerY: 618, seatXPositions: [640, 740, 840, 940, 1040, 1140]),
            TableDefinition(id: 5, centerY: 530, seatXPositions: [640, 740, 840, 940, 1040, 1140]),
        ]

        // Generate desk positions from tables.
        // Zabuton cushions sit closer to the table than office chairs: centerY - 24.
        var deskList: [DeskPosition] = []
        var deskID = 0
        for table in tableDefinitions {
            for x in table.seatXPositions {
                deskList.append(
                    DeskPosition(
                        id: deskID,
                        position: CGPoint(x: x, y: table.centerY),
                        chairPosition: CGPoint(x: x, y: table.centerY - 24)
                    )
                )
                deskID += 1
            }
        }

        self.tables = tableDefinitions
        self.desks = deskList

        // Barriers — shoji screens (glassWall), solid walls, and furniture footprints
        self.barriers = [
            // Shoji screen between Meditation Garden and Koi Courtyard
            Barrier(id: "shoji_garden_upper", kind: .glassWall,
                    rect: CGRect(x: 394, y: 558, width: 8, height: 158)),
            Barrier(id: "shoji_garden_lower", kind: .glassWall,
                    rect: CGRect(x: 394, y: 370, width: 8, height: 120)),

            // Solid walls between Tea Room and Engawa
            Barrier(id: "tea_wall_lower", kind: .solidWall,
                    rect: CGRect(x: 394, y: 52, width: 8, height: 86)),
            Barrier(id: "tea_wall_upper", kind: .solidWall,
                    rect: CGRect(x: 394, y: 180, width: 8, height: 186)),

            // East entry walls (with doorway gap)
            Barrier(id: "entry_wall_lower", kind: .solidWall,
                    rect: CGRect(x: 1232, y: 40, width: 8, height: 264)),
            Barrier(id: "entry_wall_upper", kind: .solidWall,
                    rect: CGRect(x: 1232, y: 400, width: 8, height: 328)),

            // Shoji screens between Work Hall and Scroll Library
            Barrier(id: "shoji_hall_left", kind: .glassWall,
                    rect: CGRect(x: 562, y: 432, width: 110, height: 8)),
            Barrier(id: "shoji_hall_right", kind: .glassWall,
                    rect: CGRect(x: 752, y: 432, width: 476, height: 8)),

            // Shoji screens between Koi Courtyard and Engawa
            Barrier(id: "shoji_engawa_left", kind: .glassWall,
                    rect: CGRect(x: 562, y: 264, width: 110, height: 8)),
            Barrier(id: "shoji_engawa_right", kind: .glassWall,
                    rect: CGRect(x: 752, y: 264, width: 476, height: 8)),

            // Koi pond (non-walkable central feature)
            Barrier(id: "koi_pond", kind: .furniture,
                    rect: CGRect(x: 418, y: 380, width: 120, height: 120)),

            // Rock garden (non-walkable in Meditation Garden)
            Barrier(id: "rock_garden", kind: .furniture,
                    rect: CGRect(x: 100, y: 520, width: 200, height: 100)),

            // Bamboo fountain near koi courtyard
            Barrier(id: "bamboo_fountain", kind: .furniture,
                    rect: CGRect(x: 440, y: 540, width: 40, height: 40)),

            // Torii gate visual anchor (small footprint)
            Barrier(id: "torii_gate", kind: .furniture,
                    rect: CGRect(x: 458, y: 688, width: 40, height: 20)),
        ]
    }

    // MARK: - Points of Interest

    public var pointsOfInterest: [PointOfInterest] {
        Self.zenStudioPOIs()
    }

    // MARK: - Decorations

    public var decorations: [DecorationSpec] {
        [
            // Meditation Garden decorations
            DecorationSpec(id: "bonsai_1", textureName: TextureManager.zenBonsaiTree,
                           position: CGPoint(x: 86, y: 680), size: CGSize(width: 36, height: 42)),
            DecorationSpec(id: "bonsai_2", textureName: TextureManager.zenBonsaiTree,
                           position: CGPoint(x: 360, y: 680), size: CGSize(width: 36, height: 42)),
            DecorationSpec(id: "stone_lantern_1", textureName: TextureManager.zenStoneLantern,
                           position: CGPoint(x: 86, y: 420), size: CGSize(width: 24, height: 42)),
            DecorationSpec(id: "stone_lantern_2", textureName: TextureManager.zenStoneLantern,
                           position: CGPoint(x: 360, y: 420), size: CGSize(width: 24, height: 42)),
            DecorationSpec(id: "rock_garden", textureName: TextureManager.zenRockGarden,
                           position: CGPoint(x: 200, y: 570), size: CGSize(width: 192, height: 96), zPosition: 1),
            DecorationSpec(id: "incense_1", textureName: TextureManager.zenIncenseBurner,
                           position: CGPoint(x: 180, y: 680), size: CGSize(width: 24, height: 30)),

            // Tea Room decorations
            DecorationSpec(id: "tea_set_1", textureName: TextureManager.zenTeaSet,
                           position: CGPoint(x: 220, y: 172), size: CGSize(width: 36, height: 24)),
            DecorationSpec(id: "tea_set_2", textureName: TextureManager.zenTeaSet,
                           position: CGPoint(x: 220, y: 104), size: CGSize(width: 36, height: 24)),
            DecorationSpec(id: "hanging_scroll_1", textureName: TextureManager.zenHangingScroll,
                           position: CGPoint(x: 80, y: 310), size: CGSize(width: 24, height: 60)),
            DecorationSpec(id: "paper_lantern_1", textureName: TextureManager.zenPaperLantern,
                           position: CGPoint(x: 350, y: 310), size: CGSize(width: 24, height: 36)),

            // Koi Courtyard decorations
            DecorationSpec(id: "koi_pond", textureName: TextureManager.zenKoiPond,
                           position: CGPoint(x: 478, y: 440), size: CGSize(width: 128, height: 128), zPosition: 1),
            DecorationSpec(id: "cherry_blossom_1", textureName: TextureManager.zenCherryBlossom,
                           position: CGPoint(x: 420, y: 690), size: CGSize(width: 72, height: 48)),
            DecorationSpec(id: "cherry_blossom_2", textureName: TextureManager.zenCherryBlossom,
                           position: CGPoint(x: 530, y: 690), size: CGSize(width: 72, height: 48)),

            // Engawa decorations
            DecorationSpec(id: "wind_chimes_1", textureName: TextureManager.zenWindChimes,
                           position: CGPoint(x: 430, y: 230), size: CGSize(width: 18, height: 36)),
            DecorationSpec(id: "wind_chimes_2", textureName: TextureManager.zenWindChimes,
                           position: CGPoint(x: 520, y: 230), size: CGSize(width: 18, height: 36)),
            DecorationSpec(id: "bamboo_fountain", textureName: TextureManager.zenBambooFountain,
                           position: CGPoint(x: 460, y: 560), size: CGSize(width: 30, height: 30)),

            // Work Hall decorations
            DecorationSpec(id: "torii_gate", textureName: TextureManager.zenToriiGate,
                           position: CGPoint(x: 478, y: 700), size: CGSize(width: 48, height: 84), zPosition: 3),
            DecorationSpec(id: "paper_lantern_2", textureName: TextureManager.zenPaperLantern,
                           position: CGPoint(x: 600, y: 700), size: CGSize(width: 24, height: 36)),
            DecorationSpec(id: "paper_lantern_3", textureName: TextureManager.zenPaperLantern,
                           position: CGPoint(x: 1200, y: 700), size: CGSize(width: 24, height: 36)),

            // Scroll Library decorations
            DecorationSpec(id: "hanging_scroll_2", textureName: TextureManager.zenHangingScroll,
                           position: CGPoint(x: 600, y: 380), size: CGSize(width: 24, height: 60)),
            DecorationSpec(id: "hanging_scroll_3", textureName: TextureManager.zenHangingScroll,
                           position: CGPoint(x: 700, y: 380), size: CGSize(width: 24, height: 60)),
            DecorationSpec(id: "hanging_scroll_4", textureName: TextureManager.zenHangingScroll,
                           position: CGPoint(x: 1200, y: 380), size: CGSize(width: 24, height: 60)),
            DecorationSpec(id: "shoji_screen_1", textureName: TextureManager.zenShojiScreen,
                           position: CGPoint(x: 580, y: 160), size: CGSize(width: 48, height: 72)),
            DecorationSpec(id: "incense_2", textureName: TextureManager.zenIncenseBurner,
                           position: CGPoint(x: 1190, y: 80), size: CGSize(width: 24, height: 30)),
        ]
    }

    // MARK: - Rugs

    public var rugs: [RugSpec] {
        [
            // Tatami-style rug under Meditation Garden rock garden area
            RugSpec(id: "tatami_garden", position: CGPoint(x: 223, y: 543),
                    size: CGSize(width: 300, height: 280), cornerRadius: 8, colorSlot: .focus),
            // Tatami under Tea Room
            RugSpec(id: "tatami_tea", position: CGPoint(x: 223, y: 134),
                    size: CGSize(width: 300, height: 240), cornerRadius: 8, colorSlot: .lounge),
            // Koi courtyard gravel path
            RugSpec(id: "gravel_courtyard", position: CGPoint(x: 478, y: 492),
                    size: CGSize(width: 120, height: 380), cornerRadius: 12, colorSlot: .gallery),
            // Engawa veranda runner
            RugSpec(id: "engawa_runner", position: CGPoint(x: 478, y: 158),
                    size: CGSize(width: 120, height: 160), cornerRadius: 8, colorSlot: .gallery),
            // Work Hall tatami
            RugSpec(id: "tatami_work", position: CGPoint(x: 895, y: 574),
                    size: CGSize(width: 580, height: 220), cornerRadius: 8, colorSlot: .collab),
            // Scroll Library tatami
            RugSpec(id: "tatami_library", position: CGPoint(x: 895, y: 160),
                    size: CGSize(width: 580, height: 220), cornerRadius: 8, colorSlot: .build),
        ]
    }

    // MARK: - POI Factory

    /// Returns all points of interest for the Zen Studio world.
    public static func zenStudioPOIs() -> [PointOfInterest] {
        [
            // Refreshment
            PointOfInterest(
                id: "zen_bamboo_fountain",
                category: .refreshment,
                standPosition: CGPoint(x: 480, y: 556),
                label: "Sipping water",
                emoji: "\u{1F4A7}",
                animationHint: .interact
            ),
            PointOfInterest(
                id: "zen_tea_station",
                category: .refreshment,
                standPosition: CGPoint(x: 220, y: 200),
                label: "Brewing tea",
                emoji: "\u{1F375}",
                animationHint: .interact
            ),

            // Relaxation
            PointOfInterest(
                id: "zen_meditation_cushion",
                category: .relaxation,
                standPosition: CGPoint(x: 200, y: 460),
                label: "Meditating",
                emoji: "\u{1F9D8}",
                animationHint: .sit
            ),
            PointOfInterest(
                id: "zen_engawa_seat",
                category: .relaxation,
                standPosition: CGPoint(x: 478, y: 140),
                label: "Resting on veranda",
                emoji: "\u{1F343}",
                animationHint: .sit
            ),

            // Social
            PointOfInterest(
                id: "zen_tea_chat",
                category: .social,
                standPosition: CGPoint(x: 280, y: 200),
                label: "Tea ceremony chat",
                emoji: "\u{1F375}",
                animationHint: .faceDown
            ),
            PointOfInterest(
                id: "zen_courtyard_chat",
                category: .social,
                standPosition: CGPoint(x: 460, y: 340),
                label: "Chatting by the pond",
                emoji: "\u{1F4AC}",
                animationHint: .faceDown
            ),

            // Reading / Knowledge
            PointOfInterest(
                id: "zen_scroll_shelf_1",
                category: .reading,
                standPosition: CGPoint(x: 620, y: 380),
                label: "Reading scrolls",
                emoji: "\u{1F4DC}",
                animationHint: .faceUp
            ),
            PointOfInterest(
                id: "zen_scroll_shelf_2",
                category: .reading,
                standPosition: CGPoint(x: 1200, y: 380),
                label: "Studying calligraphy",
                emoji: "\u{270D}\u{FE0F}",
                animationHint: .faceUp
            ),

            // Creative
            PointOfInterest(
                id: "zen_calligraphy_desk",
                category: .creative,
                standPosition: CGPoint(x: 700, y: 380),
                label: "Practicing calligraphy",
                emoji: "\u{1F58C}\u{FE0F}",
                animationHint: .faceUp
            ),

            // Nature
            PointOfInterest(
                id: "zen_koi_pond",
                category: .nature,
                standPosition: CGPoint(x: 478, y: 380),
                label: "Watching koi",
                emoji: "\u{1F41F}",
                animationHint: .faceDown
            ),
            PointOfInterest(
                id: "zen_bonsai_1",
                category: .nature,
                standPosition: CGPoint(x: 100, y: 660),
                label: "Tending bonsai",
                emoji: "\u{1FAB4}",
                animationHint: .interact
            ),
            PointOfInterest(
                id: "zen_cherry_blossom",
                category: .nature,
                standPosition: CGPoint(x: 478, y: 670),
                label: "Under the blossoms",
                emoji: "\u{1F338}",
                animationHint: .faceUp
            ),
            PointOfInterest(
                id: "zen_rock_garden",
                category: .nature,
                standPosition: CGPoint(x: 200, y: 640),
                label: "Contemplating stones",
                emoji: "\u{1FAA8}",
                animationHint: .faceDown
            ),

            // Fidgeting / Utility
            PointOfInterest(
                id: "zen_incense",
                category: .fidgeting,
                standPosition: CGPoint(x: 180, y: 660),
                label: "Lighting incense",
                emoji: "\u{1F9EF}",
                animationHint: .interact
            ),

            // Music
            PointOfInterest(
                id: "zen_wind_chimes",
                category: .music,
                standPosition: CGPoint(x: 478, y: 210),
                label: "Listening to chimes",
                emoji: "\u{1F390}",
                animationHint: .faceUp
            ),

            // Pets (cat roaming area)
            PointOfInterest(
                id: "zen_cat_spot",
                category: .pets,
                standPosition: CGPoint(x: 300, y: 500),
                label: "Petting the cat",
                emoji: "\u{1F408}",
                animationHint: .interact
            ),

            // Information
            PointOfInterest(
                id: "zen_hanging_scroll_info",
                category: .information,
                standPosition: CGPoint(x: 80, y: 290),
                label: "Reading the scroll",
                emoji: "\u{1F4DC}",
                animationHint: .faceUp
            ),
        ]
    }
}

// MARK: - OfficeLayout Compatibility

extension OfficeLayout {
    /// Convenience accessor that returns a classic `OfficeLayout` matching
    /// the Zen Studio geometry. Useful for code that hasn't migrated to
    /// ``WorldLayout`` yet.
    public static let zenStudio: OfficeLayout = {
        let zen = ZenStudioLayout.shared
        return OfficeLayout(
            sceneSize: zen.sceneSize,
            desks: zen.desks,
            tables: zen.tables,
            rooms: zen.rooms,
            walkableArea: zen.walkableArea,
            barriers: zen.barriers
        )
    }()
}
