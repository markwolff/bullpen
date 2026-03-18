import SpriteKit
import AppKit

// MARK: - Zen Studio Textures

extension PixelArtGenerator {

    // MARK: - Zen Color Palette

    static let zenVermillion = RGB(0xCC3333)
    static let zenVermillionDark = RGB(0xA02828)
    static let zenVermillionLight = RGB(0xE05040)
    static let zenCream = RGB(0xF5ECD8)
    static let zenCreamDark = RGB(0xE0D4B8)
    static let zenPaper = RGB(0xF8F0E0)
    static let zenPaperGrid = RGB(0xD8C8A8)
    static let zenWoodFrame = RGB(0x5A3A20)
    static let zenWoodFrameLight = RGB(0x7A5A38)
    static let zenWoodDark = RGB(0x3A2210)
    static let zenStoneGray = RGB(0x8A8A80)
    static let zenStoneDark = RGB(0x5A5A52)
    static let zenStoneLight = RGB(0xA8A898)
    static let zenWaterBlue = RGB(0x5090C0)
    static let zenWaterLight = RGB(0x78B8E0)
    static let zenWaterDark = RGB(0x386898)
    static let zenKoiOrange = RGB(0xE87830)
    static let zenKoiWhite = RGB(0xF0E8D8)
    static let zenKoiRed = RGB(0xD04030)
    static let zenLilyGreen = RGB(0x48A060)
    static let zenLilyFlower = RGB(0xF0A0B0)
    static let zenBonsaiGreen = RGB(0x388838)
    static let zenBonsaiLight = RGB(0x50B050)
    static let zenBonsaiTrunk = RGB(0x6A4A28)
    static let zenBonsaiTrunkDark = RGB(0x4A3018)
    static let zenPotTerracotta = RGB(0xB06838)
    static let zenPotDark = RGB(0x885028)
    static let zenSandBase = RGB(0xE0D8C0)
    static let zenSandLines = RGB(0xC8C0A8)
    static let zenSandDark = RGB(0xA89878)
    static let zenBlossomPink = RGB(0xF8B0C0)
    static let zenBlossomWhite = RGB(0xFFF0F0)
    static let zenBlossomDark = RGB(0xE098A8)
    static let zenBranchBrown = RGB(0x5A3A20)
    static let zenBranchLight = RGB(0x7A5A38)
    static let zenTeapotGreen = RGB(0x507848)
    static let zenTeapotDark = RGB(0x3A5830)
    static let zenCupWhite = RGB(0xF0E8D8)
    static let zenTeaGreen = RGB(0x90C870)
    static let zenScrollPaper = RGB(0xE8DCC0)
    static let zenScrollDark = RGB(0xC8B898)
    static let zenInk = RGB(0x282828)
    static let zenRollerWood = RGB(0x6A4A28)
    static let zenLanternWarm = RGB(0xF0C060)
    static let zenLanternHot = RGB(0xF8D888)
    static let zenLanternRib = RGB(0xD8A848)
    static let zenLanternFrame = RGB(0x5A3A20)
    static let zenBambooGreen = RGB(0x68A048)
    static let zenBambooDark = RGB(0x508030)
    static let zenBambooLight = RGB(0x80B860)
    static let zenWaterDrop = RGB(0xA0D8F0)
    static let zenChimeMetal = RGB(0xB0B8C0)
    static let zenChimeLight = RGB(0xD0D8E0)
    static let zenChimeDark = RGB(0x888890)
    static let zenChimeString = RGB(0xA09080)
    static let zenBronze = RGB(0xA08040)
    static let zenBronzeDark = RGB(0x806030)
    static let zenBronzeLight = RGB(0xC0A060)
    static let zenSmoke = RGB(0xC8C8D0)
    static let zenSmokeFaint = RGB(0xD8D8E0)
    static let zenCushionIndigo = RGB(0x303870)
    static let zenCushionLight = RGB(0x404888)
    static let zenCushionDark = RGB(0x202858)
    static let zenCushionTassel = RGB(0xC8A050)
    static let zenTableDark = RGB(0x3A2210)
    static let zenTableMid = RGB(0x5A3A20)
    static let zenTableLight = RGB(0x7A5A38)
    static let zenTableHighlight = RGB(0x9A7A50)
    static let zenGlowYellow = RGB(0xF0D060)

    // MARK: - Torii Gate (16x28)

