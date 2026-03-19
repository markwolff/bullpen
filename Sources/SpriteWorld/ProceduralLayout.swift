import Foundation

// MARK: - Procedural Layout

private struct ProceduralRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    mutating func nextInt(upperBound: Int) -> Int {
        Int(next() % UInt64(upperBound))
    }

    mutating func nextCGFloat(in range: ClosedRange<CGFloat>) -> CGFloat {
        let unit = CGFloat(next() & 0xFFFF) / CGFloat(UInt16.max)
        return range.lowerBound + (range.upperBound - range.lowerBound) * unit
    }

    mutating func shuffled<T>(_ values: [T]) -> [T] {
        var copy = values
        guard copy.count > 1 else { return copy }
        for index in copy.indices.dropLast() {
            let swapIndex = index + nextInt(upperBound: copy.count - index)
            if index != swapIndex {
                copy.swapAt(index, swapIndex)
            }
        }
        return copy
    }
}

private struct ProceduralModule {
    let roomID: String
    let defaultName: String
    let alternateNames: [String]
    let frame: CGRect
    let seatRows: [(centerY: CGFloat, seatXPositions: [CGFloat])]
    let furnitureBarriers: [OfficeLayout.Barrier]
}

extension OfficeLayout {
    public static let proceduralDefaultSeed: UInt64 = 0xC0DEC0DEB0015EED
    public static let proceduralBaseHeadcount: Int = 6

