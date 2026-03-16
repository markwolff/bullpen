import SpriteKit
import AppKit
import Models

/// Generates Stardew Valley-style pixel art textures programmatically.
/// All sprites are drawn at low resolution (16x16 to 32x32) with nearest-neighbor
/// filtering for that chunky, charming pixel look.
public final class PixelArtGenerator: Sendable {

    public static let shared = PixelArtGenerator()
    private init() {}

    // MARK: - Stardew Valley Color Palette

    // Warm earth tones
    static let woodDark = RGB(0x5B3A1E)
    static let woodMid = RGB(0x8B6B3D)
    static let woodLight = RGB(0xB89B6A)
    static let woodHighlight = RGB(0xD4BC8E)

    // Wall colors
    static let wallBase = RGB(0xE8DCC8)
    static let wallAccent = RGB(0xD4C4A8)
    static let wallTrim = RGB(0xC4A882)

    // Floor colors
    static let floorDark = RGB(0x9A7B4F)
    static let floorMid = RGB(0xBB9B6B)
    static let floorLight = RGB(0xD4B88A)

    // Character colors - Claude (orange hoodie)
    static let claudeHoodie = RGB(0xE87830)
    static let claudeHoodieDark = RGB(0xC05820)
    static let claudeSkin = RGB(0xF5D0A8)
    static let claudeEye = RGB(0x40E8D0)
    static let claudeEyeDark = RGB(0x30B098)

    // Character colors - Codex (green hoodie)
    static let codexHoodie = RGB(0x40A850)
    static let codexHoodieDark = RGB(0x308838)
    static let codexSkin = RGB(0xF5D0A8)
    static let codexEye = RGB(0x60B0FF)

    // Furniture
    static let monitorFrame = RGB(0x383838)
    static let monitorScreen = RGB(0x203048)
    static let monitorScreenOn = RGB(0x40A0E8)
    static let chairGray = RGB(0x585858)
    static let chairBack = RGB(0x484848)
    static let lampYellow = RGB(0xFFE878)
    static let lampBase = RGB(0x686868)
    static let mugWhite = RGB(0xF0E8D8)
    static let mugBrown = RGB(0x8B5A2B)

    // Decorations
    static let plantGreen = RGB(0x48A848)
    static let plantDark = RGB(0x307030)
    static let potBrown = RGB(0xA06830)
    static let windowFrame = RGB(0xC4A070)
    static let windowGlass = RGB(0x88C8F0)
    static let whiteboardWhite = RGB(0xF0F0F0)
    static let whiteboardFrame = RGB(0xA09080)
    static let clockFace = RGB(0xF8F0E0)
    static let clockFrame = RGB(0x8B7355)

    // Cat
    static let catOrange = RGB(0xE8A040)
    static let catOrangeDark = RGB(0xC88030)
    static let catStripe = RGB(0xD09038)
    static let catEar = RGB(0xF0C0A0)
    static let catNose = RGB(0xF08080)

    // Dog colors - Pancake (apricot Maltipoo)
    static let dogApricot = RGB(0xE8C090)       // Main body - warm apricot
    static let dogApricotLight = RGB(0xF0D8B0)  // Lighter highlights/chest
    static let dogApricotDark = RGB(0xD0A070)   // Darker shading
    static let dogNose = RGB(0x303030)           // Black nose
    static let dogEye = RGB(0x282828)            // Dark eyes
    static let dogTongue = RGB(0xF08080)         // Pink tongue (for panting)

    // Bird cage
    static let cageGold = RGB(0xC8A850)
    static let cageBars = RGB(0xA08840)
    static let cageBase = RGB(0x907830)
    static let birdYellow = RGB(0xF8D830)
    static let birdWing = RGB(0xE8C020)
    static let birdBeak = RGB(0xF08030)
    static let birdEye = RGB(0x282828)

    // Barista
    static let baristaApron = RGB(0x4A7A4A)
    static let baristaApronDark = RGB(0x3A6A3A)
    static let baristaHair = RGB(0x3A2A1A)
    static let baristaSkin = RGB(0xE8C8A0)
    static let baristaSkinDark = RGB(0xD0B088)
    static let espressoMachine = RGB(0x606060)
    static let espressoDark = RGB(0x484848)
    static let counterTop = RGB(0x8B7355)
    static let counterFront = RGB(0x7A6345)

    // Extra decorations
    static let rugWarm = RGB(0xA04040)
    static let rugPattern = RGB(0xC06050)
    static let rugBorder = RGB(0x803030)
    static let coatBlue = RGB(0x4060A0)
    static let coatBrown = RGB(0x8B6B3D)
    static let hookMetal = RGB(0x888888)
    static let posterFrame2 = RGB(0x6A5A4A)
    static let posterArt = RGB(0x50A0D0)

    // MARK: - Tile Textures (16x16)

    func floorTile() -> SKTexture {
        drawTexture(width: 16, height: 16) { [self] ctx in
            // Wood plank floor
            fill(ctx, rect: r(0, 0, 16, 16), color: Self.floorMid)

            // Horizontal plank lines
            fill(ctx, rect: r(0, 4, 16, 1), color: Self.floorDark)
            fill(ctx, rect: r(0, 8, 16, 1), color: Self.floorDark)
            fill(ctx, rect: r(0, 12, 16, 1), color: Self.floorDark)

            // Staggered vertical joints
            fill(ctx, rect: r(5, 0, 1, 4), color: Self.floorDark)
            fill(ctx, rect: r(11, 4, 1, 4), color: Self.floorDark)
            fill(ctx, rect: r(3, 8, 1, 4), color: Self.floorDark)
            fill(ctx, rect: r(9, 12, 1, 4), color: Self.floorDark)

            // Subtle wood grain highlights
            fill(ctx, rect: r(2, 1, 2, 1), color: Self.floorLight)
            fill(ctx, rect: r(8, 5, 2, 1), color: Self.floorLight)
            fill(ctx, rect: r(6, 9, 2, 1), color: Self.floorLight)
            fill(ctx, rect: r(12, 13, 2, 1), color: Self.floorLight)
        }
    }

    func wallTile() -> SKTexture {
        drawTexture(width: 16, height: 16) { [self] ctx in
            // Warm plaster wall
            fill(ctx, rect: r(0, 0, 16, 16), color: Self.wallBase)

            // Subtle texture variation
            fill(ctx, rect: r(3, 2, 2, 1), color: Self.wallAccent)
            fill(ctx, rect: r(10, 6, 3, 1), color: Self.wallAccent)
            fill(ctx, rect: r(5, 11, 2, 1), color: Self.wallAccent)
            fill(ctx, rect: r(12, 14, 2, 1), color: Self.wallAccent)
        }
    }

    // MARK: - Furniture Textures

    func desk() -> SKTexture {
        // 60x16 pixel desk, displayed at 240x64
        drawTexture(width: 60, height: 16) { [self] ctx in
            // Desktop surface
            fill(ctx, rect: r(0, 8, 60, 6), color: Self.woodMid)
            fill(ctx, rect: r(0, 14, 60, 2), color: Self.woodLight) // front edge highlight
            fill(ctx, rect: r(0, 8, 60, 1), color: Self.woodDark)   // back edge

            // Four legs for a longer desk
            fill(ctx, rect: r(2, 0, 2, 8), color: Self.woodDark)
            fill(ctx, rect: r(20, 0, 2, 8), color: Self.woodDark)
            fill(ctx, rect: r(38, 0, 2, 8), color: Self.woodDark)
            fill(ctx, rect: r(56, 0, 2, 8), color: Self.woodDark)

            // Drawer on the left
            fill(ctx, rect: r(8, 2, 5, 5), color: Self.woodMid)
            fill(ctx, rect: r(8, 2, 5, 1), color: Self.woodDark)
            fill(ctx, rect: r(8, 6, 5, 1), color: Self.woodDark)
            fill(ctx, rect: r(10, 4, 1, 1), color: Self.woodHighlight)

            // Drawer on the right
            fill(ctx, rect: r(47, 2, 5, 5), color: Self.woodMid)
            fill(ctx, rect: r(47, 2, 5, 1), color: Self.woodDark)
            fill(ctx, rect: r(47, 6, 5, 1), color: Self.woodDark)
            fill(ctx, rect: r(49, 4, 1, 1), color: Self.woodHighlight)

            // Wood grain on desktop
            fill(ctx, rect: r(4, 10, 3, 1), color: Self.woodHighlight)
            fill(ctx, rect: r(15, 11, 4, 1), color: Self.woodHighlight)
            fill(ctx, rect: r(28, 10, 3, 1), color: Self.woodHighlight)
            fill(ctx, rect: r(40, 11, 4, 1), color: Self.woodHighlight)
            fill(ctx, rect: r(52, 10, 3, 1), color: Self.woodHighlight)
        }
    }

    func chair() -> SKTexture {
        // 12x16 pixel chair
        drawTexture(width: 12, height: 16) { [self] ctx in
            // Seat cushion
            fill(ctx, rect: r(1, 4, 10, 4), color: Self.chairGray)
            fill(ctx, rect: r(2, 5, 8, 2), color: Self.RGB(0x686868)) // highlight

            // Back rest
            fill(ctx, rect: r(2, 8, 8, 6), color: Self.chairBack)
            fill(ctx, rect: r(3, 9, 6, 4), color: Self.chairGray) // inner

            // Wheels/base
            fill(ctx, rect: r(3, 0, 1, 4), color: Self.RGB(0x404040))
            fill(ctx, rect: r(8, 0, 1, 4), color: Self.RGB(0x404040))
            fill(ctx, rect: r(5, 0, 2, 3), color: Self.RGB(0x404040)) // center post

            // Wheel dots
            fill(ctx, rect: r(2, 0, 1, 1), color: Self.RGB(0x303030))
            fill(ctx, rect: r(9, 0, 1, 1), color: Self.RGB(0x303030))
        }
    }

    func monitorOff() -> SKTexture {
        drawTexture(width: 12, height: 10) { [self] ctx in
            fill(ctx, rect: r(0, 3, 12, 7), color: Self.monitorFrame)
            fill(ctx, rect: r(1, 4, 10, 5), color: Self.monitorScreen)
            fill(ctx, rect: r(4, 0, 4, 3), color: Self.monitorFrame)
            fill(ctx, rect: r(3, 0, 6, 1), color: Self.RGB(0x484848))
        }
    }

    func monitorOn() -> SKTexture {
        drawTexture(width: 12, height: 10) { [self] ctx in
            fill(ctx, rect: r(0, 3, 12, 7), color: Self.monitorFrame)
            fill(ctx, rect: r(1, 4, 10, 5), color: Self.monitorScreenOn)
            // Code lines on screen
            fill(ctx, rect: r(2, 7, 4, 1), color: Self.RGB(0x80D0FF))
            fill(ctx, rect: r(2, 5, 6, 1), color: Self.RGB(0xA0FF90))
            fill(ctx, rect: r(3, 6, 3, 1), color: Self.RGB(0xFFE080))
            fill(ctx, rect: r(4, 0, 4, 3), color: Self.monitorFrame)
            fill(ctx, rect: r(3, 0, 6, 1), color: Self.RGB(0x484848))
        }
    }

    func lamp() -> SKTexture {
        drawTexture(width: 8, height: 16) { [self] ctx in
            // Lampshade
            fill(ctx, rect: r(0, 12, 8, 4), color: Self.lampYellow)
            fill(ctx, rect: r(1, 13, 6, 2), color: Self.RGB(0xFFF0A0))
            fill(ctx, rect: r(1, 11, 6, 1), color: Self.RGB(0xFFF8D0))
            // Neck
            fill(ctx, rect: r(3, 4, 2, 8), color: Self.lampBase)
            // Base
            fill(ctx, rect: r(1, 0, 6, 3), color: Self.lampBase)
            fill(ctx, rect: r(2, 1, 4, 1), color: Self.RGB(0x787878))
        }
    }

    func coffeeMug() -> SKTexture {
        drawTexture(width: 8, height: 8) { [self] ctx in
            fill(ctx, rect: r(1, 0, 5, 6), color: Self.mugWhite)
            fill(ctx, rect: r(1, 0, 5, 1), color: Self.RGB(0xD8D0C0))
            fill(ctx, rect: r(2, 4, 3, 2), color: Self.mugBrown)
            fill(ctx, rect: r(6, 2, 2, 3), color: Self.mugWhite)
            fill(ctx, rect: r(7, 3, 1, 1), color: Self.RGB(0xE8E0D0))
        }
    }

    // MARK: - Decoration Textures

    func plant() -> SKTexture {
        drawTexture(width: 12, height: 20) { [self] ctx in
            // Pot
            fill(ctx, rect: r(3, 0, 6, 6), color: Self.potBrown)
            fill(ctx, rect: r(2, 5, 8, 1), color: Self.potBrown)
            fill(ctx, rect: r(4, 1, 4, 1), color: Self.RGB(0xC08040))
            fill(ctx, rect: r(3, 5, 6, 1), color: Self.RGB(0x604020))

            // Leaves
            fill(ctx, rect: r(4, 6, 4, 2), color: Self.plantDark)
            fill(ctx, rect: r(2, 8, 8, 4), color: Self.plantGreen)
            fill(ctx, rect: r(1, 10, 10, 4), color: Self.plantGreen)
            fill(ctx, rect: r(3, 14, 6, 3), color: Self.plantGreen)
            fill(ctx, rect: r(4, 17, 4, 2), color: Self.plantGreen)
            fill(ctx, rect: r(5, 19, 2, 1), color: Self.plantGreen)

            // Highlights
            fill(ctx, rect: r(3, 12, 2, 1), color: Self.RGB(0x60C860))
            fill(ctx, rect: r(7, 10, 2, 1), color: Self.RGB(0x60C860))
            fill(ctx, rect: r(5, 15, 2, 1), color: Self.RGB(0x60C860))

            // Shadows
            fill(ctx, rect: r(2, 9, 2, 1), color: Self.plantDark)
            fill(ctx, rect: r(8, 11, 2, 1), color: Self.plantDark)
        }
    }