    /// Vermillion red torii gate with dark cross beams.
    func toriiGate() -> SKTexture {
        drawTexture(width: 16, height: 28) { [self] ctx in
            // Two main vertical pillars
            fill(ctx, rect: r(1, 0, 3, 24), color: Self.zenVermillion)
            fill(ctx, rect: r(12, 0, 3, 24), color: Self.zenVermillion)

            // Pillar highlights
            fill(ctx, rect: r(2, 0, 1, 24), color: Self.zenVermillionLight)

            // Pillar dark edge
            fill(ctx, rect: r(1, 0, 1, 24), color: Self.zenVermillionDark)
            fill(ctx, rect: r(14, 0, 1, 24), color: Self.zenVermillionDark)

            // Top beam (kasagi) — wider, curved up at ends
            fill(ctx, rect: r(0, 24, 16, 3), color: Self.zenVermillion)
            fill(ctx, rect: r(0, 27, 16, 1), color: Self.zenVermillionDark) // top edge
            fill(ctx, rect: r(0, 24, 16, 1), color: Self.zenVermillionLight) // bottom edge highlight

            // Curved tips of kasagi
            fill(ctx, rect: r(0, 25, 1, 2), color: Self.zenVermillionDark)
            fill(ctx, rect: r(15, 25, 1, 2), color: Self.zenVermillionDark)

            // Lower cross beam (nuki)
            fill(ctx, rect: r(0, 20, 16, 2), color: Self.zenWoodDark)
            fill(ctx, rect: r(0, 21, 16, 1), color: Self.zenWoodFrameLight)

            // Gakuzuka (central tablet between beams)
            fill(ctx, rect: r(6, 22, 4, 2), color: Self.zenWoodDark)
            fill(ctx, rect: r(7, 22, 2, 1), color: Self.zenWoodFrameLight)

            // Pillar bases (stone)
            fill(ctx, rect: r(0, 0, 5, 2), color: Self.zenStoneGray)
            fill(ctx, rect: r(11, 0, 5, 2), color: Self.zenStoneGray)
            fill(ctx, rect: r(1, 0, 3, 1), color: Self.zenStoneLight)
            fill(ctx, rect: r(12, 0, 3, 1), color: Self.zenStoneLight)
        }
    }

    // MARK: - Koi Pond (32x32)

    /// Blue water with 2-3 orange/white koi fish and lily pads.
    func koiPond() -> SKTexture {
        drawTexture(width: 32, height: 32) { [self] ctx in
            // Pond border (stone edge)
            fill(ctx, rect: r(0, 0, 32, 32), color: Self.zenStoneGray)
            fill(ctx, rect: r(1, 1, 30, 30), color: Self.zenStoneDark)

            // Water fill
            fill(ctx, rect: r(2, 2, 28, 28), color: Self.zenWaterBlue)

            // Water depth variation
            fill(ctx, rect: r(4, 4, 10, 8), color: Self.zenWaterDark)
            fill(ctx, rect: r(18, 16, 10, 8), color: Self.zenWaterDark)

            // Water highlights / ripples
            fill(ctx, rect: r(8, 20, 4, 1), color: Self.zenWaterLight)
            fill(ctx, rect: r(14, 10, 5, 1), color: Self.zenWaterLight)
            fill(ctx, rect: r(20, 24, 3, 1), color: Self.zenWaterLight)
            fill(ctx, rect: r(6, 14, 3, 1), color: Self.zenWaterLight)

            // Koi fish 1 — orange, swimming right
            fill(ctx, rect: r(6, 8, 5, 2), color: Self.zenKoiOrange)
            fill(ctx, rect: r(5, 9, 1, 1), color: Self.zenKoiOrange)  // tail
            fill(ctx, rect: r(11, 8, 1, 1), color: Self.zenKoiOrange) // head
            fill(ctx, rect: r(7, 8, 1, 1), color: Self.zenKoiWhite)   // marking

            // Koi fish 2 — white with red, swimming left
            fill(ctx, rect: r(18, 18, 5, 2), color: Self.zenKoiWhite)
            fill(ctx, rect: r(23, 19, 1, 1), color: Self.zenKoiWhite) // tail
            fill(ctx, rect: r(17, 18, 1, 1), color: Self.zenKoiWhite) // head
            fill(ctx, rect: r(20, 18, 2, 1), color: Self.zenKoiRed)   // marking

            // Koi fish 3 — small orange, swimming down
            fill(ctx, rect: r(24, 6, 2, 4), color: Self.zenKoiOrange)
            fill(ctx, rect: r(24, 5, 1, 1), color: Self.zenKoiOrange)  // tail
            fill(ctx, rect: r(25, 6, 1, 1), color: Self.zenKoiWhite)   // marking

            // Lily pad 1
            fill(ctx, rect: r(4, 22, 3, 2), color: Self.zenLilyGreen)
            fill(ctx, rect: r(5, 24, 1, 1), color: Self.zenLilyGreen)
            fill(ctx, rect: r(4, 23, 1, 1), color: Self.zenBonsaiGreen) // shadow

            // Lily pad 2
            fill(ctx, rect: r(14, 26, 3, 2), color: Self.zenLilyGreen)
            fill(ctx, rect: r(15, 28, 1, 1), color: Self.zenLilyGreen)

            // Lily flower
            fill(ctx, rect: r(5, 23, 1, 1), color: Self.zenLilyFlower)

            // Stone edge highlight (top)
            fill(ctx, rect: r(2, 30, 28, 1), color: Self.zenStoneLight)
            fill(ctx, rect: r(2, 1, 28, 1), color: Self.zenStoneDark)
        }
    }