    public static func procedural(headcount: Int, seed: UInt64) -> OfficeLayout {
        var rng = ProceduralRNG(seed: seed)
        let normalizedHeadcount = max(headcount, proceduralBaseHeadcount)
        let activeDeskModuleCount: Int

        switch normalizedHeadcount {
        case ...8:
            activeDeskModuleCount = 2
        case ...16:
            activeDeskModuleCount = 3
        case ...24:
            activeDeskModuleCount = 4
        default:
            activeDeskModuleCount = 5
        }

        let sceneSize = CGSize(width: 1280, height: 768)
        let walkableArea = CGRect(x: 40, y: 40, width: 1200, height: 688)

        let westAnnex = ProceduralModule(
            roomID: "proc_west",
            defaultName: "Seed Nursery",
            alternateNames: ["Patch Nursery", "Draft Conservatory", "Scout Bloom"],
            frame: CGRect(x: 52, y: 410, width: 300, height: 306),
            seatRows: [
                (centerY: 584, seatXPositions: [126, 218, 310]),
                (centerY: 492, seatXPositions: [126, 218, 310]),
            ],
            furnitureBarriers: [
                Barrier(id: "proc_west_planter", kind: .furniture, rect: CGRect(x: 86, y: 638, width: 56, height: 32)),
            ]
        )

        let buildForge = ProceduralModule(
            roomID: "proc_forge",
            defaultName: "Compile Forge",
            alternateNames: ["Runtime Foundry", "Build Kiln", "Binary Furnace"],
            frame: CGRect(x: 560, y: 52, width: 352, height: 212),
            seatRows: [
                (centerY: 192, seatXPositions: [620, 710, 800, 890, 980]),
                (centerY: 122, seatXPositions: [620, 710, 800, 890, 980]),
            ],
            furnitureBarriers: [
                Barrier(id: "proc_forge_console", kind: .furniture, rect: CGRect(x: 572, y: 92, width: 34, height: 34)),
            ]
        )

        let collabDeck = ProceduralModule(
            roomID: "proc_deck",
            defaultName: "Signal Deck",
            alternateNames: ["Handshake Deck", "Relay Terrace", "Merge Arena"],
            frame: CGRect(x: 560, y: 436, width: 352, height: 280),
            seatRows: [
                (centerY: 622, seatXPositions: [630, 720, 810, 900]),
                (centerY: 538, seatXPositions: [630, 720, 810, 900]),
            ],
            furnitureBarriers: [
                Barrier(id: "proc_deck_reactor", kind: .furniture, rect: CGRect(x: 804, y: 470, width: 72, height: 30)),
            ]
        )

        let skyLab = ProceduralModule(
            roomID: "proc_sky",
            defaultName: "Sky Braid",
            alternateNames: ["Orbit Lattice", "Beacon Array", "Cloud Switchyard"],
            frame: CGRect(x: 916, y: 436, width: 312, height: 280),
            seatRows: [
                (centerY: 622, seatXPositions: [976, 1068, 1160]),
                (centerY: 538, seatXPositions: [976, 1068, 1160]),
            ],
            furnitureBarriers: [
                Barrier(id: "proc_sky_scanner", kind: .furniture, rect: CGRect(x: 1092, y: 470, width: 76, height: 30)),
            ]
        )

        let archiveWing = ProceduralModule(
            roomID: "proc_archive",
            defaultName: "Memory Vault",
            alternateNames: ["Archive Quay", "Recall Bank", "Replay Dock"],
            frame: CGRect(x: 916, y: 52, width: 312, height: 212),
            seatRows: [
                (centerY: 192, seatXPositions: [976, 1068, 1160]),
                (centerY: 122, seatXPositions: [976, 1068, 1160]),
            ],
            furnitureBarriers: [
                Barrier(id: "proc_archive_stacks", kind: .furniture, rect: CGRect(x: 1112, y: 82, width: 74, height: 62)),
            ]
        )

        let optionalModules = rng.shuffled([collabDeck, skyLab, archiveWing])
        let activeDeskModules = Array(([westAnnex, buildForge] + optionalModules).prefix(activeDeskModuleCount))

        let spineNamePool = ["Signal Spine", "Kernel Spine", "Transit Trunk", "Packet Spine"]
        let hubNamePool = ["Recruiting Core", "Pulse Commons", "Expansion Kernel", "Assembly Heart"]
        let spine = RoomDefinition(
            id: "proc_spine",
            name: spineNamePool[rng.nextInt(upperBound: spineNamePool.count)],
            frame: CGRect(x: 390, y: 52, width: 152, height: 664)
        )
        let hub = RoomDefinition(
            id: "proc_hub",
            name: hubNamePool[rng.nextInt(upperBound: hubNamePool.count)],
            frame: CGRect(x: 558, y: 278, width: 336, height: 148)
        )
        let lounge = RoomDefinition(
            id: "proc_lounge",
            name: "Soft Launch",
            frame: CGRect(x: 52, y: 52, width: 300, height: 314)
        )

        var rooms = [lounge, spine, hub]
        for module in activeDeskModules {
            let roomNames = [module.defaultName] + module.alternateNames
            rooms.append(
                RoomDefinition(
                    id: module.roomID,
                    name: roomNames[rng.nextInt(upperBound: roomNames.count)],
                    frame: module.frame
                )
            )
        }

        var tables: [TableDefinition] = []
        var desks: [DeskPosition] = []
        var tableID = 0
        var deskID = 0

        for module in activeDeskModules {
            for row in module.seatRows {
                var seatPositions: [CGFloat] = []
                for baseX in row.seatXPositions {
                    seatPositions.append(baseX + rng.nextCGFloat(in: -8...8))
                }
                seatPositions.sort()

                let table = TableDefinition(id: tableID, centerY: row.centerY, seatXPositions: seatPositions)
                tables.append(table)

                for x in seatPositions {
                    desks.append(
                        DeskPosition(
                            id: deskID,
                            position: CGPoint(x: x, y: row.centerY),
                            chairPosition: CGPoint(x: x, y: row.centerY - 30)
                        )
                    )
                    deskID += 1
                }

                tableID += 1
            }
        }

        var barriers: [Barrier] = [
            Barrier(id: "proc_west_glass_upper", kind: .glassWall, rect: CGRect(x: 386, y: 410, width: 8, height: 132)),
            Barrier(id: "proc_west_glass_lower", kind: .glassWall, rect: CGRect(x: 386, y: 602, width: 8, height: 114)),
            Barrier(id: "proc_lounge_wall_lower", kind: .solidWall, rect: CGRect(x: 386, y: 52, width: 8, height: 86)),
            Barrier(id: "proc_lounge_wall_upper", kind: .solidWall, rect: CGRect(x: 386, y: 182, width: 8, height: 184)),
            Barrier(id: "proc_build_glass", kind: .glassWall, rect: CGRect(x: 560, y: 264, width: 320, height: 8)),
            Barrier(id: "proc_build_glass_far", kind: .glassWall, rect: CGRect(x: 960, y: 264, width: 268, height: 8)),
            Barrier(id: "proc_deck_glass", kind: .glassWall, rect: CGRect(x: 560, y: 436, width: 320, height: 8)),
            Barrier(id: "proc_deck_glass_far", kind: .glassWall, rect: CGRect(x: 960, y: 436, width: 268, height: 8)),
            Barrier(id: "proc_far_split_upper", kind: .glassWall, rect: CGRect(x: 912, y: 436, width: 8, height: 280)),
            Barrier(id: "proc_far_split_lower", kind: .glassWall, rect: CGRect(x: 912, y: 52, width: 8, height: 212)),
            Barrier(id: "proc_entry_wall_lower", kind: .solidWall, rect: CGRect(x: 1232, y: 40, width: 8, height: 264)),
            Barrier(id: "proc_entry_wall_upper", kind: .solidWall, rect: CGRect(x: 1232, y: 400, width: 8, height: 328)),
            Barrier(id: "proc_cooler", kind: .furniture, rect: CGRect(x: 680, y: 304, width: 40, height: 72)),
            Barrier(id: "proc_coffee_bar", kind: .furniture, rect: CGRect(x: 1034, y: 296, width: 118, height: 46)),
            Barrier(id: "proc_printer", kind: .furniture, rect: CGRect(x: 564, y: 96, width: 34, height: 34)),
            Barrier(id: "proc_ping_pong", kind: .furniture, rect: CGRect(x: 138, y: 248, width: 124, height: 60)),
        ]

        barriers += activeDeskModules.flatMap(\.furnitureBarriers)

        return OfficeLayout(
            preset: .procedural,
            sceneSize: sceneSize,
            desks: desks,
            tables: tables,
            rooms: rooms,
            walkableArea: walkableArea,
            barriers: barriers
        )
    }
}