    func windowDecoration() -> SKTexture {
        drawTexture(width: 20, height: 16) { [self] ctx in
            fill(ctx, rect: r(0, 0, 20, 16), color: Self.windowFrame)
            // Glass panes (2x2 grid)
            fill(ctx, rect: r(2, 2, 7, 5), color: Self.windowGlass)
            fill(ctx, rect: r(11, 2, 7, 5), color: Self.windowGlass)
            fill(ctx, rect: r(2, 9, 7, 5), color: Self.windowGlass)
            fill(ctx, rect: r(11, 9, 7, 5), color: Self.windowGlass)
            // Reflections
            fill(ctx, rect: r(3, 11, 2, 2), color: Self.RGB(0xA8D8FF))
            fill(ctx, rect: r(12, 11, 2, 2), color: Self.RGB(0xA8D8FF))
            // Cross divider
            fill(ctx, rect: r(9, 0, 2, 16), color: Self.windowFrame)
            fill(ctx, rect: r(0, 7, 20, 2), color: Self.windowFrame)
            // Curtain hints
            fill(ctx, rect: r(0, 2, 1, 12), color: Self.RGB(0xD0A868))
            fill(ctx, rect: r(19, 2, 1, 12), color: Self.RGB(0xD0A868))
        }
    }

    func whiteboard() -> SKTexture {
        drawTexture(width: 24, height: 16) { [self] ctx in
            fill(ctx, rect: r(0, 0, 24, 16), color: Self.whiteboardFrame)
            fill(ctx, rect: r(1, 1, 22, 14), color: Self.whiteboardWhite)
            // Scribbles
            fill(ctx, rect: r(3, 11, 6, 1), color: Self.RGB(0x4080D0))
            fill(ctx, rect: r(3, 9, 8, 1), color: Self.RGB(0x4080D0))
            fill(ctx, rect: r(3, 7, 5, 1), color: Self.RGB(0xD04040))
            fill(ctx, rect: r(14, 8, 4, 4), color: Self.RGB(0x40B060))
            fill(ctx, rect: r(15, 9, 2, 2), color: Self.whiteboardWhite)
            fill(ctx, rect: r(10, 4, 3, 1), color: Self.RGB(0xE0A020))
            // Marker tray
            fill(ctx, rect: r(2, 0, 20, 1), color: Self.RGB(0x908070))
            fill(ctx, rect: r(5, 1, 1, 1), color: Self.RGB(0x4080D0))
            fill(ctx, rect: r(7, 1, 1, 1), color: Self.RGB(0xD04040))
            fill(ctx, rect: r(9, 1, 1, 1), color: Self.RGB(0x40B060))
        }
    }

    func clock() -> SKTexture {
        drawTexture(width: 10, height: 10) { [self] ctx in
            // Frame (circle approximation)
            fill(ctx, rect: r(2, 0, 6, 1), color: Self.clockFrame)
            fill(ctx, rect: r(1, 1, 8, 1), color: Self.clockFrame)
            fill(ctx, rect: r(0, 2, 10, 6), color: Self.clockFrame)
            fill(ctx, rect: r(1, 8, 8, 1), color: Self.clockFrame)
            fill(ctx, rect: r(2, 9, 6, 1), color: Self.clockFrame)
            // Face
            fill(ctx, rect: r(3, 1, 4, 1), color: Self.clockFace)
            fill(ctx, rect: r(2, 2, 6, 1), color: Self.clockFace)
            fill(ctx, rect: r(1, 3, 8, 4), color: Self.clockFace)
            fill(ctx, rect: r(2, 7, 6, 1), color: Self.clockFace)
            fill(ctx, rect: r(3, 8, 4, 1), color: Self.clockFace)
            // Markers
            fill(ctx, rect: r(5, 7, 1, 1), color: Self.clockFrame)
            fill(ctx, rect: r(5, 3, 1, 1), color: Self.clockFrame)
            fill(ctx, rect: r(8, 5, 1, 1), color: Self.clockFrame)
            fill(ctx, rect: r(2, 5, 1, 1), color: Self.clockFrame)
            // Hands
            fill(ctx, rect: r(5, 5, 1, 2), color: Self.RGB(0x303030))
            fill(ctx, rect: r(5, 5, 2, 1), color: Self.RGB(0x303030))
        }
    }

    // MARK: - Character Textures (16x24 pixel art characters)

    /// Generates a character texture from a full trait set.
    func character(traits: CharacterTraits, state: String, frame: Int = 0) -> SKTexture {
        drawTexture(width: 16, height: 24) { [self] ctx in
            self.drawCharacter(ctx,
                         hoodie: Self.RGB(traits.hoodieColor),
                         hoodieDark: Self.RGB(traits.hoodieDarkColor),
                         skin: Self.RGB(traits.skinColor),
                         eyeColor: Self.RGB(traits.eyeColor),
                         eyeDark: Self.RGB(traits.eyeDarkColor),
                         state: state, frame: frame)
            self.drawHair(ctx, style: traits.hairStyle, color: Self.RGB(traits.hairColor))
            self.drawAccessory(ctx, accessory: traits.accessory,
                         skin: Self.RGB(traits.skinColor),
                         hoodie: Self.RGB(traits.hoodieColor))
        }
    }

    func claudeCharacter(state: String) -> SKTexture {
        drawTexture(width: 16, height: 24) { [self] ctx in
            self.drawCharacter(ctx, hoodie: Self.claudeHoodie, hoodieDark: Self.claudeHoodieDark,
                         skin: Self.claudeSkin, eyeColor: Self.claudeEye, eyeDark: Self.claudeEyeDark,
                         state: state)
        }
    }

    func codexCharacter(state: String) -> SKTexture {
        drawTexture(width: 16, height: 24) { [self] ctx in
            self.drawCharacter(ctx, hoodie: Self.codexHoodie, hoodieDark: Self.codexHoodieDark,
                         skin: Self.codexSkin, eyeColor: Self.codexEye, eyeDark: Self.codexEye,
                         state: state)
        }
    }

    private func drawCharacter(_ ctx: CGContext, hoodie: NSColor, hoodieDark: NSColor,
                                skin: NSColor, eyeColor: NSColor, eyeDark: NSColor, state: String, frame: Int = 0) {
        // Head (6x5 at top center)
        fill(ctx, rect: r(5, 16, 6, 5), color: skin)
        fill(ctx, rect: r(5, 21, 6, 2), color: skin) // forehead
        fill(ctx, rect: r(4, 17, 1, 3), color: skin) // left cheek
        fill(ctx, rect: r(11, 17, 1, 3), color: skin) // right cheek

        // Hood
        fill(ctx, rect: r(4, 21, 8, 3), color: hoodie)
        fill(ctx, rect: r(3, 20, 1, 2), color: hoodie)
        fill(ctx, rect: r(12, 20, 1, 2), color: hoodie)

        // Eyes
        fill(ctx, rect: r(6, 19, 2, 2), color: eyeColor)
        fill(ctx, rect: r(9, 19, 2, 2), color: eyeColor)
        fill(ctx, rect: r(6, 19, 1, 1), color: eyeDark)
        fill(ctx, rect: r(9, 19, 1, 1), color: eyeDark)

        // Mouth
        fill(ctx, rect: r(7, 17, 2, 1), color: Self.RGB(0xE0B090))

        // Body (hoodie)
        fill(ctx, rect: r(4, 6, 8, 10), color: hoodie)
        fill(ctx, rect: r(3, 8, 1, 6), color: hoodie)
        fill(ctx, rect: r(12, 8, 1, 6), color: hoodie)

        // Hoodie details
        fill(ctx, rect: r(4, 6, 8, 1), color: hoodieDark)
        fill(ctx, rect: r(7, 12, 2, 3), color: hoodieDark)
        fill(ctx, rect: r(5, 14, 2, 1), color: hoodieDark)
        fill(ctx, rect: r(9, 14, 2, 1), color: hoodieDark)

        // Hands
        fill(ctx, rect: r(3, 7, 1, 2), color: skin)
        fill(ctx, rect: r(12, 7, 1, 2), color: skin)

        // Legs
        fill(ctx, rect: r(5, 2, 3, 4), color: Self.RGB(0x404860))
        fill(ctx, rect: r(8, 2, 3, 4), color: Self.RGB(0x404860))

        // Shoes
        fill(ctx, rect: r(4, 0, 4, 2), color: Self.RGB(0x483828))
        fill(ctx, rect: r(8, 0, 4, 2), color: Self.RGB(0x483828))

        // State-specific details with frame variations
        switch state {
        case "thinking":
            // Hand on chin
            fill(ctx, rect: r(10, 16, 2, 1), color: skin)
            // Sparkle positions shift per frame
            let sparkleOffsets: [(Int, Int)] = [(2, 22), (13, 23), (1, 23), (14, 22)]
            let idx = frame % sparkleOffsets.count
            fill(ctx, rect: r(sparkleOffsets[idx].0, sparkleOffsets[idx].1, 1, 1), color: Self.lampYellow)
            // Second sparkle toggles on odd frames
            if frame % 2 == 1 {
                let idx2 = (idx + 2) % sparkleOffsets.count
                fill(ctx, rect: r(sparkleOffsets[idx2].0, sparkleOffsets[idx2].1, 1, 1), color: Self.lampYellow)
            }
        case "writing", "writingCode":
            // Alternating arm positions per frame — typing motion
            if frame % 2 == 0 {
                fill(ctx, rect: r(2, 9, 2, 1), color: hoodie)
                fill(ctx, rect: r(12, 10, 2, 1), color: hoodie)
                fill(ctx, rect: r(2, 9, 1, 1), color: skin)
                fill(ctx, rect: r(13, 10, 1, 1), color: skin)
            } else {
                fill(ctx, rect: r(2, 10, 2, 1), color: hoodie)
                fill(ctx, rect: r(12, 9, 2, 1), color: hoodie)
                fill(ctx, rect: r(2, 10, 1, 1), color: skin)
                fill(ctx, rect: r(13, 9, 1, 1), color: skin)
            }
        case "reading", "readingFiles":
            // Eyes scan left/right across frames
            let eyeShift = frame % 3
            fill(ctx, rect: r(6 + eyeShift, 20, 2, 1), color: eyeColor)
        case "command", "runningCommand":
            // Terminal cursor blinks
            if frame % 2 == 0 {
                fill(ctx, rect: r(7, 18, 2, 1), color: Self.RGB(0x80FF80))
            } else {
                fill(ctx, rect: r(7, 18, 2, 1), color: Self.RGB(0x40C040))
            }
        case "searching":
            // Eyes shift side to side
            let searchShift = frame % 4
            let leftEyeX = searchShift < 2 ? 7 : 6
            let rightEyeX = searchShift < 2 ? 10 : 9
            fill(ctx, rect: r(leftEyeX, 19, 1, 1), color: eyeColor)
            fill(ctx, rect: r(rightEyeX, 19, 1, 1), color: eyeColor)
        case "waiting", "waitingForInput":
            // Question mark dots animate
            fill(ctx, rect: r(12, 22, 2, 1), color: Self.RGB(0xFFFFFF))
            if frame % 4 < 2 {
                fill(ctx, rect: r(13, 23, 1, 1), color: Self.RGB(0xFFFFFF))
            }
        case "error":
            // Red eyes with flicker intensity
            let redEye = frame % 2 == 0 ? Self.RGB(0xFF4040) : Self.RGB(0xE02020)
            fill(ctx, rect: r(6, 19, 2, 2), color: redEye)
            fill(ctx, rect: r(9, 19, 2, 2), color: redEye)
            // Sweat drop on odd frames
            if frame % 2 == 1 {
                fill(ctx, rect: r(12, 21, 1, 2), color: Self.RGB(0x80C0FF))
            }
        case "finished":
            fill(ctx, rect: r(6, 19, 2, 1), color: hoodieDark)
            fill(ctx, rect: r(9, 19, 2, 1), color: hoodieDark)
            fill(ctx, rect: r(7, 17, 2, 1), color: Self.RGB(0xE08070))
        case "idle":
            // Subtle breathing — body shifts 1px on even frames
            if frame % 4 >= 2 {
                // "Exhale" — tiny highlight shift on hoodie
                fill(ctx, rect: r(5, 12, 6, 1), color: hoodieDark)
            }
        case "supervisingAgents":
            // Arms-crossed pose with eyes shifting per frame
            // Crossed arms over body
            fill(ctx, rect: r(3, 9, 2, 3), color: hoodie)
            fill(ctx, rect: r(11, 9, 2, 3), color: hoodie)
            fill(ctx, rect: r(4, 10, 8, 2), color: hoodieDark) // crossed-arm band
            fill(ctx, rect: r(3, 10, 1, 1), color: skin) // left hand
            fill(ctx, rect: r(12, 10, 1, 1), color: skin) // right hand
            // Eyes shift side to side — watching subagents
            let superviseShift = frame % 4
            let leftEye = superviseShift < 2 ? 6 : 7
            let rightEye = superviseShift < 2 ? 9 : 10
            fill(ctx, rect: r(leftEye, 19, 1, 1), color: eyeColor)
            fill(ctx, rect: r(rightEye, 19, 1, 1), color: eyeColor)
        case "deepThinking":
            // Same as thinking: hand on chin + sparkle
            fill(ctx, rect: r(10, 16, 2, 1), color: skin)
            let dtSparkleOffsets: [(Int, Int)] = [(2, 22), (13, 23), (1, 23), (14, 22)]
            let dtIdx = frame % dtSparkleOffsets.count
            fill(ctx, rect: r(dtSparkleOffsets[dtIdx].0, dtSparkleOffsets[dtIdx].1, 1, 1), color: Self.lampYellow)
            if frame % 2 == 1 {
                let dtIdx2 = (dtIdx + 2) % dtSparkleOffsets.count
                fill(ctx, rect: r(dtSparkleOffsets[dtIdx2].0, dtSparkleOffsets[dtIdx2].1, 1, 1), color: Self.lampYellow)
            }
        default:
            break
        }
    }