    // MARK: - Bonsai Tree (12x14)

    /// Green canopy on twisted brown trunk in terracotta pot.
    func bonsaiTree() -> SKTexture {
        drawTexture(width: 12, height: 14) { [self] ctx in
            // Terracotta pot
            fill(ctx, rect: r(3, 0, 6, 3), color: Self.zenPotTerracotta)
            fill(ctx, rect: r(2, 2, 8, 1), color: Self.zenPotTerracotta) // rim
            fill(ctx, rect: r(4, 0, 4, 1), color: Self.zenPotDark)        // base shadow
            fill(ctx, rect: r(3, 2, 6, 1), color: Self.zenPotDark)        // rim shadow

            // Soil
            fill(ctx, rect: r(3, 3, 6, 1), color: Self.zenBonsaiTrunkDark)

            // Trunk — twisted
            fill(ctx, rect: r(5, 4, 2, 3), color: Self.zenBonsaiTrunk)
            fill(ctx, rect: r(4, 6, 1, 2), color: Self.zenBonsaiTrunk)
            fill(ctx, rect: r(6, 7, 2, 1), color: Self.zenBonsaiTrunk)
            fill(ctx, rect: r(5, 4, 1, 1), color: Self.zenBonsaiTrunkDark) // dark side

            // Left branch
            fill(ctx, rect: r(3, 7, 2, 1), color: Self.zenBonsaiTrunk)

            // Right branch
            fill(ctx, rect: r(7, 8, 2, 1), color: Self.zenBonsaiTrunk)

            // Canopy — rounded mass
            fill(ctx, rect: r(1, 8, 4, 3), color: Self.zenBonsaiGreen)   // left mass
            fill(ctx, rect: r(5, 9, 5, 3), color: Self.zenBonsaiGreen)   // right mass
            fill(ctx, rect: r(3, 11, 6, 2), color: Self.zenBonsaiGreen)  // top
            fill(ctx, rect: r(4, 13, 4, 1), color: Self.zenBonsaiGreen)  // peak

            // Canopy highlights
            fill(ctx, rect: r(2, 10, 2, 1), color: Self.zenBonsaiLight)
            fill(ctx, rect: r(6, 11, 2, 1), color: Self.zenBonsaiLight)
            fill(ctx, rect: r(4, 13, 2, 1), color: Self.zenBonsaiLight)

            // Canopy shadows
            fill(ctx, rect: r(1, 8, 2, 1), color: Self.zenBambooDark)
            fill(ctx, rect: r(8, 9, 2, 1), color: Self.zenBambooDark)
        }
    }

    // MARK: - Shoji Screen (16x24)

    /// Cream/white paper grid with thin dark wood frame.
    func shojiScreen() -> SKTexture {
        drawTexture(width: 16, height: 24) { [self] ctx in
            // Outer wood frame
            fill(ctx, rect: r(0, 0, 16, 24), color: Self.zenWoodFrame)

            // Paper panels (3 columns x 4 rows)
            let panelW = 4
            let panelH = 5
            for col in 0..<3 {
                for row in 0..<4 {
                    let px = 1 + col * 5
                    let py = 1 + row * 6
                    fill(ctx, rect: r(px, py, panelW, panelH), color: Self.zenPaper)
                    // Subtle paper texture
                    if (col + row) % 2 == 0 {
                        fill(ctx, rect: r(px + 1, py + 1, 2, 1), color: Self.zenPaperGrid)
                    }
                }
            }

            // Cross-hatch grid lines (wood muntins)
            for col in 0..<2 {
                let x = 5 + col * 5
                fill(ctx, rect: r(x, 0, 1, 24), color: Self.zenWoodFrame)
            }
            for row in 0..<3 {
                let y = 6 + row * 6
                fill(ctx, rect: r(0, y, 16, 1), color: Self.zenWoodFrame)
            }

            // Bottom rail (thicker)
            fill(ctx, rect: r(0, 0, 16, 1), color: Self.zenWoodDark)

            // Top rail
            fill(ctx, rect: r(0, 23, 16, 1), color: Self.zenWoodDark)

            // Handle notch
            fill(ctx, rect: r(14, 10, 1, 4), color: Self.zenWoodDark)
        }
    }

    // MARK: - Stone Lantern / Toro (8x14)