// MARK: - Procedural Points of Interest

public func proceduralRugs() -> [RugSpec] {
    [
        RugSpec(
            id: "gallery",
            position: CGPoint(x: 726, y: 352),
            size: CGSize(width: 220, height: 88),
            cornerRadius: 22,
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
            position: CGPoint(x: 218, y: 538),
            size: CGSize(width: 210, height: 60),
            cornerRadius: 14,
            colorSlot: .focus
        ),
        RugSpec(
            id: "build",
            position: CGPoint(x: 744, y: 158),
            size: CGSize(width: 280, height: 54),
            cornerRadius: 12,
            colorSlot: .build
        ),
        RugSpec(
            id: "collab",
            position: CGPoint(x: 1060, y: 304),
            size: CGSize(width: 132, height: 52),
            cornerRadius: 16,
            colorSlot: .collab
        ),
    ]
}

public func proceduralDecorations() -> [DecorationSpec] {
    [
        DecorationSpec(id: "plant_0", textureName: TextureManager.decorationPlant,
                       position: CGPoint(x: 96, y: 714), size: CGSize(width: 48, height: 80)),
        DecorationSpec(id: "plant_1", textureName: TextureManager.decorationPlant,
                       position: CGPoint(x: 1160, y: 714), size: CGSize(width: 48, height: 80)),
        DecorationSpec(id: "plant_2", textureName: TextureManager.decorationPlant,
                       position: CGPoint(x: 92, y: 96), size: CGSize(width: 40, height: 68)),
        DecorationSpec(id: "plant_3", textureName: TextureManager.decorationPlant,
                       position: CGPoint(x: 1140, y: 96), size: CGSize(width: 40, height: 68)),
        DecorationSpec(id: "window", textureName: TextureManager.decorationWindow,
                       position: CGPoint(x: 246, y: 706), size: CGSize(width: 100, height: 80)),
        DecorationSpec(id: "window_2", textureName: TextureManager.decorationWindow,
                       position: CGPoint(x: 1102, y: 706), size: CGSize(width: 100, height: 80)),
        DecorationSpec(id: "whiteboard", textureName: TextureManager.decorationWhiteboard,
                       position: CGPoint(x: 592, y: 396), size: CGSize(width: 120, height: 80)),
        DecorationSpec(id: "clock", textureName: TextureManager.decorationClock,
                       position: CGPoint(x: 1020, y: 720), size: CGSize(width: 40, height: 40)),
        DecorationSpec(id: "poster", textureName: TextureManager.decorationPoster,
                       position: CGPoint(x: 306, y: 680), size: CGSize(width: 56, height: 72)),
        DecorationSpec(id: "bookshelf", textureName: TextureManager.decorationBookshelf,
                       position: CGPoint(x: 130, y: 710), size: CGSize(width: 80, height: 64)),
        DecorationSpec(id: "bulletin_board", textureName: TextureManager.decorationBulletinBoard,
                       position: CGPoint(x: 820, y: 420), size: CGSize(width: 80, height: 56)),
        DecorationSpec(id: "water_cooler", textureName: TextureManager.decorationWaterCooler,
                       position: CGPoint(x: 720, y: 348), size: CGSize(width: 40, height: 80)),
        DecorationSpec(id: "door", textureName: TextureManager.decorationDoor,
                       position: CGPoint(x: 1238, y: 352), size: CGSize(width: 56, height: 96)),
        DecorationSpec(id: "couch", textureName: TextureManager.decorationCouch,
                       position: CGPoint(x: 280, y: 140), size: CGSize(width: 60, height: 36)),
        DecorationSpec(id: "printer", textureName: TextureManager.decorationPrinter,
                       position: CGPoint(x: 580, y: 114), size: CGSize(width: 30, height: 30)),
        DecorationSpec(id: "collab_plant", textureName: TextureManager.decorationPlant,
                       position: CGPoint(x: 884, y: 494), size: CGSize(width: 44, height: 72)),
        DecorationSpec(id: "lounge_shelf", textureName: TextureManager.decorationBookshelf,
                       position: CGPoint(x: 90, y: 220), size: CGSize(width: 56, height: 48)),
        DecorationSpec(id: "lounge_plant", textureName: TextureManager.decorationPlant,
                       position: CGPoint(x: 350, y: 220), size: CGSize(width: 32, height: 52)),
    ]
}