    // MARK: - Additional Decoration Textures

    /// Bookshelf decoration — 20x16 pixel art
    func bookshelf() -> SKTexture {
        drawTexture(width: 20, height: 16) { [self] ctx in
            // Shelf frame (dark wood)
            fill(ctx, rect: r(0, 0, 20, 16), color: Self.woodDark)
            fill(ctx, rect: r(1, 1, 18, 14), color: Self.woodMid)

            // Middle shelf
            fill(ctx, rect: r(0, 7, 20, 1), color: Self.woodDark)

            // Top row books
            fill(ctx, rect: r(2, 9, 2, 5), color: Self.RGB(0xC04040)) // red
            fill(ctx, rect: r(4, 10, 2, 4), color: Self.RGB(0x4080C0)) // blue
            fill(ctx, rect: r(6, 9, 3, 5), color: Self.RGB(0x40A060)) // green
            fill(ctx, rect: r(9, 10, 2, 4), color: Self.RGB(0xE0A040)) // gold
            fill(ctx, rect: r(11, 9, 2, 5), color: Self.RGB(0x8060A0)) // purple
            fill(ctx, rect: r(14, 10, 3, 4), color: Self.RGB(0xD07040)) // brown

            // Bottom row books
            fill(ctx, rect: r(2, 2, 3, 4), color: Self.RGB(0x4060A0)) // navy
            fill(ctx, rect: r(5, 1, 2, 5), color: Self.RGB(0xD0A060)) // tan
            fill(ctx, rect: r(7, 2, 2, 4), color: Self.RGB(0xA04040)) // maroon
            fill(ctx, rect: r(10, 1, 3, 5), color: Self.RGB(0x60A080)) // teal
            fill(ctx, rect: r(13, 2, 2, 4), color: Self.RGB(0xC08040)) // orange
            fill(ctx, rect: r(16, 1, 2, 5), color: Self.RGB(0x606080)) // slate

            // Book spines (highlight lines)
            fill(ctx, rect: r(3, 12, 1, 1), color: Self.RGB(0xE06060))
            fill(ctx, rect: r(7, 12, 1, 1), color: Self.RGB(0x60C080))
            fill(ctx, rect: r(11, 4, 1, 1), color: Self.RGB(0x80C0A0))
        }
    }

    /// Bulletin board decoration — 20x14 pixel art
    func bulletinBoard() -> SKTexture {
        drawTexture(width: 20, height: 14) { [self] ctx in
            // Cork board background
            fill(ctx, rect: r(0, 0, 20, 14), color: Self.RGB(0xA08050))
            fill(ctx, rect: r(1, 1, 18, 12), color: Self.RGB(0xC8A868))

            // Wood frame
            fill(ctx, rect: r(0, 0, 20, 1), color: Self.woodDark)
            fill(ctx, rect: r(0, 13, 20, 1), color: Self.woodDark)
            fill(ctx, rect: r(0, 0, 1, 14), color: Self.woodDark)
            fill(ctx, rect: r(19, 0, 1, 14), color: Self.woodDark)

            // Pinned notes
            fill(ctx, rect: r(3, 7, 5, 4), color: Self.RGB(0xFFF8A0)) // yellow sticky
            fill(ctx, rect: r(5, 11, 1, 1), color: Self.RGB(0xE04040)) // red pin
            fill(ctx, rect: r(4, 8, 3, 1), color: Self.RGB(0xB0A060)) // text line

            fill(ctx, rect: r(10, 3, 4, 5), color: Self.RGB(0xA0D0FF)) // blue note
            fill(ctx, rect: r(12, 8, 1, 1), color: Self.RGB(0x40A040)) // green pin
            fill(ctx, rect: r(11, 5, 2, 1), color: Self.RGB(0x6090C0)) // text

            fill(ctx, rect: r(3, 2, 4, 3), color: Self.RGB(0xFFB0C0)) // pink note
            fill(ctx, rect: r(4, 5, 1, 1), color: Self.RGB(0xE0E040)) // yellow pin

            fill(ctx, rect: r(15, 8, 3, 4), color: Self.RGB(0xE0E0E0)) // white card
            fill(ctx, rect: r(16, 12, 1, 1), color: Self.RGB(0x4040E0)) // blue pin
        }
    }

    /// Water cooler decoration — 10x20 pixel art
    func waterCooler() -> SKTexture {
        drawTexture(width: 10, height: 20) { [self] ctx in
            // Bottle (top)
            fill(ctx, rect: r(3, 12, 4, 8), color: Self.RGB(0xC0E0F8))
            fill(ctx, rect: r(4, 13, 2, 6), color: Self.RGB(0xA8D0F0)) // water
            fill(ctx, rect: r(4, 19, 2, 1), color: Self.RGB(0xD8E8F8)) // cap

            // Dispenser body
            fill(ctx, rect: r(1, 4, 8, 8), color: Self.RGB(0xE8E8E8))
            fill(ctx, rect: r(2, 5, 6, 6), color: Self.RGB(0xD0D0D0))

            // Taps
            fill(ctx, rect: r(3, 7, 1, 1), color: Self.RGB(0x4080D0)) // cold
            fill(ctx, rect: r(6, 7, 1, 1), color: Self.RGB(0xD04040)) // hot

            // Drip tray
            fill(ctx, rect: r(2, 4, 6, 1), color: Self.RGB(0xA0A0A0))

            // Stand/legs
            fill(ctx, rect: r(2, 0, 2, 4), color: Self.RGB(0x808080))
            fill(ctx, rect: r(6, 0, 2, 4), color: Self.RGB(0x808080))
            fill(ctx, rect: r(1, 0, 8, 1), color: Self.RGB(0x707070)) // base
        }
    }

    /// "SHIP IT" poster with pixel-art rocket — 14x18 pixel art
    func poster() -> SKTexture {
        drawTexture(width: 14, height: 18) { [self] ctx in
            // Frame border
            fill(ctx, rect: r(0, 0, 14, 18), color: Self.woodLight)
            // Dark interior
            fill(ctx, rect: r(1, 1, 12, 16), color: Self.RGB(0x2A2A3A))

            // "SHIP" text at top — compact 2px-wide letters in cyan
            let cyan = Self.RGB(0x60E0FF)
            // S
            fill(ctx, rect: r(2, 14, 2, 1), color: cyan)
            fill(ctx, rect: r(2, 15, 1, 1), color: cyan)
            fill(ctx, rect: r(2, 16, 2, 1), color: cyan)
            fill(ctx, rect: r(3, 13, 1, 1), color: cyan)
            fill(ctx, rect: r(2, 12, 2, 1), color: cyan)
            // H
            fill(ctx, rect: r(5, 12, 1, 5), color: cyan)
            fill(ctx, rect: r(7, 12, 1, 5), color: cyan)
            fill(ctx, rect: r(6, 14, 1, 1), color: cyan)
            // I
            fill(ctx, rect: r(9, 12, 1, 5), color: cyan)
            // P
            fill(ctx, rect: r(11, 12, 1, 5), color: cyan)
            fill(ctx, rect: r(12, 14, 1, 3), color: cyan)
            fill(ctx, rect: r(11, 14, 2, 1), color: cyan)
            fill(ctx, rect: r(11, 16, 2, 1), color: cyan)

            // "IT" text below — 2px-wide, 5px-tall letters at y=6-10, centered
            // I (serifed: 3px top/bottom bars + 1px stem) at x=4-6
            fill(ctx, rect: r(4, 10, 3, 1), color: cyan)  // top serif
            fill(ctx, rect: r(5, 7, 1, 3), color: cyan)   // vertical stem
            fill(ctx, rect: r(4, 6, 3, 1), color: cyan)   // bottom serif
            // T (3px crossbar + 1px stem) at x=8-10
            fill(ctx, rect: r(8, 10, 3, 1), color: cyan)  // crossbar
            fill(ctx, rect: r(9, 6, 1, 4), color: cyan)   // vertical stem

            // Rocket body (centered, shifted down to y=1-5)
            let white = Self.RGB(0xE0E0E0)
            let red = Self.RGB(0xE04040)
            let orange = Self.RGB(0xFFA030)
            // Nose cone
            fill(ctx, rect: r(7, 5, 1, 1), color: red)
            // Body
            fill(ctx, rect: r(6, 2, 3, 3), color: white)
            // Fins
            fill(ctx, rect: r(5, 2, 1, 2), color: red)
            fill(ctx, rect: r(9, 2, 1, 2), color: red)
            // Flame
            fill(ctx, rect: r(7, 1, 1, 1), color: orange)
        }
    }

    /// Office door — 14x24 pixel art (wooden door with frame and handle)
    func door() -> SKTexture {
        drawTexture(width: 14, height: 24) { [self] ctx in
            // Door frame (darker wood surround)
            fill(ctx, rect: r(0, 0, 14, 24), color: Self.woodDark)

            // Door panel (medium wood)
            fill(ctx, rect: r(2, 0, 10, 22), color: Self.woodMid)

            // Top panel inset
            fill(ctx, rect: r(3, 14, 8, 6), color: Self.woodLight)
            fill(ctx, rect: r(4, 15, 6, 4), color: Self.woodMid)

            // Bottom panel inset
            fill(ctx, rect: r(3, 2, 8, 9), color: Self.woodLight)
            fill(ctx, rect: r(4, 3, 6, 7), color: Self.woodMid)

            // Horizontal divider between panels
            fill(ctx, rect: r(2, 12, 10, 2), color: Self.woodDark)

            // Door handle (brass/gold)
            fill(ctx, rect: r(9, 11, 2, 3), color: Self.RGB(0xD4A847))
            fill(ctx, rect: r(10, 12, 1, 1), color: Self.RGB(0xE8C060)) // highlight

            // Frame shadow on left edge
            fill(ctx, rect: r(1, 0, 1, 22), color: Self.RGB(0x4A2A12))

            // Threshold / floor strip at bottom
            fill(ctx, rect: r(0, 0, 14, 1), color: Self.RGB(0x706050))

            // Transom window above door
            fill(ctx, rect: r(3, 21, 8, 2), color: Self.RGB(0x88C8F0))
            fill(ctx, rect: r(7, 21, 1, 2), color: Self.woodDark) // divider
        }
    }

    // MARK: - Animation Frame Variants

    /// Generates a character texture with per-frame pixel variations for animation.
    /// `frame` is 0-based; frame 0 is the base pose.
    func claudeCharacter(state: String, frame: Int) -> SKTexture {
        drawTexture(width: 16, height: 24) { [self] ctx in
            self.drawCharacter(ctx, hoodie: Self.claudeHoodie, hoodieDark: Self.claudeHoodieDark,
                         skin: Self.claudeSkin, eyeColor: Self.claudeEye, eyeDark: Self.claudeEyeDark,
                         state: state, frame: frame)
        }
    }

    func codexCharacter(state: String, frame: Int) -> SKTexture {
        drawTexture(width: 16, height: 24) { [self] ctx in
            self.drawCharacter(ctx, hoodie: Self.codexHoodie, hoodieDark: Self.codexHoodieDark,
                         skin: Self.codexSkin, eyeColor: Self.codexEye, eyeDark: Self.codexEye,
                         state: state, frame: frame)
        }
    }

    // MARK: - Hair & Accessory Drawing

    /// Draws hair pixels above the hood based on style.
    private func drawHair(_ ctx: CGContext, style: HairStyle, color: NSColor) {
        switch style {
        case .spiky:
            // 3 pointed tufts above hood
            fill(ctx, rect: r(5, 23, 1, 1), color: color)
            fill(ctx, rect: r(7, 23, 2, 1), color: color)
            fill(ctx, rect: r(10, 23, 1, 1), color: color)
        case .long:
            // Hair flowing down sides of hood
            fill(ctx, rect: r(5, 23, 6, 1), color: color)
            fill(ctx, rect: r(3, 19, 1, 3), color: color)
            fill(ctx, rect: r(12, 19, 1, 3), color: color)
        case .curly:
            // Rounded puffs above hood
            fill(ctx, rect: r(5, 23, 2, 1), color: color)
            fill(ctx, rect: r(9, 23, 2, 1), color: color)
            fill(ctx, rect: r(6, 23, 1, 1), color: color)
            fill(ctx, rect: r(10, 23, 1, 1), color: color)
        case .bun:
            // Small bun on top of hood
            fill(ctx, rect: r(7, 23, 2, 1), color: color)
            fill(ctx, rect: r(7, 22, 2, 1), color: color)
        case .buzzcut:
            // Subtle stubble line at hood edge
            fill(ctx, rect: r(5, 22, 6, 1), color: color)
        }
    }