    /// Gray stone lantern with warm glow at top.
    func stoneLantern() -> SKTexture {
        drawTexture(width: 8, height: 14) { [self] ctx in
            // Base platform
            fill(ctx, rect: r(1, 0, 6, 2), color: Self.zenStoneGray)
            fill(ctx, rect: r(2, 0, 4, 1), color: Self.zenStoneDark)

            // Pillar
            fill(ctx, rect: r(3, 2, 2, 4), color: Self.zenStoneGray)
            fill(ctx, rect: r(3, 2, 1, 4), color: Self.zenStoneDark) // shadow side

            // Fire box (open sides showing glow)
            fill(ctx, rect: r(1, 6, 6, 3), color: Self.zenStoneGray)
            fill(ctx, rect: r(2, 7, 4, 2), color: Self.zenGlowYellow) // warm glow
            fill(ctx, rect: r(3, 7, 2, 1), color: Self.zenLanternHot) // bright center

            // Roof cap
            fill(ctx, rect: r(0, 9, 8, 2), color: Self.zenStoneDark)
            fill(ctx, rect: r(1, 11, 6, 1), color: Self.zenStoneGray)
            fill(ctx, rect: r(2, 12, 4, 1), color: Self.zenStoneDark)

            // Finial
            fill(ctx, rect: r(3, 12, 2, 1), color: Self.zenStoneGray)
            fill(ctx, rect: r(3, 13, 2, 1), color: Self.zenStoneLight)

            // Highlight
            fill(ctx, rect: r(4, 10, 2, 1), color: Self.zenStoneLight)
        }
    }

    // MARK: - Rock Garden (32x16)

    /// Raked sand pattern with 3 dark stones.
    func rockGarden() -> SKTexture {
        drawTexture(width: 32, height: 16) { [self] ctx in
            // Sand base
            fill(ctx, rect: r(0, 0, 32, 16), color: Self.zenSandBase)

            // Raked parallel lines (horizontal)
            for y in stride(from: 1, to: 16, by: 2) {
                fill(ctx, rect: r(0, y, 32, 1), color: Self.zenSandLines)
            }

            // Stone 1 — large, left
            fill(ctx, rect: r(4, 5, 5, 4), color: Self.zenStoneDark)
            fill(ctx, rect: r(5, 9, 3, 1), color: Self.zenStoneDark)
            fill(ctx, rect: r(5, 4, 3, 1), color: Self.zenStoneDark)
            fill(ctx, rect: r(5, 7, 2, 1), color: Self.zenStoneLight) // highlight
            fill(ctx, rect: r(4, 5, 1, 2), color: Self.zenStoneGray) // mid

            // Sand ripples around stone 1
            fill(ctx, rect: r(3, 4, 1, 6), color: Self.zenSandDark)
            fill(ctx, rect: r(9, 5, 1, 4), color: Self.zenSandDark)

            // Stone 2 — medium, center-right
            fill(ctx, rect: r(16, 7, 4, 3), color: Self.zenStoneDark)
            fill(ctx, rect: r(17, 10, 2, 1), color: Self.zenStoneDark)
            fill(ctx, rect: r(17, 6, 2, 1), color: Self.zenStoneDark)
            fill(ctx, rect: r(17, 8, 1, 1), color: Self.zenStoneLight)

            // Sand ripples around stone 2
            fill(ctx, rect: r(15, 7, 1, 3), color: Self.zenSandDark)
            fill(ctx, rect: r(20, 7, 1, 3), color: Self.zenSandDark)

            // Stone 3 — small, far right
            fill(ctx, rect: r(26, 3, 3, 2), color: Self.zenStoneDark)
            fill(ctx, rect: r(27, 5, 1, 1), color: Self.zenStoneDark)
            fill(ctx, rect: r(27, 3, 1, 1), color: Self.zenStoneLight)

            // Border indication (subtle darker edge)
            fill(ctx, rect: r(0, 0, 32, 1), color: Self.zenSandDark)
            fill(ctx, rect: r(0, 15, 32, 1), color: Self.zenSandDark)
        }
    }

    // MARK: - Cherry Blossom Branch (24x16)

