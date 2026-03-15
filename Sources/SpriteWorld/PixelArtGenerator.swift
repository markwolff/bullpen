import SpriteKit
import AppKit

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
        // 24x16 pixel desk, displayed at 96x64
        drawTexture(width: 24, height: 16) { [self] ctx in
            // Desktop surface
            fill(ctx, rect: r(0, 8, 24, 6), color: Self.woodMid)
            fill(ctx, rect: r(0, 14, 24, 2), color: Self.woodLight) // front edge highlight
            fill(ctx, rect: r(0, 8, 24, 1), color: Self.woodDark)   // back edge

            // Legs
            fill(ctx, rect: r(2, 0, 2, 8), color: Self.woodDark)
            fill(ctx, rect: r(20, 0, 2, 8), color: Self.woodDark)

            // Drawer on the right
            fill(ctx, rect: r(15, 2, 5, 5), color: Self.woodMid)
            fill(ctx, rect: r(15, 2, 5, 1), color: Self.woodDark) // top
            fill(ctx, rect: r(15, 6, 5, 1), color: Self.woodDark) // bottom
            fill(ctx, rect: r(17, 4, 1, 1), color: Self.woodHighlight) // knob

            // Wood grain on desktop
            fill(ctx, rect: r(4, 10, 3, 1), color: Self.woodHighlight)
            fill(ctx, rect: r(10, 11, 4, 1), color: Self.woodHighlight)
            fill(ctx, rect: r(18, 10, 3, 1), color: Self.woodHighlight)
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
                                skin: NSColor, eyeColor: NSColor, eyeDark: NSColor, state: String) {
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

        // State-specific details
        switch state {
        case "thinking":
            fill(ctx, rect: r(10, 16, 2, 1), color: skin)
            fill(ctx, rect: r(2, 22, 1, 1), color: Self.lampYellow)
            fill(ctx, rect: r(13, 23, 1, 1), color: Self.lampYellow)
        case "writing", "writingCode":
            fill(ctx, rect: r(2, 9, 2, 1), color: hoodie)
            fill(ctx, rect: r(12, 9, 2, 1), color: hoodie)
            fill(ctx, rect: r(2, 9, 1, 1), color: skin)
            fill(ctx, rect: r(13, 9, 1, 1), color: skin)
        case "reading", "readingFiles":
            fill(ctx, rect: r(6, 20, 2, 1), color: eyeColor)
        case "command", "runningCommand":
            fill(ctx, rect: r(7, 18, 2, 1), color: Self.RGB(0x80FF80))
        case "searching":
            fill(ctx, rect: r(7, 19, 1, 1), color: eyeColor)
            fill(ctx, rect: r(10, 19, 1, 1), color: eyeColor)
        case "waiting", "waitingForInput":
            fill(ctx, rect: r(12, 22, 2, 1), color: Self.RGB(0xFFFFFF))
            fill(ctx, rect: r(13, 23, 1, 1), color: Self.RGB(0xFFFFFF))
        case "error":
            fill(ctx, rect: r(6, 19, 2, 2), color: Self.RGB(0xFF4040))
            fill(ctx, rect: r(9, 19, 2, 2), color: Self.RGB(0xFF4040))
            fill(ctx, rect: r(12, 21, 1, 2), color: Self.RGB(0x80C0FF))
        case "finished":
            fill(ctx, rect: r(6, 19, 2, 1), color: hoodieDark)
            fill(ctx, rect: r(9, 19, 2, 1), color: hoodieDark)
            fill(ctx, rect: r(7, 17, 2, 1), color: Self.RGB(0xE08070))
        default:
            break
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

    private func drawCat(_ ctx: CGContext, sleeping: Bool, walking: Bool = false) {
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

        // Legs
        if walking {
            fill(ctx, rect: r(3, 0, 2, 2), color: Self.catOrange)
            fill(ctx, rect: r(7, 1, 2, 2), color: Self.catOrange)
        } else {
            fill(ctx, rect: r(3, 0, 2, 2), color: Self.catOrange)
            fill(ctx, rect: r(7, 0, 2, 2), color: Self.catOrange)
        }

        // Paws
        fill(ctx, rect: r(3, 0, 2, 1), color: Self.catEar)
        if walking {
            fill(ctx, rect: r(7, 1, 2, 1), color: Self.catEar)
        } else {
            fill(ctx, rect: r(7, 0, 2, 1), color: Self.catEar)
        }
    }

    // MARK: - Drawing Helpers

    private func drawTexture(width: Int, height: Int, draw: @escaping (CGContext) -> Void) -> SKTexture {
        let image = NSImage(size: NSSize(width: width, height: height), flipped: true) { rect in
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

    private static func RGB(_ hex: Int) -> NSColor {
        NSColor(
            red: CGFloat((hex >> 16) & 0xFF) / 255.0,
            green: CGFloat((hex >> 8) & 0xFF) / 255.0,
            blue: CGFloat(hex & 0xFF) / 255.0,
            alpha: 1.0
        )
    }
}