    /// Draws an accessory on the character.
    private func drawAccessory(_ ctx: CGContext, accessory: Accessory, skin: NSColor, hoodie: NSColor) {
        switch accessory {
        case .glasses:
            // Glasses frames across eyes — dark frame color
            let frame = Self.RGB(0x383838)
            // Left lens frame
            fill(ctx, rect: r(5, 19, 4, 1), color: frame)
            fill(ctx, rect: r(5, 21, 4, 1), color: frame)
            fill(ctx, rect: r(5, 19, 1, 3), color: frame)
            fill(ctx, rect: r(8, 19, 1, 3), color: frame)
            // Bridge
            fill(ctx, rect: r(8, 20, 1, 1), color: frame)
            // Right lens frame
            fill(ctx, rect: r(9, 19, 3, 1), color: frame)
            fill(ctx, rect: r(9, 21, 3, 1), color: frame)
            fill(ctx, rect: r(9, 19, 1, 3), color: frame)
            fill(ctx, rect: r(11, 19, 1, 3), color: frame)
        case .headphones:
            // Headband arc over the hood
            let hpColor = Self.RGB(0x484848)
            fill(ctx, rect: r(3, 22, 1, 1), color: hpColor)
            fill(ctx, rect: r(4, 23, 8, 1), color: hpColor)
            fill(ctx, rect: r(12, 22, 1, 1), color: hpColor)
            // Ear cups
            fill(ctx, rect: r(3, 20, 1, 2), color: hpColor)
            fill(ctx, rect: r(12, 20, 1, 2), color: hpColor)
        case .none:
            break
        }
    }

    /// Cat walk with alternating leg frames.
    func catWalk(frame: Int) -> SKTexture {
        drawTexture(width: 12, height: 12) { [self] ctx in
            self.drawCat(ctx, sleeping: false, walking: true, walkFrame: frame)
        }
    }

    /// Cat idle with subtle ear/tail twitch.
    func catIdle(frame: Int) -> SKTexture {
        drawTexture(width: 12, height: 12) { [self] ctx in
            self.drawCat(ctx, sleeping: false, idleFrame: frame)
        }
    }

    /// Cat sleep with breathing animation.
    func catSleep(frame: Int) -> SKTexture {
        drawTexture(width: 12, height: 12) { [self] ctx in
            self.drawCat(ctx, sleeping: true, sleepFrame: frame)
        }
    }

    // MARK: - Barista Textures

    func baristaIdle(frame: Int = 0) -> SKTexture {
        drawTexture(width: 16, height: 24) { [self] ctx in
            // Legs
            fill(ctx, rect: r(5, 0, 3, 6), color: Self.woodDark)
            fill(ctx, rect: r(8, 0, 3, 6), color: Self.woodDark)
            // Apron (long, covers torso and upper legs)
            fill(ctx, rect: r(4, 4, 8, 10), color: Self.baristaApron)
            fill(ctx, rect: r(3, 6, 10, 8), color: Self.baristaApron)
            fill(ctx, rect: r(4, 5, 8, 1), color: Self.baristaApronDark)
            // Arms
            if frame == 0 {
                fill(ctx, rect: r(2, 8, 2, 4), color: Self.baristaSkin)
                fill(ctx, rect: r(12, 8, 2, 4), color: Self.baristaSkin)
            } else {
                // Wiping motion - one arm extended
                fill(ctx, rect: r(2, 8, 2, 4), color: Self.baristaSkin)
                fill(ctx, rect: r(13, 9, 2, 3), color: Self.baristaSkin)
            }
            // Head
            fill(ctx, rect: r(5, 15, 6, 6), color: Self.baristaSkin)
            // Hair
            fill(ctx, rect: r(5, 20, 6, 3), color: Self.baristaHair)
            fill(ctx, rect: r(4, 18, 1, 4), color: Self.baristaHair)
            fill(ctx, rect: r(11, 18, 1, 4), color: Self.baristaHair)
            // Eyes
            fill(ctx, rect: r(6, 17, 1, 1), color: Self.birdEye)
            fill(ctx, rect: r(9, 17, 1, 1), color: Self.birdEye)
            // Mouth (friendly smile)
            fill(ctx, rect: r(7, 15, 2, 1), color: Self.baristaSkinDark)
        }
    }

    func baristaServe() -> SKTexture {
        drawTexture(width: 16, height: 24) { [self] ctx in
            // Same base as idle
            // Legs
            fill(ctx, rect: r(5, 0, 3, 6), color: Self.woodDark)
            fill(ctx, rect: r(8, 0, 3, 6), color: Self.woodDark)
            // Apron
            fill(ctx, rect: r(4, 4, 8, 10), color: Self.baristaApron)
            fill(ctx, rect: r(3, 6, 10, 8), color: Self.baristaApron)
            fill(ctx, rect: r(4, 5, 8, 1), color: Self.baristaApronDark)
            // Arms - one hand out with cup
            fill(ctx, rect: r(2, 8, 2, 4), color: Self.baristaSkin)
            fill(ctx, rect: r(13, 10, 3, 3), color: Self.baristaSkin)
            // Small cup in hand
            fill(ctx, rect: r(14, 12, 2, 3), color: Self.mugWhite)
            fill(ctx, rect: r(14, 14, 2, 1), color: Self.mugBrown)
            // Head
            fill(ctx, rect: r(5, 15, 6, 6), color: Self.baristaSkin)
            // Hair
            fill(ctx, rect: r(5, 20, 6, 3), color: Self.baristaHair)
            fill(ctx, rect: r(4, 18, 1, 4), color: Self.baristaHair)
            fill(ctx, rect: r(11, 18, 1, 4), color: Self.baristaHair)
            // Eyes
            fill(ctx, rect: r(6, 17, 1, 1), color: Self.birdEye)
            fill(ctx, rect: r(9, 17, 1, 1), color: Self.birdEye)
            // Smile
            fill(ctx, rect: r(7, 15, 2, 1), color: Self.baristaSkinDark)
        }
    }

    func coffeeStation() -> SKTexture {
        drawTexture(width: 32, height: 24) { [self] ctx in
            // Counter body
            fill(ctx, rect: r(0, 0, 32, 14), color: Self.counterFront)
            fill(ctx, rect: r(0, 14, 32, 2), color: Self.counterTop)
            // Counter top surface highlight
            fill(ctx, rect: r(1, 15, 30, 1), color: Self.woodHighlight)
            // Espresso machine on counter
            fill(ctx, rect: r(4, 16, 10, 7), color: Self.espressoMachine)
            fill(ctx, rect: r(5, 23, 8, 1), color: Self.espressoDark)
            // Machine details
            fill(ctx, rect: r(6, 18, 3, 2), color: Self.espressoDark)
            fill(ctx, rect: r(7, 19, 1, 1), color: Self.lampYellow) // indicator light
            // Steam nozzle
            fill(ctx, rect: r(8, 16, 2, 1), color: Self.espressoDark)
            // Cup stack on counter
            fill(ctx, rect: r(20, 16, 4, 3), color: Self.mugWhite)
            fill(ctx, rect: r(21, 19, 4, 3), color: Self.mugWhite)
            fill(ctx, rect: r(22, 22, 4, 2), color: Self.mugWhite)
            // Menu board on wall above
            fill(ctx, rect: r(16, 18, 12, 6), color: Self.woodDark)
            fill(ctx, rect: r(17, 19, 10, 4), color: Self.woodMid)
            // Menu text squiggles
            fill(ctx, rect: r(18, 21, 4, 1), color: Self.whiteboardWhite)
            fill(ctx, rect: r(18, 20, 3, 1), color: Self.whiteboardWhite)
        }
    }

    // MARK: - Extra Decoration Textures

    func smallRug() -> SKTexture {
        drawTexture(width: 24, height: 12) { [self] ctx in
            // Border
            fill(ctx, rect: r(0, 0, 24, 12), color: Self.rugBorder)
            // Inner area
            fill(ctx, rect: r(1, 1, 22, 10), color: Self.rugWarm)
            // Pattern - diamond shapes
            fill(ctx, rect: r(6, 3, 2, 2), color: Self.rugPattern)
            fill(ctx, rect: r(11, 5, 2, 2), color: Self.rugPattern)
            fill(ctx, rect: r(16, 3, 2, 2), color: Self.rugPattern)
            fill(ctx, rect: r(8, 7, 2, 2), color: Self.rugPattern)
            fill(ctx, rect: r(14, 7, 2, 2), color: Self.rugPattern)
            // Center motif
            fill(ctx, rect: r(10, 4, 4, 4), color: Self.rugBorder)
            fill(ctx, rect: r(11, 5, 2, 2), color: Self.rugPattern)
        }
    }

    func coatHooks() -> SKTexture {
        drawTexture(width: 20, height: 14) { [self] ctx in
            // Wall-mounted board
            fill(ctx, rect: r(0, 10, 20, 4), color: Self.woodMid)
            fill(ctx, rect: r(0, 10, 20, 1), color: Self.woodDark)
            // Hooks
            fill(ctx, rect: r(3, 8, 1, 3), color: Self.hookMetal)
            fill(ctx, rect: r(10, 8, 1, 3), color: Self.hookMetal)
            fill(ctx, rect: r(17, 8, 1, 3), color: Self.hookMetal)
            // Coat 1 - blue jacket
            fill(ctx, rect: r(1, 2, 5, 7), color: Self.coatBlue)
            fill(ctx, rect: r(2, 1, 3, 2), color: Self.coatBlue)
            // Coat 2 - brown jacket
            fill(ctx, rect: r(8, 3, 5, 6), color: Self.coatBrown)
            fill(ctx, rect: r(9, 2, 3, 2), color: Self.coatBrown)
            // Scarf on hook 3
            fill(ctx, rect: r(16, 4, 3, 5), color: Self.rugWarm)
            fill(ctx, rect: r(15, 6, 2, 3), color: Self.rugWarm)
        }
    }

    func motivationalPoster2() -> SKTexture {
        drawTexture(width: 14, height: 18) { [self] ctx in
            // Frame
            fill(ctx, rect: r(0, 0, 14, 18), color: Self.posterFrame2)
            // Inner white
            fill(ctx, rect: r(1, 1, 12, 16), color: Self.whiteboardWhite)
            // Abstract mountain art
            fill(ctx, rect: r(2, 2, 10, 1), color: Self.plantGreen)
            fill(ctx, rect: r(3, 3, 8, 1), color: Self.plantGreen)
            fill(ctx, rect: r(4, 4, 3, 4), color: Self.posterArt)
            fill(ctx, rect: r(8, 4, 3, 3), color: Self.posterArt)
            // Sun
            fill(ctx, rect: r(9, 10, 3, 3), color: Self.lampYellow)
            fill(ctx, rect: r(10, 13, 1, 1), color: Self.lampYellow)
            // Motivational text squiggle
            fill(ctx, rect: r(3, 8, 8, 1), color: Self.woodDark)
            fill(ctx, rect: r(4, 9, 6, 1), color: Self.woodDark)
        }
    }

    func wallClock(frame: Int = 0) -> SKTexture {
        drawTexture(width: 10, height: 10) { [self] ctx in
            // Circular frame (approximated with rects)
            fill(ctx, rect: r(2, 0, 6, 1), color: Self.clockFrame)
            fill(ctx, rect: r(1, 1, 8, 1), color: Self.clockFrame)
            fill(ctx, rect: r(0, 2, 10, 6), color: Self.clockFrame)
            fill(ctx, rect: r(1, 8, 8, 1), color: Self.clockFrame)
            fill(ctx, rect: r(2, 9, 6, 1), color: Self.clockFrame)
            // Face
            fill(ctx, rect: r(2, 2, 6, 6), color: Self.clockFace)
            fill(ctx, rect: r(3, 1, 4, 1), color: Self.clockFace)
            fill(ctx, rect: r(3, 8, 4, 1), color: Self.clockFace)
            fill(ctx, rect: r(1, 3, 1, 4), color: Self.clockFace)
            fill(ctx, rect: r(8, 3, 1, 4), color: Self.clockFace)
            // Hour markers
            fill(ctx, rect: r(5, 8, 1, 1), color: Self.woodDark) // 12
            fill(ctx, rect: r(7, 5, 1, 1), color: Self.woodDark) // 3
            fill(ctx, rect: r(5, 2, 1, 1), color: Self.woodDark) // 6
            fill(ctx, rect: r(2, 5, 1, 1), color: Self.woodDark) // 9
            // Center dot
            fill(ctx, rect: r(5, 5, 1, 1), color: Self.woodDark)
            // Hands
            if frame == 0 {
                // Hour hand pointing up, minute at 12
                fill(ctx, rect: r(5, 6, 1, 2), color: Self.woodDark)
                fill(ctx, rect: r(5, 6, 1, 2), color: Self.woodDark)
                fill(ctx, rect: r(6, 5, 2, 1), color: Self.espressoMachine)
            } else {
                // Minute hand moved to 3
                fill(ctx, rect: r(5, 6, 1, 2), color: Self.woodDark)
                fill(ctx, rect: r(5, 6, 2, 1), color: Self.espressoMachine)
            }
        }
    }

    // MARK: - Cat Textures (12x12 pixel art)