public func proceduralPOIs() -> [PointOfInterest] {
    [
        PointOfInterest(
            id: "proc_water_cooler",
            category: .refreshment,
            standPosition: CGPoint(x: 700, y: 340),
            label: "Tap coolant line",
            emoji: "\u{1F4A7}",
            animationHint: .interact
        ),
        PointOfInterest(
            id: "proc_bookshelf",
            category: .reading,
            standPosition: CGPoint(x: 130, y: 674),
            label: "Browse seed archives",
            emoji: "\u{1F4D8}",
            animationHint: .faceUp
        ),
        PointOfInterest(
            id: "proc_bulletin",
            category: .information,
            standPosition: CGPoint(x: 900, y: 386),
            label: "Read growth backlog",
            emoji: "\u{1F4CC}",
            animationHint: .faceUp
        ),
        PointOfInterest(
            id: "proc_window",
            category: .relaxation,
            standPosition: CGPoint(x: 904, y: 672),
            label: "Watch new annexes boot",
            emoji: "\u{2728}",
            animationHint: .faceUp
        ),
        PointOfInterest(
            id: "proc_whiteboard",
            category: .creative,
            standPosition: CGPoint(x: 592, y: 352),
            label: "Sketch the next branch",
            emoji: "\u{1F4A1}",
            animationHint: .faceUp
        ),
        PointOfInterest(
            id: "proc_plant_nw",
            category: .nature,
            standPosition: CGPoint(x: 86, y: 674),
            label: "Tune greenhouse patch",
            emoji: "\u{1F331}",
            animationHint: .interact
        ),
        PointOfInterest(
            id: "proc_plant_ne",
            category: .nature,
            standPosition: CGPoint(x: 1152, y: 674),
            label: "Tune greenhouse patch",
            emoji: "\u{1F331}",
            animationHint: .interact
        ),
        PointOfInterest(
            id: "proc_plant_sw",
            category: .nature,
            standPosition: CGPoint(x: 92, y: 96),
            label: "Prune runtime vines",
            emoji: "\u{1F33F}",
            animationHint: .interact
        ),
        PointOfInterest(
            id: "proc_plant_se",
            category: .nature,
            standPosition: CGPoint(x: 1140, y: 96),
            label: "Prune runtime vines",
            emoji: "\u{1F33F}",
            animationHint: .interact
        ),
        PointOfInterest(
            id: "proc_coffee",
            category: .refreshment,
            standPosition: CGPoint(x: 1012, y: 324),
            label: "Queue at synth bar",
            emoji: "\u{2615}",
            animationHint: .interact
        ),
        PointOfInterest(
            id: "proc_lounge",
            category: .relaxation,
            standPosition: CGPoint(x: 280, y: 140),
            label: "Sink into launch couch",
            emoji: "\u{1F6CB}\u{FE0F}",
            animationHint: .sit
        ),
        PointOfInterest(
            id: "proc_radio",
            category: .music,
            standPosition: CGPoint(x: 116, y: 218),
            label: "Listen to build hum",
            emoji: "\u{1F3B5}",
            animationHint: .dance
        ),
        PointOfInterest(
            id: "proc_printer",
            category: .fidgeting,
            standPosition: CGPoint(x: 580, y: 110),
            label: "Kick the fabricator",
            emoji: "\u{1F5A8}\u{FE0F}",
            animationHint: .interact
        ),
        PointOfInterest(
            id: "proc_ping_pong",
            category: .recreation,
            standPosition: CGPoint(x: 200, y: 280),
            label: "Play merge pong",
            emoji: "\u{1F3D3}",
            animationHint: .interact
        ),
    ]
}