    /// Dark branch with pink/white blossoms.
    func cherryBlossomBranch() -> SKTexture {
        drawTexture(width: 24, height: 16) { [self] ctx in
            // Main branch — diagonal from bottom-left
            fill(ctx, rect: r(0, 6, 4, 2), color: Self.zenBranchBrown)
            fill(ctx, rect: r(4, 7, 4, 2), color: Self.zenBranchBrown)
            fill(ctx, rect: r(8, 8, 4, 2), color: Self.zenBranchBrown)
            fill(ctx, rect: r(12, 9, 4, 2), color: Self.zenBranchBrown)
            fill(ctx, rect: r(16, 10, 4, 2), color: Self.zenBranchBrown)
            fill(ctx, rect: r(20, 10, 3, 1), color: Self.zenBranchBrown)

            // Branch highlights
            fill(ctx, rect: r(2, 7, 2, 1), color: Self.zenBranchLight)
            fill(ctx, rect: r(10, 9, 2, 1), color: Self.zenBranchLight)

            // Upper twig
            fill(ctx, rect: r(6, 10, 1, 2), color: Self.zenBranchBrown)
            fill(ctx, rect: r(14, 11, 1, 2), color: Self.zenBranchBrown)

            // Blossoms — clusters of pink/white
            // Cluster 1 (left)
            fill(ctx, rect: r(1, 9, 3, 2), color: Self.zenBlossomPink)
            fill(ctx, rect: r(2, 11, 2, 1), color: Self.zenBlossomPink)
            fill(ctx, rect: r(2, 10, 1, 1), color: Self.zenBlossomWhite) // center

            // Cluster 2 (mid-left upper)
            fill(ctx, rect: r(5, 12, 3, 2), color: Self.zenBlossomPink)
            fill(ctx, rect: r(6, 14, 1, 1), color: Self.zenBlossomPink)
            fill(ctx, rect: r(6, 13, 1, 1), color: Self.zenBlossomWhite)

            // Cluster 3 (center)
            fill(ctx, rect: r(10, 11, 3, 2), color: Self.zenBlossomPink)
            fill(ctx, rect: r(11, 13, 2, 1), color: Self.zenBlossomPink)
            fill(ctx, rect: r(11, 12, 1, 1), color: Self.zenBlossomWhite)

            // Cluster 4 (right upper)
            fill(ctx, rect: r(14, 13, 3, 2), color: Self.zenBlossomPink)
            fill(ctx, rect: r(15, 15, 1, 1), color: Self.zenBlossomPink)
            fill(ctx, rect: r(15, 14, 1, 1), color: Self.zenBlossomWhite)

            // Cluster 5 (far right)
            fill(ctx, rect: r(19, 12, 3, 2), color: Self.zenBlossomPink)
            fill(ctx, rect: r(20, 12, 1, 1), color: Self.zenBlossomWhite)

            // Falling petals
            fill(ctx, rect: r(8, 3, 1, 1), color: Self.zenBlossomPink)
            fill(ctx, rect: r(16, 5, 1, 1), color: Self.zenBlossomPink)
            fill(ctx, rect: r(3, 2, 1, 1), color: Self.zenBlossomDark)
            fill(ctx, rect: r(21, 7, 1, 1), color: Self.zenBlossomPink)

            // Shadow hints on blossoms
            fill(ctx, rect: r(1, 9, 1, 1), color: Self.zenBlossomDark)
            fill(ctx, rect: r(10, 11, 1, 1), color: Self.zenBlossomDark)
        }
    }

    // MARK: - Tea Set (12x8)

    /// Small teapot and two cups on a tray.
    func teaSet() -> SKTexture {
        drawTexture(width: 12, height: 8) { [self] ctx in
            // Tray
            fill(ctx, rect: r(0, 0, 12, 2), color: Self.zenWoodFrame)
            fill(ctx, rect: r(1, 0, 10, 1), color: Self.zenWoodFrameLight)

            // Teapot body (left side)
            fill(ctx, rect: r(1, 2, 4, 3), color: Self.zenTeapotGreen)
            fill(ctx, rect: r(2, 5, 2, 1), color: Self.zenTeapotGreen) // top
            fill(ctx, rect: r(2, 4, 1, 1), color: Self.zenTeapotDark) // shadow
            // Teapot lid
            fill(ctx, rect: r(2, 6, 2, 1), color: Self.zenTeapotDark)
            fill(ctx, rect: r(2, 7, 2, 1), color: Self.zenTeapotGreen)
            // Teapot spout
            fill(ctx, rect: r(5, 3, 1, 1), color: Self.zenTeapotGreen)
            fill(ctx, rect: r(5, 4, 1, 1), color: Self.zenTeapotDark)
            // Teapot handle
            fill(ctx, rect: r(0, 3, 1, 2), color: Self.zenTeapotDark)

            // Cup 1
            fill(ctx, rect: r(7, 2, 2, 2), color: Self.zenCupWhite)
            fill(ctx, rect: r(7, 2, 2, 1), color: Self.zenCreamDark) // base
            fill(ctx, rect: r(7, 3, 1, 1), color: Self.zenTeaGreen)  // tea inside

            // Cup 2
            fill(ctx, rect: r(10, 2, 2, 2), color: Self.zenCupWhite)
            fill(ctx, rect: r(10, 2, 2, 1), color: Self.zenCreamDark)
            fill(ctx, rect: r(10, 3, 1, 1), color: Self.zenTeaGreen)

            // Steam wisps from teapot
            fill(ctx, rect: r(3, 7, 1, 1), color: Self.zenSmokeFaint)
        }
    }