    func catIdle() -> SKTexture {
        drawTexture(width: 12, height: 12) { [self] ctx in
            self.drawCat(ctx, sleeping: false)
        }
    }

    func catSleep() -> SKTexture {
        drawTexture(width: 12, height: 12) { [self] ctx in
            self.drawCat(ctx, sleeping: true)
        }
    }

    func catWalk() -> SKTexture {
        drawTexture(width: 12, height: 12) { [self] ctx in
            self.drawCat(ctx, sleeping: false, walking: true)
        }
    }

    private func drawCat(_ ctx: CGContext, sleeping: Bool, walking: Bool = false,
                          walkFrame: Int = 0, idleFrame: Int = 0, sleepFrame: Int = 0) {
        // Body
        fill(ctx, rect: r(2, 2, 8, 5), color: Self.catOrange)
        fill(ctx, rect: r(3, 3, 6, 3), color: Self.catOrangeDark)

        // Stripes
        fill(ctx, rect: r(4, 5, 1, 2), color: Self.catStripe)
        fill(ctx, rect: r(7, 5, 1, 2), color: Self.catStripe)

        // Head
        fill(ctx, rect: r(3, 7, 6, 4), color: Self.catOrange)
        fill(ctx, rect: r(4, 8, 4, 3), color: Self.catOrange)

        // Ears
        fill(ctx, rect: r(3, 11, 2, 1), color: Self.catOrange)
        fill(ctx, rect: r(7, 11, 2, 1), color: Self.catOrange)
        fill(ctx, rect: r(3, 11, 1, 1), color: Self.catEar)
        fill(ctx, rect: r(8, 11, 1, 1), color: Self.catEar)

        // Eyes
        if sleeping {
            fill(ctx, rect: r(4, 9, 2, 1), color: Self.RGB(0x303030))
            fill(ctx, rect: r(7, 9, 2, 1), color: Self.RGB(0x303030))
        } else {
            fill(ctx, rect: r(4, 9, 2, 2), color: Self.RGB(0x40A040))
            fill(ctx, rect: r(7, 9, 2, 2), color: Self.RGB(0x40A040))
            fill(ctx, rect: r(5, 9, 1, 1), color: Self.RGB(0x202020))
            fill(ctx, rect: r(8, 9, 1, 1), color: Self.RGB(0x202020))
        }

        // Nose
        fill(ctx, rect: r(6, 8, 1, 1), color: Self.catNose)

        // Tail
        fill(ctx, rect: r(9, 5, 2, 1), color: Self.catOrange)
        fill(ctx, rect: r(10, 6, 2, 1), color: Self.catOrange)
        fill(ctx, rect: r(11, 7, 1, 1), color: Self.catOrangeDark)

        // Legs with frame-based animation
        if walking {
            // Alternate front/back leg positions for walk cycle
            if walkFrame % 2 == 0 {
                fill(ctx, rect: r(3, 0, 2, 2), color: Self.catOrange)
                fill(ctx, rect: r(7, 1, 2, 2), color: Self.catOrange)
                fill(ctx, rect: r(3, 0, 2, 1), color: Self.catEar)
                fill(ctx, rect: r(7, 1, 2, 1), color: Self.catEar)
            } else {
                fill(ctx, rect: r(3, 1, 2, 2), color: Self.catOrange)
                fill(ctx, rect: r(7, 0, 2, 2), color: Self.catOrange)
                fill(ctx, rect: r(3, 1, 2, 1), color: Self.catEar)
                fill(ctx, rect: r(7, 0, 2, 1), color: Self.catEar)
            }
        } else {
            fill(ctx, rect: r(3, 0, 2, 2), color: Self.catOrange)
            fill(ctx, rect: r(7, 0, 2, 2), color: Self.catOrange)
            fill(ctx, rect: r(3, 0, 2, 1), color: Self.catEar)
            fill(ctx, rect: r(7, 0, 2, 1), color: Self.catEar)
        }

        // Idle ear/tail twitch on specific frames
        if !walking && !sleeping && idleFrame % 3 == 1 {
            // Ear twitch — left ear flicks up 1px
            fill(ctx, rect: r(3, 12, 1, 1), color: Self.catOrange)
        }

        // Sleeping breathing — tail curls tighter on even frames
        if sleeping && sleepFrame % 2 == 1 {
            fill(ctx, rect: r(10, 6, 1, 1), color: Self.catOrange)
            fill(ctx, rect: r(11, 7, 1, 1), color: .clear)
        }
    }

    // MARK: - Dog Textures (14x12 pixel art) - Pancake the Maltipoo

    func dogIdle() -> SKTexture {
        drawTexture(width: 14, height: 12) { [self] ctx in
            self.drawDog(ctx, sleeping: false)
        }
    }

    func dogSleep() -> SKTexture {
        drawTexture(width: 14, height: 12) { [self] ctx in
            self.drawDog(ctx, sleeping: true)
        }
    }

    func dogWalk() -> SKTexture {
        drawTexture(width: 14, height: 12) { [self] ctx in
            self.drawDog(ctx, sleeping: false, walking: true)
        }
    }

    func dogWalk(frame: Int) -> SKTexture {
        drawTexture(width: 14, height: 12) { [self] ctx in
            self.drawDog(ctx, sleeping: false, walking: true, walkFrame: frame)
        }
    }

    func dogIdle(frame: Int) -> SKTexture {
        drawTexture(width: 14, height: 12) { [self] ctx in
            self.drawDog(ctx, sleeping: false, idleFrame: frame)
        }
    }

    func dogSleep(frame: Int) -> SKTexture {
        drawTexture(width: 14, height: 12) { [self] ctx in
            self.drawDog(ctx, sleeping: true, sleepFrame: frame)
        }
    }

    func dogEat() -> SKTexture {
        drawTexture(width: 14, height: 12) { [self] ctx in
            self.drawDog(ctx, sleeping: false, eating: true)
        }
    }

    func dogTailWag(frame: Int) -> SKTexture {
        drawTexture(width: 14, height: 12) { [self] ctx in
            self.drawDog(ctx, sleeping: false, wagging: true, wagFrame: frame)
        }
    }

    private func drawDog(_ ctx: CGContext, sleeping: Bool, walking: Bool = false,
                          eating: Bool = false, wagging: Bool = false,
                          walkFrame: Int = 0, idleFrame: Int = 0,
                          sleepFrame: Int = 0, wagFrame: Int = 0) {
        // Fluffy body (maltipoos are round and fluffy)
        fill(ctx, rect: r(3, 2, 8, 5), color: Self.dogApricot)
        fill(ctx, rect: r(2, 3, 10, 3), color: Self.dogApricot)       // Extra width for fluff
        fill(ctx, rect: r(4, 3, 6, 3), color: Self.dogApricotLight)   // Lighter belly/chest

        // Fluffy texture (random highlight pixels for curly fur)
        fill(ctx, rect: r(4, 5, 1, 1), color: Self.dogApricotLight)
        fill(ctx, rect: r(8, 4, 1, 1), color: Self.dogApricotLight)
        fill(ctx, rect: r(6, 6, 1, 1), color: Self.dogApricotDark)

        // Head (round maltipoo head with fluffy cheeks)
        fill(ctx, rect: r(4, 7, 6, 4), color: Self.dogApricot)
        fill(ctx, rect: r(3, 8, 8, 3), color: Self.dogApricot)        // Wider for fluffy cheeks
        fill(ctx, rect: r(5, 8, 4, 2), color: Self.dogApricotLight)   // Lighter face

        // Floppy ears (maltipoos have droopy, fluffy ears)
        fill(ctx, rect: r(3, 9, 2, 3), color: Self.dogApricotDark)
        fill(ctx, rect: r(9, 9, 2, 3), color: Self.dogApricotDark)

        // Fluffy top of head
        fill(ctx, rect: r(5, 11, 4, 1), color: Self.dogApricot)

        // Eyes
        if sleeping {
            // Closed eyes - horizontal lines
            fill(ctx, rect: r(5, 9, 2, 1), color: Self.dogEye)
            fill(ctx, rect: r(8, 9, 2, 1), color: Self.dogEye)
        } else {
            // Open eyes - round and dark
            fill(ctx, rect: r(5, 9, 2, 2), color: Self.dogEye)
            fill(ctx, rect: r(8, 9, 2, 2), color: Self.dogEye)
            // Eye shine
            fill(ctx, rect: r(5, 10, 1, 1), color: Self.RGB(0xFFFFFF))
            fill(ctx, rect: r(8, 10, 1, 1), color: Self.RGB(0xFFFFFF))
        }

        // Nose
        fill(ctx, rect: r(7, 8, 1, 1), color: Self.dogNose)

        // Tongue (when eating or panting on certain idle frames)
        if eating || (!sleeping && idleFrame % 4 == 2) {
            fill(ctx, rect: r(7, 7, 1, 1), color: Self.dogTongue)
        }

        // Tail (fluffy upward curl - maltipoo signature)
        if wagging {
            // Tail wag animation
            if wagFrame % 2 == 0 {
                fill(ctx, rect: r(10, 6, 2, 1), color: Self.dogApricot)
                fill(ctx, rect: r(11, 7, 2, 1), color: Self.dogApricot)
                fill(ctx, rect: r(12, 8, 1, 1), color: Self.dogApricotLight)
            } else {
                fill(ctx, rect: r(10, 6, 2, 1), color: Self.dogApricot)
                fill(ctx, rect: r(11, 7, 1, 1), color: Self.dogApricot)
                fill(ctx, rect: r(11, 8, 1, 1), color: Self.dogApricotLight)
            }
        } else {
            fill(ctx, rect: r(10, 5, 2, 1), color: Self.dogApricot)
            fill(ctx, rect: r(11, 6, 2, 1), color: Self.dogApricot)
            fill(ctx, rect: r(12, 7, 1, 1), color: Self.dogApricotLight)
        }

        // Legs with frame-based animation
        if walking {
            if walkFrame % 2 == 0 {
                fill(ctx, rect: r(4, 0, 2, 2), color: Self.dogApricot)
                fill(ctx, rect: r(8, 1, 2, 2), color: Self.dogApricot)
                fill(ctx, rect: r(4, 0, 2, 1), color: Self.dogApricotDark)
                fill(ctx, rect: r(8, 1, 2, 1), color: Self.dogApricotDark)
            } else {
                fill(ctx, rect: r(4, 1, 2, 2), color: Self.dogApricot)
                fill(ctx, rect: r(8, 0, 2, 2), color: Self.dogApricot)
                fill(ctx, rect: r(4, 1, 2, 1), color: Self.dogApricotDark)
                fill(ctx, rect: r(8, 0, 2, 1), color: Self.dogApricotDark)
            }
        } else if eating {
            // Head down pose - legs slightly apart
            fill(ctx, rect: r(3, 0, 2, 2), color: Self.dogApricot)
            fill(ctx, rect: r(9, 0, 2, 2), color: Self.dogApricot)
            fill(ctx, rect: r(3, 0, 2, 1), color: Self.dogApricotDark)
            fill(ctx, rect: r(9, 0, 2, 1), color: Self.dogApricotDark)
        } else {
            // Standing legs
            fill(ctx, rect: r(4, 0, 2, 2), color: Self.dogApricot)
            fill(ctx, rect: r(8, 0, 2, 2), color: Self.dogApricot)
            fill(ctx, rect: r(4, 0, 2, 1), color: Self.dogApricotDark)
            fill(ctx, rect: r(8, 0, 2, 1), color: Self.dogApricotDark)
        }

        // Idle tail wag on specific frames (subtle)
        if !walking && !sleeping && !wagging && idleFrame % 3 == 1 {
            // Slight tail movement
            fill(ctx, rect: r(12, 7, 1, 1), color: Self.dogApricot)
        }

        // Sleeping breathing - body slightly expands on even frames
        if sleeping && sleepFrame % 2 == 1 {
            fill(ctx, rect: r(2, 4, 1, 1), color: Self.dogApricot)
        }
    }

    // MARK: - Dog Bowl Texture (10x6 pixel art)

    func dogBowl() -> SKTexture {
        drawTexture(width: 10, height: 6) { [self] ctx in
            // Bowl body (metallic silver)
            fill(ctx, rect: r(1, 0, 8, 3), color: Self.RGB(0xB0B0B8))   // Main bowl
            fill(ctx, rect: r(0, 1, 10, 2), color: Self.RGB(0xB0B0B8))  // Wider middle
            fill(ctx, rect: r(2, 3, 6, 1), color: Self.RGB(0xC8C8D0))   // Rim highlight

            // Bowl rim
            fill(ctx, rect: r(1, 3, 8, 1), color: Self.RGB(0x989898))
            fill(ctx, rect: r(0, 2, 1, 1), color: Self.RGB(0x989898))
            fill(ctx, rect: r(9, 2, 1, 1), color: Self.RGB(0x989898))

            // Food inside (kibble brown)
            fill(ctx, rect: r(2, 2, 6, 1), color: Self.RGB(0x8B5A2B))
            fill(ctx, rect: r(3, 3, 4, 1), color: Self.RGB(0xA06830))

            // Shine on bowl
            fill(ctx, rect: r(2, 1, 1, 1), color: Self.RGB(0xD0D0D8))

            // "PANCAKE" text area (just a bone shape decoration)
            fill(ctx, rect: r(4, 0, 2, 1), color: Self.RGB(0xE8C090))   // Bone color accent
        }
    }

    // MARK: - Dog Toy Textures