    // MARK: - Hanging Scroll / Kakejiku (8x20)

    /// Dark paper with calligraphy marks, wood roller at bottom.
    func hangingScroll() -> SKTexture {
        drawTexture(width: 8, height: 20) { [self] ctx in
            // Mounting border (brocade fabric)
            fill(ctx, rect: r(1, 2, 6, 16), color: Self.zenScrollDark)

            // Main paper panel
            fill(ctx, rect: r(2, 3, 4, 14), color: Self.zenScrollPaper)

            // Calligraphy strokes (abstract vertical marks)
            fill(ctx, rect: r(3, 13, 1, 4), color: Self.zenInk)
            fill(ctx, rect: r(4, 12, 1, 3), color: Self.zenInk)
            fill(ctx, rect: r(4, 8, 1, 2), color: Self.zenInk)
            fill(ctx, rect: r(3, 6, 2, 1), color: Self.zenInk)
            fill(ctx, rect: r(3, 9, 1, 1), color: Self.zenInk)

            // Red seal stamp (hanko)
            fill(ctx, rect: r(4, 4, 1, 1), color: Self.zenVermillion)

            // Hanging cord at top
            fill(ctx, rect: r(3, 18, 2, 2), color: Self.zenChimeString)
            fill(ctx, rect: r(4, 19, 1, 1), color: Self.zenChimeDark)

            // Bottom roller (jikusaki)
            fill(ctx, rect: r(0, 1, 8, 2), color: Self.zenRollerWood)
            fill(ctx, rect: r(1, 2, 6, 1), color: Self.zenWoodFrameLight)
            fill(ctx, rect: r(0, 0, 1, 2), color: Self.zenWoodDark) // knob left
            fill(ctx, rect: r(7, 0, 1, 2), color: Self.zenWoodDark) // knob right

            // Top mounting bar
            fill(ctx, rect: r(1, 18, 6, 1), color: Self.zenRollerWood)
        }
    }

    // MARK: - Paper Lantern (8x12)

    /// Warm yellow/orange glow with ribbed paper structure.
    func paperLantern() -> SKTexture {
        drawTexture(width: 8, height: 12) { [self] ctx in
            // Top cap (wood)
            fill(ctx, rect: r(2, 10, 4, 2), color: Self.zenLanternFrame)
            fill(ctx, rect: r(3, 11, 2, 1), color: Self.zenWoodDark)

            // Hanging cord
            fill(ctx, rect: r(3, 11, 2, 1), color: Self.zenChimeString)

            // Lantern body — oval shape
            fill(ctx, rect: r(2, 2, 4, 8), color: Self.zenLanternWarm)
            fill(ctx, rect: r(1, 4, 6, 4), color: Self.zenLanternWarm)

            // Bright center glow
            fill(ctx, rect: r(3, 4, 2, 4), color: Self.zenLanternHot)

            // Ribs (horizontal structural lines)
            fill(ctx, rect: r(1, 4, 6, 1), color: Self.zenLanternRib)
            fill(ctx, rect: r(2, 6, 4, 1), color: Self.zenLanternRib)
            fill(ctx, rect: r(1, 8, 6, 1), color: Self.zenLanternRib)

            // Bottom cap
            fill(ctx, rect: r(2, 1, 4, 1), color: Self.zenLanternFrame)
            fill(ctx, rect: r(3, 0, 2, 1), color: Self.zenLanternFrame) // tassel hook

            // Tassel
            fill(ctx, rect: r(3, 0, 2, 1), color: Self.zenVermillion)
        }
    }

    // MARK: - Bamboo Fountain / Shishi-odoshi (10x10)

    /// Bamboo pipe on pivot with water drops.
    func bambooFountain() -> SKTexture {
        drawTexture(width: 10, height: 10) { [self] ctx in
            // Stone basin
            fill(ctx, rect: r(0, 0, 10, 3), color: Self.zenStoneGray)
            fill(ctx, rect: r(1, 0, 8, 2), color: Self.zenStoneDark)
            fill(ctx, rect: r(2, 1, 6, 1), color: Self.zenWaterBlue)  // water in basin

            // Support posts (bamboo)
            fill(ctx, rect: r(1, 3, 1, 5), color: Self.zenBambooGreen)
            fill(ctx, rect: r(8, 3, 1, 5), color: Self.zenBambooGreen)

            // Cross bar
            fill(ctx, rect: r(1, 7, 8, 1), color: Self.zenBambooDark)

            // Tilting pipe (shishi-odoshi)
            fill(ctx, rect: r(2, 5, 7, 2), color: Self.zenBambooGreen)
            fill(ctx, rect: r(3, 5, 5, 1), color: Self.zenBambooLight) // highlight
            fill(ctx, rect: r(2, 5, 1, 2), color: Self.zenBambooDark)  // mouth end (darker)

            // Pivot point
            fill(ctx, rect: r(5, 5, 1, 2), color: Self.zenWoodDark)

            // Water drops falling from pipe mouth
            fill(ctx, rect: r(2, 4, 1, 1), color: Self.zenWaterDrop)
            fill(ctx, rect: r(3, 3, 1, 1), color: Self.zenWaterDrop)

            // Water spout (incoming)
            fill(ctx, rect: r(8, 8, 2, 2), color: Self.zenBambooGreen)
            fill(ctx, rect: r(9, 7, 1, 1), color: Self.zenWaterDrop)
        }
    }

    // MARK: - Wind Chimes (6x12)

    /// Hanging metal/glass tubes with string.
    func windChimes() -> SKTexture {
        drawTexture(width: 6, height: 12) { [self] ctx in
            // Top hook/ring
            fill(ctx, rect: r(2, 10, 2, 2), color: Self.zenChimeMetal)
            fill(ctx, rect: r(2, 11, 2, 1), color: Self.zenChimeLight)

            // Central disc / wind catcher at top
            fill(ctx, rect: r(1, 9, 4, 1), color: Self.zenChimeMetal)

            // Hanging strings
            fill(ctx, rect: r(0, 3, 1, 6), color: Self.zenChimeString)
            fill(ctx, rect: r(1, 2, 1, 7), color: Self.zenChimeString)
            fill(ctx, rect: r(3, 2, 1, 7), color: Self.zenChimeString)
            fill(ctx, rect: r(4, 3, 1, 6), color: Self.zenChimeString)
            fill(ctx, rect: r(5, 4, 1, 5), color: Self.zenChimeString)

            // Chime tubes (varying heights)
            fill(ctx, rect: r(0, 3, 1, 4), color: Self.zenChimeMetal)
            fill(ctx, rect: r(1, 2, 1, 5), color: Self.zenChimeLight)
            fill(ctx, rect: r(3, 2, 1, 6), color: Self.zenChimeMetal)
            fill(ctx, rect: r(4, 3, 1, 4), color: Self.zenChimeLight)
            fill(ctx, rect: r(5, 4, 1, 3), color: Self.zenChimeMetal)

            // Wind sail (clapper piece) at bottom center
            fill(ctx, rect: r(2, 0, 2, 2), color: Self.zenChimeLight)
            fill(ctx, rect: r(2, 0, 1, 1), color: Self.zenChimeDark) // shadow
        }
    }

    // MARK: - Incense Burner (8x10)

    /// Small bronze bowl on stand with wispy smoke.
    func incenseBurner() -> SKTexture {
        drawTexture(width: 8, height: 10) { [self] ctx in
            // Three legs
            fill(ctx, rect: r(1, 0, 1, 2), color: Self.zenBronzeDark)
            fill(ctx, rect: r(3, 0, 2, 1), color: Self.zenBronzeDark)
            fill(ctx, rect: r(6, 0, 1, 2), color: Self.zenBronzeDark)

            // Bowl body
            fill(ctx, rect: r(1, 2, 6, 3), color: Self.zenBronze)
            fill(ctx, rect: r(0, 3, 8, 2), color: Self.zenBronze)
            fill(ctx, rect: r(2, 2, 4, 1), color: Self.zenBronzeDark) // inner shadow

            // Bowl rim
            fill(ctx, rect: r(0, 5, 8, 1), color: Self.zenBronzeLight)

            // Decorative band
            fill(ctx, rect: r(1, 3, 6, 1), color: Self.zenBronzeLight)

            // Ash bed inside
            fill(ctx, rect: r(2, 5, 4, 1), color: Self.zenStoneGray)

            // Incense stick
            fill(ctx, rect: r(4, 5, 1, 3), color: Self.zenBranchBrown)

            // Smoke wisps
            fill(ctx, rect: r(4, 8, 1, 1), color: Self.zenSmoke)
            fill(ctx, rect: r(3, 9, 1, 1), color: Self.zenSmokeFaint)
            fill(ctx, rect: r(5, 9, 1, 1), color: Self.zenSmokeFaint)
        }
    }

    // MARK: - Zabuton Cushion (12x8)