    /// Red bouncy ball — 8x8 pixel art
    func dogToyBall() -> SKTexture {
        drawTexture(width: 8, height: 8) { [self] ctx in
            // Main ball body (red)
            fill(ctx, rect: r(2, 0, 4, 1), color: Self.RGB(0xC02020))
            fill(ctx, rect: r(1, 1, 6, 1), color: Self.RGB(0xD03030))
            fill(ctx, rect: r(0, 2, 8, 4), color: Self.RGB(0xE03030))
            fill(ctx, rect: r(1, 6, 6, 1), color: Self.RGB(0xD03030))
            fill(ctx, rect: r(2, 7, 4, 1), color: Self.RGB(0xC02020))

            // Shadow on bottom-left
            fill(ctx, rect: r(0, 2, 1, 2), color: Self.RGB(0xA02020))
            fill(ctx, rect: r(1, 1, 1, 1), color: Self.RGB(0xA02020))

            // Highlight on top-right
            fill(ctx, rect: r(4, 5, 2, 1), color: Self.RGB(0xF06060))
            fill(ctx, rect: r(5, 4, 1, 1), color: Self.RGB(0xF08080))
        }
    }

    /// Classic dog bone — 10x6 pixel art
    func dogToyBone() -> SKTexture {
        drawTexture(width: 10, height: 6) { [self] ctx in
            let boneMain = Self.RGB(0xF0E8D0)   // Cream white
            let boneDark = Self.RGB(0xD8C8A8)    // Shading
            let boneHighlight = Self.RGB(0xFFF8E8)  // Highlight

            // Left knob
            fill(ctx, rect: r(0, 0, 2, 2), color: boneMain)
            fill(ctx, rect: r(0, 4, 2, 2), color: boneMain)
            fill(ctx, rect: r(0, 1, 1, 4), color: boneMain)

            // Right knob
            fill(ctx, rect: r(8, 0, 2, 2), color: boneMain)
            fill(ctx, rect: r(8, 4, 2, 2), color: boneMain)
            fill(ctx, rect: r(9, 1, 1, 4), color: boneMain)

            // Center shaft
            fill(ctx, rect: r(2, 1, 6, 4), color: boneMain)

            // Shading on bottom edges
            fill(ctx, rect: r(0, 0, 2, 1), color: boneDark)
            fill(ctx, rect: r(8, 0, 2, 1), color: boneDark)
            fill(ctx, rect: r(2, 1, 6, 1), color: boneDark)

            // Highlight on top
            fill(ctx, rect: r(3, 4, 4, 1), color: boneHighlight)
            fill(ctx, rect: r(0, 5, 2, 1), color: boneHighlight)
            fill(ctx, rect: r(8, 5, 2, 1), color: boneHighlight)
        }
    }

    /// Braided rope toy with colored knots — 12x6 pixel art
    func dogToyRope() -> SKTexture {
        drawTexture(width: 12, height: 6) { [self] ctx in
            let ropeLight = Self.RGB(0xE8D8B0)  // Natural rope color
            let ropeDark = Self.RGB(0xC0A878)    // Rope shading
            let knotBlue = Self.RGB(0x5088D0)    // Blue knot
            let knotRed = Self.RGB(0xD05050)     // Red knot

            // Left knot (blue)
            fill(ctx, rect: r(0, 1, 3, 4), color: knotBlue)
            fill(ctx, rect: r(1, 0, 1, 1), color: knotBlue)
            fill(ctx, rect: r(1, 5, 1, 1), color: knotBlue)

            // Rope body - braided pattern (alternating light/dark)
            fill(ctx, rect: r(3, 2, 6, 2), color: ropeLight)
            fill(ctx, rect: r(3, 2, 1, 1), color: ropeDark)
            fill(ctx, rect: r(5, 2, 1, 1), color: ropeDark)
            fill(ctx, rect: r(7, 2, 1, 1), color: ropeDark)
            fill(ctx, rect: r(4, 3, 1, 1), color: ropeDark)
            fill(ctx, rect: r(6, 3, 1, 1), color: ropeDark)
            fill(ctx, rect: r(8, 3, 1, 1), color: ropeDark)

            // Frayed fibers top and bottom of rope
            fill(ctx, rect: r(4, 1, 1, 1), color: ropeLight)
            fill(ctx, rect: r(6, 4, 1, 1), color: ropeLight)

            // Right knot (red)
            fill(ctx, rect: r(9, 1, 3, 4), color: knotRed)
            fill(ctx, rect: r(10, 0, 1, 1), color: knotRed)
            fill(ctx, rect: r(10, 5, 1, 1), color: knotRed)
        }
    }

    // MARK: - Laptop Desk Textures

    /// Laptop desk — 16x10 pixel art, compact startup-style desk
    func laptopDesk() -> SKTexture {
        drawTexture(width: 16, height: 10) { [self] ctx in
            // Desktop surface
            fill(ctx, rect: r(0, 4, 16, 5), color: Self.woodMid)
            fill(ctx, rect: r(0, 9, 16, 1), color: Self.woodLight) // front edge
            fill(ctx, rect: r(0, 4, 16, 1), color: Self.woodDark) // back edge
            // Two legs
            fill(ctx, rect: r(1, 0, 2, 4), color: Self.woodDark)
            fill(ctx, rect: r(13, 0, 2, 4), color: Self.woodDark)
            // Wood grain
            fill(ctx, rect: r(4, 6, 3, 1), color: Self.woodHighlight)
            fill(ctx, rect: r(10, 7, 3, 1), color: Self.woodHighlight)
        }
    }

    /// Long communal table — 80x10 pixel art, tiled wood surface with legs at ends
    func longTable() -> SKTexture {
        drawTexture(width: 80, height: 10) { [self] ctx in
            // Table surface
            fill(ctx, rect: r(0, 4, 80, 5), color: Self.woodMid)
            fill(ctx, rect: r(0, 9, 80, 1), color: Self.woodLight) // front edge
            fill(ctx, rect: r(0, 4, 80, 1), color: Self.woodDark)  // back edge
            // Four legs
            fill(ctx, rect: r(1, 0, 2, 4), color: Self.woodDark)
            fill(ctx, rect: r(26, 0, 2, 4), color: Self.woodDark)
            fill(ctx, rect: r(52, 0, 2, 4), color: Self.woodDark)
            fill(ctx, rect: r(77, 0, 2, 4), color: Self.woodDark)
            // Wood grain highlights
            fill(ctx, rect: r(5, 6, 4, 1), color: Self.woodHighlight)
            fill(ctx, rect: r(15, 7, 3, 1), color: Self.woodHighlight)
            fill(ctx, rect: r(28, 6, 4, 1), color: Self.woodHighlight)
            fill(ctx, rect: r(38, 7, 3, 1), color: Self.woodHighlight)
            fill(ctx, rect: r(50, 6, 4, 1), color: Self.woodHighlight)
            fill(ctx, rect: r(62, 7, 3, 1), color: Self.woodHighlight)
            fill(ctx, rect: r(70, 6, 4, 1), color: Self.woodHighlight)
        }
    }

    /// Open laptop with code on screen — 10x8 pixel art, silver aluminum body
    func laptopOn() -> SKTexture {
        drawTexture(width: 10, height: 8) { [self] ctx in
            // Screen bezel (silver)
            fill(ctx, rect: r(0, 3, 10, 5), color: Self.RGB(0xB0B8C0))
            fill(ctx, rect: r(0, 7, 10, 1), color: Self.RGB(0x909898)) // top edge shadow
            // Screen content
            fill(ctx, rect: r(1, 4, 8, 3), color: Self.monitorScreenOn)
            // Code lines
            fill(ctx, rect: r(2, 6, 4, 1), color: Self.RGB(0x80D0FF))
            fill(ctx, rect: r(2, 5, 5, 1), color: Self.RGB(0xA0FF90))
            fill(ctx, rect: r(3, 4, 3, 1), color: Self.RGB(0xFFE080))
            // Keyboard base (silver)
            fill(ctx, rect: r(0, 0, 10, 3), color: Self.RGB(0xC0C8D0))
            fill(ctx, rect: r(1, 1, 8, 1), color: Self.RGB(0xA8B0B8)) // key area
            fill(ctx, rect: r(0, 0, 10, 1), color: Self.RGB(0x909898)) // front edge
        }
    }

    /// Closed/dark laptop — 10x8 pixel art, silver aluminum body
    func laptopOff() -> SKTexture {
        drawTexture(width: 10, height: 8) { [self] ctx in
            // Screen bezel (silver)
            fill(ctx, rect: r(0, 3, 10, 5), color: Self.RGB(0xB0B8C0))
            fill(ctx, rect: r(0, 7, 10, 1), color: Self.RGB(0x909898)) // top edge shadow
            // Screen (dark/off)
            fill(ctx, rect: r(1, 4, 8, 3), color: Self.monitorScreen)
            // Keyboard base (silver)
            fill(ctx, rect: r(0, 0, 10, 3), color: Self.RGB(0xC0C8D0))
            fill(ctx, rect: r(1, 1, 8, 1), color: Self.RGB(0xA8B0B8)) // key area
            fill(ctx, rect: r(0, 0, 10, 1), color: Self.RGB(0x909898)) // front edge
        }
    }

    /// Laptop screensaver — 10x8 pixel art, silver aluminum body with colorful pattern
    func laptopScreensaver() -> SKTexture {
        drawTexture(width: 10, height: 8) { [self] ctx in
            // Screen bezel (silver)
            fill(ctx, rect: r(0, 3, 10, 5), color: Self.RGB(0xB0B8C0))
            fill(ctx, rect: r(0, 7, 10, 1), color: Self.RGB(0x909898)) // top edge shadow
            // Screen with screensaver
            fill(ctx, rect: r(1, 4, 8, 3), color: Self.RGB(0x203048))
            // Colorful bouncing pattern
            fill(ctx, rect: r(2, 6, 3, 1), color: Self.RGB(0xFF6080))
            fill(ctx, rect: r(5, 4, 3, 1), color: Self.RGB(0x60D0FF))
            // Keyboard base (silver)
            fill(ctx, rect: r(0, 0, 10, 3), color: Self.RGB(0xC0C8D0))
            fill(ctx, rect: r(1, 1, 8, 1), color: Self.RGB(0xA8B0B8)) // key area
            fill(ctx, rect: r(0, 0, 10, 1), color: Self.RGB(0x909898)) // front edge
        }
    }

    /// Lounge couch — 20x12 pixel art
    func couch() -> SKTexture {
        drawTexture(width: 20, height: 12) { [self] ctx in
            // Couch body
            fill(ctx, rect: r(2, 2, 16, 6), color: Self.RGB(0x6B4C3B))
            fill(ctx, rect: r(3, 3, 14, 4), color: Self.RGB(0x8B6B4F))
            // Armrests
            fill(ctx, rect: r(0, 2, 3, 8), color: Self.RGB(0x5B3C2B))
            fill(ctx, rect: r(17, 2, 3, 8), color: Self.RGB(0x5B3C2B))
            // Back
            fill(ctx, rect: r(2, 8, 16, 4), color: Self.RGB(0x5B3C2B))
            fill(ctx, rect: r(3, 9, 14, 2), color: Self.RGB(0x6B4C3B))
            // Cushions (dividing line)
            fill(ctx, rect: r(10, 3, 1, 4), color: Self.RGB(0x7B5C3F))
            // Legs
            fill(ctx, rect: r(3, 0, 2, 2), color: Self.woodDark)
            fill(ctx, rect: r(15, 0, 2, 2), color: Self.woodDark)
        }
    }

    /// Printer — 10x10 pixel art
    func printer() -> SKTexture {
        drawTexture(width: 10, height: 10) { [self] ctx in
            // Body
            fill(ctx, rect: r(0, 1, 10, 7), color: Self.RGB(0xD8D8D8))
            fill(ctx, rect: r(1, 2, 8, 5), color: Self.RGB(0xE8E8E8))
            // Paper tray slot
            fill(ctx, rect: r(2, 7, 6, 2), color: Self.RGB(0xC0C0C0))
            fill(ctx, rect: r(3, 8, 4, 1), color: Self.RGB(0xF0F0F0)) // paper edge
            // Control panel
            fill(ctx, rect: r(6, 4, 3, 2), color: Self.RGB(0x404040))
            fill(ctx, rect: r(7, 5, 1, 1), color: Self.RGB(0x40D040)) // green LED
            // Output tray
            fill(ctx, rect: r(1, 0, 8, 1), color: Self.RGB(0xC0C0C0))
        }
    }

    /// Coat rack — 6x16 pixel art
    func coatRack() -> SKTexture {
        drawTexture(width: 6, height: 16) { [self] ctx in
            // Pole
            fill(ctx, rect: r(2, 0, 2, 14), color: Self.woodDark)
            // Base
            fill(ctx, rect: r(0, 0, 6, 2), color: Self.woodDark)
            fill(ctx, rect: r(1, 1, 4, 1), color: Self.woodMid)
            // Top knob
            fill(ctx, rect: r(2, 14, 2, 2), color: Self.woodMid)
            // Hooks
            fill(ctx, rect: r(0, 11, 2, 1), color: Self.RGB(0x808080))
            fill(ctx, rect: r(4, 11, 2, 1), color: Self.RGB(0x808080))
            fill(ctx, rect: r(0, 8, 2, 1), color: Self.RGB(0x808080))
            fill(ctx, rect: r(4, 8, 2, 1), color: Self.RGB(0x808080))
            // Hanging jacket
            fill(ctx, rect: r(4, 9, 2, 3), color: Self.RGB(0x3850A0))
        }
    }

    // MARK: - Item Textures

    /// Sticky note — 4x4 pixel art
    func stickyNote(color: NSColor) -> SKTexture {
        drawTexture(width: 4, height: 4) { [self] ctx in
            fill(ctx, rect: r(0, 0, 4, 4), color: color)
            // Fold corner
            fill(ctx, rect: r(3, 3, 1, 1), color: Self.RGB(0xD0D0D0))
            // Text line
            fill(ctx, rect: r(0, 2, 3, 1), color: Self.RGB(0x909090))
        }
    }

    /// Crumpled paper — 5x4 pixel art
    func crumpledPaper() -> SKTexture {
        drawTexture(width: 5, height: 4) { [self] ctx in
            fill(ctx, rect: r(1, 0, 3, 3), color: Self.RGB(0xF0EDE0))
            fill(ctx, rect: r(0, 1, 4, 2), color: Self.RGB(0xE8E4D8))
            fill(ctx, rect: r(2, 3, 2, 1), color: Self.RGB(0xF0EDE0))
            // Crumple lines
            fill(ctx, rect: r(1, 1, 1, 1), color: Self.RGB(0xD0CCC0))
            fill(ctx, rect: r(3, 2, 1, 1), color: Self.RGB(0xD0CCC0))
        }
    }

    /// Rubber duck — 8x8 pixel art
    func rubberDuck() -> SKTexture {
        drawTexture(width: 8, height: 8) { [self] ctx in
            // Body
            fill(ctx, rect: r(2, 0, 4, 4), color: Self.RGB(0xFFD700))
            fill(ctx, rect: r(1, 1, 6, 3), color: Self.RGB(0xFFD700))
            // Head
            fill(ctx, rect: r(4, 4, 3, 3), color: Self.RGB(0xFFD700))
            fill(ctx, rect: r(3, 5, 4, 2), color: Self.RGB(0xFFD700))
            // Beak
            fill(ctx, rect: r(7, 5, 1, 2), color: Self.RGB(0xFF8C00))
            // Eye
            fill(ctx, rect: r(5, 6, 1, 1), color: Self.RGB(0x202020))
            // Wing highlight
            fill(ctx, rect: r(2, 2, 2, 1), color: Self.RGB(0xFFE44D))
            // Belly shadow
            fill(ctx, rect: r(2, 0, 4, 1), color: Self.RGB(0xE6C200))
        }
    }

    /// Small coffee cup — 6x6 pixel art
    func coffeeCupSmall() -> SKTexture {
        drawTexture(width: 6, height: 6) { [self] ctx in
            // Cup body
            fill(ctx, rect: r(1, 0, 4, 4), color: Self.RGB(0xF0F0F0))
            // Sleeve
            fill(ctx, rect: r(1, 1, 4, 2), color: Self.RGB(0x8B5A2B))
            // Lid
            fill(ctx, rect: r(0, 4, 6, 2), color: Self.RGB(0xE0D8C8))
            fill(ctx, rect: r(2, 5, 2, 1), color: Self.RGB(0x8B5A2B)) // sip hole
            // Handle
            fill(ctx, rect: r(5, 2, 1, 2), color: Self.RGB(0xF0F0F0))
        }
    }

    /// Pizza box — 10x6 pixel art
    func pizzaBox() -> SKTexture {
        drawTexture(width: 10, height: 6) { [self] ctx in
            // Box
            fill(ctx, rect: r(0, 0, 10, 5), color: Self.RGB(0xC8A870))
            fill(ctx, rect: r(1, 1, 8, 3), color: Self.RGB(0xD4B880))
            // Top edge
            fill(ctx, rect: r(0, 5, 10, 1), color: Self.RGB(0xB09060))
            // Logo circle
            fill(ctx, rect: r(4, 2, 3, 2), color: Self.RGB(0xD04040))
            fill(ctx, rect: r(5, 3, 1, 1), color: Self.RGB(0xF0F0F0))
            // Box crease
            fill(ctx, rect: r(0, 3, 10, 1), color: Self.RGB(0xB89B6A))
        }
    }

    // MARK: - NPC Textures

    /// Janitor NPC — 16x24 pixel art (gray uniform, broom)
    func janitorNPC() -> SKTexture {
        drawTexture(width: 16, height: 24) { [self] ctx in
            // Head
            fill(ctx, rect: r(5, 16, 6, 5), color: Self.RGB(0xF5D0A8))
            fill(ctx, rect: r(5, 21, 6, 2), color: Self.RGB(0xF5D0A8))
            fill(ctx, rect: r(4, 17, 1, 3), color: Self.RGB(0xF5D0A8))
            fill(ctx, rect: r(11, 17, 1, 3), color: Self.RGB(0xF5D0A8))
            // Cap
            fill(ctx, rect: r(4, 21, 8, 3), color: Self.RGB(0x606060))
            fill(ctx, rect: r(3, 21, 10, 1), color: Self.RGB(0x505050))
            // Eyes
            fill(ctx, rect: r(6, 19, 2, 2), color: Self.RGB(0x404040))
            fill(ctx, rect: r(9, 19, 2, 2), color: Self.RGB(0x404040))
            // Mouth
            fill(ctx, rect: r(7, 17, 2, 1), color: Self.RGB(0xE0B090))
            // Body (gray uniform)
            fill(ctx, rect: r(4, 6, 8, 10), color: Self.RGB(0x808080))
            fill(ctx, rect: r(3, 8, 1, 6), color: Self.RGB(0x808080))
            fill(ctx, rect: r(12, 8, 1, 6), color: Self.RGB(0x808080))
            // Uniform details
            fill(ctx, rect: r(4, 6, 8, 1), color: Self.RGB(0x707070))
            fill(ctx, rect: r(7, 10, 2, 3), color: Self.RGB(0x707070))
            // Hands
            fill(ctx, rect: r(3, 7, 1, 2), color: Self.RGB(0xF5D0A8))
            fill(ctx, rect: r(12, 7, 1, 2), color: Self.RGB(0xF5D0A8))
            // Broom (held in right hand)
            fill(ctx, rect: r(13, 4, 1, 12), color: Self.RGB(0x8B6B3D))
            fill(ctx, rect: r(12, 2, 3, 3), color: Self.RGB(0xA0A060))
            // Legs
            fill(ctx, rect: r(5, 2, 3, 4), color: Self.RGB(0x505050))
            fill(ctx, rect: r(8, 2, 3, 4), color: Self.RGB(0x505050))
            // Shoes
            fill(ctx, rect: r(4, 0, 4, 2), color: Self.RGB(0x303030))
            fill(ctx, rect: r(8, 0, 4, 2), color: Self.RGB(0x303030))
        }
    }

    /// Pizza delivery NPC — 16x24 pixel art (red cap, pizza box)
    func pizzaDeliveryNPC() -> SKTexture {
        drawTexture(width: 16, height: 24) { [self] ctx in
            // Head
            fill(ctx, rect: r(5, 16, 6, 5), color: Self.RGB(0xF5D0A8))
            fill(ctx, rect: r(5, 21, 6, 2), color: Self.RGB(0xF5D0A8))
            fill(ctx, rect: r(4, 17, 1, 3), color: Self.RGB(0xF5D0A8))
            fill(ctx, rect: r(11, 17, 1, 3), color: Self.RGB(0xF5D0A8))
            // Red cap
            fill(ctx, rect: r(4, 21, 8, 3), color: Self.RGB(0xD04040))
            fill(ctx, rect: r(3, 21, 10, 1), color: Self.RGB(0xC03030))
            // Eyes
            fill(ctx, rect: r(6, 19, 2, 2), color: Self.RGB(0x404040))
            fill(ctx, rect: r(9, 19, 2, 2), color: Self.RGB(0x404040))
            // Mouth
            fill(ctx, rect: r(7, 17, 2, 1), color: Self.RGB(0xE0B090))
            // Body (blue shirt)
            fill(ctx, rect: r(4, 6, 8, 10), color: Self.RGB(0x4060A0))
            fill(ctx, rect: r(3, 8, 1, 6), color: Self.RGB(0x4060A0))
            fill(ctx, rect: r(12, 8, 1, 6), color: Self.RGB(0x4060A0))
            // Shirt details
            fill(ctx, rect: r(4, 6, 8, 1), color: Self.RGB(0x305090))
            // Hands carrying pizza box
            fill(ctx, rect: r(2, 9, 2, 2), color: Self.RGB(0xF5D0A8))
            fill(ctx, rect: r(12, 9, 2, 2), color: Self.RGB(0xF5D0A8))
            // Pizza box being carried
            fill(ctx, rect: r(1, 8, 14, 2), color: Self.RGB(0xC8A870))
            fill(ctx, rect: r(2, 9, 12, 1), color: Self.RGB(0xD4B880))
            // Legs
            fill(ctx, rect: r(5, 2, 3, 4), color: Self.RGB(0x404860))
            fill(ctx, rect: r(8, 2, 3, 4), color: Self.RGB(0x404860))
            // Shoes
            fill(ctx, rect: r(4, 0, 4, 2), color: Self.RGB(0x483828))
            fill(ctx, rect: r(8, 0, 4, 2), color: Self.RGB(0x483828))
        }
    }

    // MARK: - Plant Growth Stage Textures

    /// Plant seedling — 8x10 pixel art
    func plantSeedling() -> SKTexture {
        drawTexture(width: 8, height: 10) { [self] ctx in
            // Pot
            fill(ctx, rect: r(2, 0, 4, 3), color: Self.potBrown)
            fill(ctx, rect: r(1, 2, 6, 1), color: Self.potBrown)
            // Soil
            fill(ctx, rect: r(2, 3, 4, 1), color: Self.RGB(0x604020))
            // Small sprout
            fill(ctx, rect: r(4, 4, 1, 3), color: Self.plantDark)
            fill(ctx, rect: r(3, 6, 3, 2), color: Self.plantGreen)
            fill(ctx, rect: r(4, 8, 1, 2), color: Self.plantGreen)
        }
    }

    /// Small plant — 8x14 pixel art
    func plantSmall() -> SKTexture {
        drawTexture(width: 8, height: 14) { [self] ctx in
            // Pot
            fill(ctx, rect: r(2, 0, 4, 4), color: Self.potBrown)
            fill(ctx, rect: r(1, 3, 6, 1), color: Self.potBrown)
            fill(ctx, rect: r(2, 3, 4, 1), color: Self.RGB(0x604020))
            // Stem
            fill(ctx, rect: r(4, 4, 1, 4), color: Self.plantDark)
            // Leaves
            fill(ctx, rect: r(2, 7, 5, 3), color: Self.plantGreen)
            fill(ctx, rect: r(3, 10, 3, 2), color: Self.plantGreen)
            fill(ctx, rect: r(4, 12, 1, 2), color: Self.plantGreen)
            // Highlights
            fill(ctx, rect: r(3, 9, 1, 1), color: Self.RGB(0x60C860))
        }
    }

    /// Medium plant — 10x18 pixel art
    func plantMedium() -> SKTexture {
        drawTexture(width: 10, height: 18) { [self] ctx in
            // Pot
            fill(ctx, rect: r(3, 0, 4, 5), color: Self.potBrown)
            fill(ctx, rect: r(2, 4, 6, 1), color: Self.potBrown)
            fill(ctx, rect: r(3, 4, 4, 1), color: Self.RGB(0x604020))
            // Stem
            fill(ctx, rect: r(5, 5, 1, 5), color: Self.plantDark)
            // Leaves
            fill(ctx, rect: r(2, 9, 7, 3), color: Self.plantGreen)
            fill(ctx, rect: r(1, 11, 8, 3), color: Self.plantGreen)
            fill(ctx, rect: r(3, 14, 5, 2), color: Self.plantGreen)
            fill(ctx, rect: r(4, 16, 3, 2), color: Self.plantGreen)
            // Highlights
            fill(ctx, rect: r(3, 12, 2, 1), color: Self.RGB(0x60C860))
            fill(ctx, rect: r(7, 11, 1, 1), color: Self.RGB(0x60C860))
        }
    }

    /// Large plant — 12x22 pixel art
    func plantLarge() -> SKTexture {
        drawTexture(width: 12, height: 22) { [self] ctx in
            // Same structure as the existing plant() method
            // Pot
            fill(ctx, rect: r(3, 0, 6, 6), color: Self.potBrown)
            fill(ctx, rect: r(2, 5, 8, 1), color: Self.potBrown)
            fill(ctx, rect: r(4, 1, 4, 1), color: Self.RGB(0xC08040))
            fill(ctx, rect: r(3, 5, 6, 1), color: Self.RGB(0x604020))
            // Leaves
            fill(ctx, rect: r(4, 6, 4, 2), color: Self.plantDark)
            fill(ctx, rect: r(2, 8, 8, 4), color: Self.plantGreen)
            fill(ctx, rect: r(1, 10, 10, 4), color: Self.plantGreen)
            fill(ctx, rect: r(3, 14, 6, 3), color: Self.plantGreen)
            fill(ctx, rect: r(4, 17, 4, 3), color: Self.plantGreen)
            fill(ctx, rect: r(5, 20, 2, 2), color: Self.plantGreen)
            // Highlights
            fill(ctx, rect: r(3, 12, 2, 1), color: Self.RGB(0x60C860))
            fill(ctx, rect: r(7, 10, 2, 1), color: Self.RGB(0x60C860))
            fill(ctx, rect: r(5, 15, 2, 1), color: Self.RGB(0x60C860))
            // Shadows
            fill(ctx, rect: r(2, 9, 2, 1), color: Self.plantDark)
            fill(ctx, rect: r(8, 11, 2, 1), color: Self.plantDark)
        }
    }