    /// Flat meditation cushion, deep indigo blue.
    func zabutonCushion() -> SKTexture {
        drawTexture(width: 12, height: 8) { [self] ctx in
            // Cushion body — rounded rectangle feel
            fill(ctx, rect: r(1, 1, 10, 6), color: Self.zenCushionIndigo)
            fill(ctx, rect: r(0, 2, 12, 4), color: Self.zenCushionIndigo)

            // Top surface highlight
            fill(ctx, rect: r(2, 4, 8, 2), color: Self.zenCushionLight)
            fill(ctx, rect: r(3, 6, 6, 1), color: Self.zenCushionLight)

            // Bottom shadow
            fill(ctx, rect: r(1, 1, 10, 1), color: Self.zenCushionDark)
            fill(ctx, rect: r(0, 2, 1, 2), color: Self.zenCushionDark)
            fill(ctx, rect: r(11, 2, 1, 2), color: Self.zenCushionDark)

            // Tufting pattern (subtle stitch lines)
            fill(ctx, rect: r(4, 3, 1, 1), color: Self.zenCushionDark)
            fill(ctx, rect: r(7, 3, 1, 1), color: Self.zenCushionDark)
            fill(ctx, rect: r(4, 5, 1, 1), color: Self.zenCushionDark)
            fill(ctx, rect: r(7, 5, 1, 1), color: Self.zenCushionDark)

            // Corner tassels
            fill(ctx, rect: r(0, 0, 1, 1), color: Self.zenCushionTassel)
            fill(ctx, rect: r(11, 0, 1, 1), color: Self.zenCushionTassel)
            fill(ctx, rect: r(0, 7, 1, 1), color: Self.zenCushionTassel)
            fill(ctx, rect: r(11, 7, 1, 1), color: Self.zenCushionTassel)
        }
    }

    // MARK: - Chabudai Table (60x16)

    /// Low dark wood Japanese table, same dimensions as existing desk
    /// but styled with Japanese dark lacquer and clean lines.
    func chabudaiTable() -> SKTexture {
        drawTexture(width: 60, height: 16) { [self] ctx in
            // Table surface — low profile, dark lacquer
            fill(ctx, rect: r(0, 6, 60, 8), color: Self.zenTableMid)
            fill(ctx, rect: r(0, 14, 60, 2), color: Self.zenTableLight) // top surface highlight
            fill(ctx, rect: r(0, 6, 60, 1), color: Self.zenTableDark)   // front edge shadow

            // Short legs (low table)
            fill(ctx, rect: r(2, 0, 3, 6), color: Self.zenTableDark)
            fill(ctx, rect: r(55, 0, 3, 6), color: Self.zenTableDark)

            // Leg highlights
            fill(ctx, rect: r(3, 1, 1, 4), color: Self.zenTableMid)
            fill(ctx, rect: r(56, 1, 1, 4), color: Self.zenTableMid)

            // Subtle wood grain on surface
            fill(ctx, rect: r(6, 9, 4, 1), color: Self.zenTableHighlight)
            fill(ctx, rect: r(18, 10, 5, 1), color: Self.zenTableHighlight)
            fill(ctx, rect: r(30, 9, 4, 1), color: Self.zenTableHighlight)
            fill(ctx, rect: r(42, 10, 5, 1), color: Self.zenTableHighlight)
            fill(ctx, rect: r(52, 9, 4, 1), color: Self.zenTableHighlight)

            // Edge banding
            fill(ctx, rect: r(0, 6, 1, 10), color: Self.zenTableDark)
            fill(ctx, rect: r(59, 6, 1, 10), color: Self.zenTableDark)
        }
    }
}

// MARK: - TextureManager Zen Studio Constants

extension TextureManager {

    // Zen Studio texture name constants
    public static let zenToriiGate = "zen_torii_gate"
    public static let zenKoiPond = "zen_koi_pond"
    public static let zenBonsaiTree = "zen_bonsai_tree"
    public static let zenShojiScreen = "zen_shoji_screen"
    public static let zenStoneLantern = "zen_stone_lantern"
    public static let zenRockGarden = "zen_rock_garden"
    public static let zenCherryBlossom = "zen_cherry_blossom"
    public static let zenTeaSet = "zen_tea_set"
    public static let zenHangingScroll = "zen_hanging_scroll"
    public static let zenPaperLantern = "zen_paper_lantern"
    public static let zenBambooFountain = "zen_bamboo_fountain"
    public static let zenWindChimes = "zen_wind_chimes"
    public static let zenIncenseBurner = "zen_incense_burner"
    public static let zenZabutonCushion = "zen_zabuton_cushion"
    public static let zenChabudaiTable = "zen_chabudai_table"

    /// All zen studio texture names for validation.
    public static let zenTextureNames: [String] = [
        zenToriiGate, zenKoiPond, zenBonsaiTree, zenShojiScreen,
        zenStoneLantern, zenRockGarden, zenCherryBlossom, zenTeaSet,
        zenHangingScroll, zenPaperLantern, zenBambooFountain, zenWindChimes,
        zenIncenseBurner, zenZabutonCushion, zenChabudaiTable,
    ]
}