    // MARK: - Overlay Textures

    /// Sleepy eye overlay — 16x6 pixel art (semi-transparent droopy eyelids)
    func sleepyEyeOverlay() -> SKTexture {
        drawTexture(width: 16, height: 6) { [self] ctx in
            let eyelid = Self.RGB(0xF5D0A8).withAlphaComponent(0.7)
            // Left eyelid (drooping down)
            fill(ctx, rect: r(4, 3, 4, 3), color: eyelid)
            // Right eyelid
            fill(ctx, rect: r(9, 3, 4, 3), color: eyelid)
        }
    }

    // MARK: - Radio Texture

    /// Office radio — 10x8 pixel art
    func officeRadio() -> SKTexture {
        drawTexture(width: 10, height: 8) { [self] ctx in
            // Body
            fill(ctx, rect: r(0, 0, 10, 7), color: Self.RGB(0x484848))
            fill(ctx, rect: r(1, 1, 8, 5), color: Self.RGB(0x585858))
            // Speaker grille dots
            fill(ctx, rect: r(2, 2, 1, 1), color: Self.RGB(0x404040))
            fill(ctx, rect: r(4, 2, 1, 1), color: Self.RGB(0x404040))
            fill(ctx, rect: r(6, 2, 1, 1), color: Self.RGB(0x404040))
            fill(ctx, rect: r(2, 4, 1, 1), color: Self.RGB(0x404040))
            fill(ctx, rect: r(4, 4, 1, 1), color: Self.RGB(0x404040))
            fill(ctx, rect: r(6, 4, 1, 1), color: Self.RGB(0x404040))
            // Yellow LED
            fill(ctx, rect: r(8, 5, 1, 1), color: Self.RGB(0xFFE040))
            // Antenna
            fill(ctx, rect: r(8, 7, 1, 1), color: Self.RGB(0x808080))
            fill(ctx, rect: r(9, 6, 1, 2), color: Self.RGB(0x808080))
        }
    }

    // MARK: - Bird Cage Textures

    /// Bird cage — 16x24 pixel art (dome cage on a stand)
    func birdCage() -> SKTexture {
        drawTexture(width: 16, height: 24) { [self] ctx in
            // Stand base
            fill(ctx, rect: r(5, 0, 6, 1), color: Self.woodDark)
            fill(ctx, rect: r(6, 1, 4, 1), color: Self.woodMid)
            // Stand pole
            fill(ctx, rect: r(7, 2, 2, 3), color: Self.woodMid)
            fill(ctx, rect: r(7, 2, 1, 3), color: Self.woodLight)
            // Cage ring at bottom
            fill(ctx, rect: r(4, 5, 8, 1), color: Self.RGB(0xC8A800))
            // Cage bars (vertical)
            for x in [4, 6, 8, 10, 11] {
                fill(ctx, rect: r(x, 5, 1, 14), color: Self.RGB(0xE0C840))
            }
            // Left and right bars
            fill(ctx, rect: r(3, 8, 1, 8), color: Self.RGB(0xE0C840))
            fill(ctx, rect: r(12, 8, 1, 8), color: Self.RGB(0xE0C840))
            // Cage dome top arcs (horizontal rings)
            fill(ctx, rect: r(5, 19, 6, 1), color: Self.RGB(0xC8A800))
            fill(ctx, rect: r(4, 16, 8, 1), color: Self.RGB(0xE0C840))
            fill(ctx, rect: r(3, 13, 10, 1), color: Self.RGB(0xE0C840))
            fill(ctx, rect: r(4, 10, 8, 1), color: Self.RGB(0xE0C840))
            fill(ctx, rect: r(5, 7, 6, 1), color: Self.RGB(0xE0C840))
            // Cage ring at bottom of bars
            fill(ctx, rect: r(4, 5, 8, 1), color: Self.RGB(0xC8A800))
            // Top hook
            fill(ctx, rect: r(7, 20, 2, 2), color: Self.RGB(0xC8A800))
            fill(ctx, rect: r(7, 22, 2, 1), color: Self.RGB(0xE0C840))
            // Perch bar inside cage
            fill(ctx, rect: r(5, 9, 6, 1), color: Self.woodLight)
        }
    }

    /// Bird idle animation frame — 6x6 pixel art small parakeet
    func birdIdle(frame: Int = 0) -> SKTexture {
        drawTexture(width: 6, height: 6) { [self] ctx in
            // Body
            fill(ctx, rect: r(1, 1, 4, 3), color: Self.RGB(0x40C060))
            fill(ctx, rect: r(2, 2, 2, 2), color: Self.RGB(0x60E080))
            // Head
            fill(ctx, rect: r(2, 4, 2, 2), color: Self.RGB(0xFFE040))
            // Eye
            fill(ctx, rect: r(3, 5, 1, 1), color: Self.RGB(0x202020))
            // Beak
            fill(ctx, rect: r(4, 4, 1, 1), color: Self.RGB(0xE08020))
            // Tail
            fill(ctx, rect: r(0, 1, 1, 2), color: Self.RGB(0x3090A0))
            // Wing variation per frame
            let wingColor: Int = frame == 1 ? 0x80E0A0 : (frame == 2 ? 0x20A040 : 0x50C070)
            fill(ctx, rect: r(1, 2, 3, 1), color: Self.RGB(wingColor))
        }
    }

    // MARK: - Planning Clipboard Texture

    /// Planning clipboard — 6x8 pixel art
    func planningClipboard() -> SKTexture {
        drawTexture(width: 6, height: 8) { [self] ctx in
            // Clipboard body
            fill(ctx, rect: r(0, 0, 6, 7), color: Self.RGB(0xC8A870))
            fill(ctx, rect: r(1, 1, 4, 5), color: Self.RGB(0xF0EDE0))
            // Clip at top
            fill(ctx, rect: r(2, 7, 2, 1), color: Self.RGB(0x808080))
            fill(ctx, rect: r(1, 6, 4, 1), color: Self.RGB(0x909090))
            // Checkbox lines
            fill(ctx, rect: r(1, 4, 1, 1), color: Self.RGB(0x40A040)) // check
            fill(ctx, rect: r(2, 4, 3, 1), color: Self.RGB(0xA0A0A0))
            fill(ctx, rect: r(1, 2, 1, 1), color: Self.RGB(0xC0C0C0)) // unchecked
            fill(ctx, rect: r(2, 2, 3, 1), color: Self.RGB(0xA0A0A0))
        }
    }

    // MARK: - Achievement Textures

    /// Achievement shelf — 24x8 pixel art
    func achievementShelf() -> SKTexture {
        drawTexture(width: 24, height: 8) { [self] ctx in
            // Back panel
            fill(ctx, rect: r(0, 2, 24, 6), color: Self.woodMid)
            fill(ctx, rect: r(0, 2, 24, 1), color: Self.woodDark)
            // Shelf surface
            fill(ctx, rect: r(0, 0, 24, 2), color: Self.woodDark)
            fill(ctx, rect: r(1, 1, 22, 1), color: Self.woodLight)
            // Brackets
            fill(ctx, rect: r(3, 0, 1, 3), color: Self.RGB(0x808080))
            fill(ctx, rect: r(20, 0, 1, 3), color: Self.RGB(0x808080))
        }
    }

    /// Trophy cup — 6x8 pixel art (golden cup)
    func trophyCup() -> SKTexture {
        drawTexture(width: 6, height: 8) { [self] ctx in
            // Base
            fill(ctx, rect: r(1, 0, 4, 2), color: Self.RGB(0xB8860B))
            // Stem
            fill(ctx, rect: r(2, 2, 2, 2), color: Self.RGB(0xDAA520))
            // Cup
            fill(ctx, rect: r(0, 4, 6, 3), color: Self.RGB(0xFFD700))
            fill(ctx, rect: r(1, 5, 4, 1), color: Self.RGB(0xFFE44D))
            // Rim
            fill(ctx, rect: r(0, 7, 6, 1), color: Self.RGB(0xDAA520))
        }
    }

    /// Trophy star — 6x8 pixel art (silver star)
    func trophyStar() -> SKTexture {
        drawTexture(width: 6, height: 8) { [self] ctx in
            // Base
            fill(ctx, rect: r(2, 0, 2, 2), color: Self.RGB(0x808080))
            // Star shape (approximated)
            fill(ctx, rect: r(2, 2, 2, 1), color: Self.RGB(0xC0C0C0))
            fill(ctx, rect: r(1, 3, 4, 2), color: Self.RGB(0xC0C0C0))
            fill(ctx, rect: r(0, 4, 6, 1), color: Self.RGB(0xC0C0C0))
            fill(ctx, rect: r(1, 5, 4, 1), color: Self.RGB(0xC0C0C0))
            fill(ctx, rect: r(1, 6, 1, 1), color: Self.RGB(0xC0C0C0))
            fill(ctx, rect: r(4, 6, 1, 1), color: Self.RGB(0xC0C0C0))
            fill(ctx, rect: r(2, 7, 2, 1), color: Self.RGB(0xC0C0C0))
            // Shine
            fill(ctx, rect: r(2, 5, 1, 1), color: Self.RGB(0xE0E0E0))
        }
    }

    /// Trophy moon — 6x8 pixel art (blue crescent)
    func trophyMoon() -> SKTexture {
        drawTexture(width: 6, height: 8) { [self] ctx in
            // Base
            fill(ctx, rect: r(2, 0, 2, 2), color: Self.RGB(0x808080))
            // Moon circle
            fill(ctx, rect: r(1, 3, 4, 4), color: Self.RGB(0x4060A0))
            fill(ctx, rect: r(2, 2, 2, 1), color: Self.RGB(0x4060A0))
            fill(ctx, rect: r(2, 7, 2, 1), color: Self.RGB(0x4060A0))
            // Crescent cutout
            fill(ctx, rect: r(3, 4, 2, 2), color: Self.RGB(0x203048))
            fill(ctx, rect: r(4, 3, 1, 1), color: Self.RGB(0x203048))
            // Glow
            fill(ctx, rect: r(1, 5, 1, 1), color: Self.RGB(0x6080C0))
        }
    }

    /// Trophy house — 6x8 pixel art (small house icon)
    func trophyHouse() -> SKTexture {
        drawTexture(width: 6, height: 8) { [self] ctx in
            // Base
            fill(ctx, rect: r(2, 0, 2, 1), color: Self.RGB(0x808080))
            // Walls
            fill(ctx, rect: r(1, 1, 4, 3), color: Self.RGB(0xE8D8B8))
            // Door
            fill(ctx, rect: r(2, 1, 2, 2), color: Self.RGB(0x8B6B3D))
            // Roof
            fill(ctx, rect: r(0, 4, 6, 1), color: Self.RGB(0xC04040))
            fill(ctx, rect: r(1, 5, 4, 1), color: Self.RGB(0xC04040))
            fill(ctx, rect: r(2, 6, 2, 1), color: Self.RGB(0xC04040))
            fill(ctx, rect: r(2, 7, 2, 1), color: Self.RGB(0xA03030))
        }
    }

    /// Trophy lightning — 6x8 pixel art (yellow bolt)
    func trophyLightning() -> SKTexture {
        drawTexture(width: 6, height: 8) { [self] ctx in
            // Base
            fill(ctx, rect: r(2, 0, 2, 1), color: Self.RGB(0x808080))
            // Lightning bolt
            fill(ctx, rect: r(3, 1, 2, 1), color: Self.RGB(0xFFD700))
            fill(ctx, rect: r(2, 2, 2, 1), color: Self.RGB(0xFFD700))
            fill(ctx, rect: r(1, 3, 3, 1), color: Self.RGB(0xFFD700))
            fill(ctx, rect: r(2, 4, 2, 1), color: Self.RGB(0xFFD700))
            fill(ctx, rect: r(3, 5, 2, 1), color: Self.RGB(0xFFD700))
            fill(ctx, rect: r(2, 6, 2, 1), color: Self.RGB(0xFFD700))
            fill(ctx, rect: r(1, 7, 2, 1), color: Self.RGB(0xFFD700))
            // Glow
            fill(ctx, rect: r(2, 4, 1, 1), color: Self.RGB(0xFFE44D))
        }
    }

    // MARK: - Drawing Helpers

    private func drawTexture(width: Int, height: Int, draw: @escaping (CGContext) -> Void) -> SKTexture {
        let image = NSImage(size: NSSize(width: width, height: height), flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            ctx.clear(rect)
            draw(ctx)
            return true
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        return texture
    }

    private func r(_ x: Int, _ y: Int, _ w: Int, _ h: Int) -> CGRect {
        CGRect(x: x, y: y, width: w, height: h)
    }

    private func fill(_ ctx: CGContext, rect: CGRect, color: NSColor) {
        ctx.setFillColor(color.cgColor)
        ctx.fill([rect])
    }

    public static func RGB(_ hex: Int) -> NSColor {
        NSColor(
            red: CGFloat((hex >> 16) & 0xFF) / 255.0,
            green: CGFloat((hex >> 8) & 0xFF) / 255.0,
            blue: CGFloat(hex & 0xFF) / 255.0,
            alpha: 1.0
        )
    }
}
