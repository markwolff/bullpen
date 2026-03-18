import SpriteKit
import AppKit

// MARK: - Overgrown Ruins Texture Name Constants

extension TextureManager {

    // Ruins environment textures
    public static let ruinsBigTreeTrunk = "ruins_big_tree_trunk"
    public static let ruinsTreeCanopy = "ruins_tree_canopy"
    public static let ruinsTreeRoots = "ruins_tree_roots"
    public static let ruinsVineCurtain = "ruins_vine_curtain"
    public static let ruinsVineWallClimber = "ruins_vine_wall_climber"
    public static let ruinsGlowingMushroomCluster = "ruins_glowing_mushroom_cluster"
    public static let ruinsSmallGlowingMushroom = "ruins_small_glowing_mushroom"
    public static let ruinsCrackedServerRack = "ruins_cracked_server_rack"
    public static let ruinsBrokenCeilingHole = "ruins_broken_ceiling_hole"
    public static let ruinsMossPatch = "ruins_moss_patch"
    public static let ruinsPuddle = "ruins_puddle"
    public static let ruinsWildflowerPatch = "ruins_wildflower_patch"
    public static let ruinsBirdNest = "ruins_bird_nest"
    public static let ruinsRubblePile = "ruins_rubble_pile"
    public static let ruinsBrokenPipeWaterfall = "ruins_broken_pipe_waterfall"
    public static let ruinsSunbeam = "ruins_sunbeam"
    public static let ruinsFlickeringMonitor = "ruins_flickering_monitor"
    public static let ruinsBrokenDoorFrame = "ruins_broken_door_frame"
    public static let ruinsOldCrackedWhiteboard = "ruins_old_cracked_whiteboard"
    public static let ruinsTiltedDesk = "ruins_tilted_desk"
}

// MARK: - Overgrown Ruins Pixel Art Generation

extension PixelArtGenerator {

    // MARK: Color Palette — Overgrown Ruins

    private static let ruinsConcreteDark = RGB(0x5A5A5A)
    private static let ruinsConcreteMid = RGB(0x808080)
    private static let ruinsConcreteLight = RGB(0xA0A0A0)
    private static let ruinsBarkDark = RGB(0x3A2410)
    private static let ruinsBarkMid = RGB(0x5C3A1E)
    private static let ruinsBarkLight = RGB(0x7A5030)
    private static let ruinsBarkHighlight = RGB(0x987048)
    private static let ruinsLeafDark = RGB(0x1E6830)
    private static let ruinsLeafMid = RGB(0x38A050)
    private static let ruinsLeafLight = RGB(0x58C868)
    private static let ruinsLeafHighlight = RGB(0x78E080)
    private static let ruinsVineDark = RGB(0x205828)
    private static let ruinsVineMid = RGB(0x388840)
    private static let ruinsVineLight = RGB(0x50A858)
    private static let ruinsMushroomCap = RGB(0xD0D8E0)
    private static let ruinsMushroomGlow = RGB(0x40E0D0)
    private static let ruinsMushroomGlowBright = RGB(0x80FFF0)
    private static let ruinsMushroomStem = RGB(0xC0C8B8)
    private static let ruinsSkyBlue = RGB(0x88C8F0)
    private static let ruinsSkyLight = RGB(0xB0E0FF)
    private static let ruinsRebar = RGB(0x8B4513)
    private static let ruinsRust = RGB(0xA05020)
    private static let ruinsServerGray = RGB(0x606870)
    private static let ruinsServerDark = RGB(0x404850)
    private static let ruinsLedGreen = RGB(0x40FF40)
    private static let ruinsSunGold = RGB(0xFFE040)
    private static let ruinsSunLight = RGB(0xFFF8B0)
    private static let ruinsWaterBlue = RGB(0x60A8D0)
    private static let ruinsWaterLight = RGB(0x90D0F0)
    private static let ruinsWaterDark = RGB(0x4088B0)
    private static let ruinsFlowerYellow = RGB(0xF0D030)
    private static let ruinsFlowerPurple = RGB(0xA060D0)
    private static let ruinsFlowerWhite = RGB(0xF0F0E8)
    private static let ruinsGrassDark = RGB(0x408040)
    private static let ruinsGrassLight = RGB(0x60A060)
    private static let ruinsMossDark = RGB(0x306830)
    private static let ruinsMossLight = RGB(0x50A050)
    private static let ruinsNestBrown = RGB(0x8B6B3D)
    private static let ruinsNestLight = RGB(0xB89B6A)
    private static let ruinsEggBlue = RGB(0x90C8E0)

    // MARK: - Drawing Helpers (file-local, mirrors PixelArtGenerator.private helpers)

    private func ruinsTex(width: Int, height: Int, draw: @escaping (CGContext) -> Void) -> SKTexture {
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

    private func px(_ ctx: CGContext, _ x: Int, _ y: Int, _ w: Int, _ h: Int, _ color: NSColor) {
        ctx.setFillColor(color.cgColor)
        ctx.fill([CGRect(x: x, y: y, width: w, height: h)])
    }

    // MARK: - 1. Big Tree Trunk (20x48)

    /// Massive gnarled trunk with thick bark texture, exposed roots at bottom,
    /// canopy leaves poking out the top.
    func bigTreeTrunk() -> SKTexture {
        ruinsTex(width: 20, height: 48) { [self] ctx in
            // Main trunk body
            px(ctx, 5, 4, 10, 38, Self.ruinsBarkMid)
            px(ctx, 6, 4, 8, 38, Self.ruinsBarkMid)

            // Wider base
            px(ctx, 3, 0, 14, 6, Self.ruinsBarkDark)
            px(ctx, 2, 0, 16, 3, Self.ruinsBarkDark)

            // Left bark edge
            px(ctx, 4, 6, 2, 34, Self.ruinsBarkDark)
            // Right bark edge
            px(ctx, 14, 6, 2, 34, Self.ruinsBarkDark)

            // Bark texture — horizontal crevices
            px(ctx, 6, 10, 8, 1, Self.ruinsBarkDark)
            px(ctx, 7, 18, 6, 1, Self.ruinsBarkDark)
            px(ctx, 6, 26, 8, 1, Self.ruinsBarkDark)
            px(ctx, 7, 34, 6, 1, Self.ruinsBarkDark)

            // Bark highlights
            px(ctx, 8, 12, 3, 1, Self.ruinsBarkHighlight)
            px(ctx, 9, 20, 4, 1, Self.ruinsBarkHighlight)
            px(ctx, 7, 28, 3, 1, Self.ruinsBarkHighlight)
            px(ctx, 10, 36, 3, 1, Self.ruinsBarkHighlight)

            // Knot / gnarl detail
            px(ctx, 8, 22, 4, 3, Self.ruinsBarkDark)
            px(ctx, 9, 23, 2, 1, Self.ruinsBarkLight)

            // Exposed roots at bottom
            px(ctx, 0, 0, 4, 2, Self.ruinsBarkDark)
            px(ctx, 1, 2, 3, 2, Self.ruinsBarkMid)
            px(ctx, 16, 0, 4, 2, Self.ruinsBarkDark)
            px(ctx, 17, 2, 2, 2, Self.ruinsBarkMid)

            // Canopy leaves poking out at top
            px(ctx, 2, 42, 16, 3, Self.ruinsLeafDark)
            px(ctx, 0, 44, 20, 4, Self.ruinsLeafMid)
            px(ctx, 3, 45, 4, 2, Self.ruinsLeafLight)
            px(ctx, 12, 46, 5, 2, Self.ruinsLeafHighlight)
        }
    }

    // MARK: - 2. Tree Canopy (48x28)

    /// Lush green leaf cluster with varied greens and light filtering through.
    func treeCanopy() -> SKTexture {
        ruinsTex(width: 48, height: 28) { [self] ctx in
            // Outer canopy shape — dark green base
            px(ctx, 8, 2, 32, 4, Self.ruinsLeafDark)
            px(ctx, 4, 4, 40, 6, Self.ruinsLeafDark)
            px(ctx, 2, 8, 44, 8, Self.ruinsLeafMid)
            px(ctx, 0, 12, 48, 8, Self.ruinsLeafMid)
            px(ctx, 2, 20, 44, 6, Self.ruinsLeafDark)
            px(ctx, 6, 24, 36, 4, Self.ruinsLeafDark)

            // Mid-tone leaf clusters
            px(ctx, 6, 10, 10, 6, Self.ruinsLeafMid)
            px(ctx, 20, 8, 12, 8, Self.ruinsLeafMid)
            px(ctx, 34, 10, 10, 6, Self.ruinsLeafMid)

            // Light filtering highlights
            px(ctx, 10, 14, 4, 3, Self.ruinsLeafLight)
            px(ctx, 22, 12, 6, 4, Self.ruinsLeafLight)
            px(ctx, 36, 14, 4, 3, Self.ruinsLeafLight)
            px(ctx, 16, 18, 3, 2, Self.ruinsLeafHighlight)
            px(ctx, 30, 16, 3, 2, Self.ruinsLeafHighlight)

            // Dappled sunlight spots
            px(ctx, 12, 16, 2, 2, Self.ruinsLeafHighlight)
            px(ctx, 26, 14, 2, 2, Self.ruinsLeafHighlight)
            px(ctx, 40, 12, 2, 2, Self.ruinsLeafHighlight)

            // Shadow underside
            px(ctx, 4, 6, 6, 2, Self.ruinsLeafDark)
            px(ctx, 38, 6, 6, 2, Self.ruinsLeafDark)
        }
    }

    // MARK: - 3. Tree Roots (32x16)

    /// Spreading root system cracking floor tiles.
    func treeRoots() -> SKTexture {
        ruinsTex(width: 32, height: 16) { [self] ctx in
            // Cracked concrete floor base
            px(ctx, 0, 0, 32, 16, Self.ruinsConcreteMid)
            px(ctx, 0, 0, 32, 2, Self.ruinsConcreteDark)

            // Crack lines in floor
            px(ctx, 8, 2, 1, 6, Self.ruinsConcreteDark)
            px(ctx, 20, 0, 1, 8, Self.ruinsConcreteDark)
            px(ctx, 4, 10, 8, 1, Self.ruinsConcreteDark)
            px(ctx, 22, 8, 6, 1, Self.ruinsConcreteDark)

            // Main root — left
            px(ctx, 0, 6, 12, 4, Self.ruinsBarkDark)
            px(ctx, 1, 7, 10, 2, Self.ruinsBarkMid)
            px(ctx, 2, 8, 4, 1, Self.ruinsBarkLight)

            // Main root — right
            px(ctx, 20, 8, 12, 4, Self.ruinsBarkDark)
            px(ctx, 21, 9, 10, 2, Self.ruinsBarkMid)
            px(ctx, 26, 10, 4, 1, Self.ruinsBarkLight)

            // Center root mass (where trunk would be above)
            px(ctx, 12, 8, 8, 6, Self.ruinsBarkDark)
            px(ctx, 13, 9, 6, 4, Self.ruinsBarkMid)
            px(ctx, 14, 10, 4, 2, Self.ruinsBarkLight)

            // Small root tendrils
            px(ctx, 0, 12, 6, 2, Self.ruinsBarkMid)
            px(ctx, 28, 4, 4, 2, Self.ruinsBarkMid)

            // Moss on roots
            px(ctx, 3, 10, 3, 1, Self.ruinsMossLight)
            px(ctx, 24, 12, 3, 1, Self.ruinsMossLight)
        }
    }

    // MARK: - 4. Vine Curtain (32x10)

    /// Hanging ivy/vine tendrils from above with various greens.
    func vineCurtain() -> SKTexture {
        ruinsTex(width: 32, height: 10) { [self] ctx in
            // Vine attachment bar at top
            px(ctx, 0, 8, 32, 2, Self.ruinsVineDark)

            // Hanging tendrils — varying lengths
            px(ctx, 2, 2, 2, 8, Self.ruinsVineMid)
            px(ctx, 3, 3, 1, 5, Self.ruinsVineLight)

            px(ctx, 7, 0, 2, 10, Self.ruinsVineDark)
            px(ctx, 8, 1, 1, 7, Self.ruinsVineMid)

            px(ctx, 12, 3, 2, 7, Self.ruinsVineMid)
            px(ctx, 13, 4, 1, 4, Self.ruinsVineLight)

            px(ctx, 17, 1, 2, 9, Self.ruinsVineDark)
            px(ctx, 18, 2, 1, 6, Self.ruinsVineMid)

            px(ctx, 22, 4, 2, 6, Self.ruinsVineMid)
            px(ctx, 23, 5, 1, 3, Self.ruinsVineLight)

            px(ctx, 27, 0, 2, 10, Self.ruinsVineDark)
            px(ctx, 28, 2, 1, 6, Self.ruinsVineMid)

            // Small leaves on tendrils
            px(ctx, 1, 4, 2, 1, Self.ruinsLeafMid)
            px(ctx, 6, 2, 2, 1, Self.ruinsLeafMid)
            px(ctx, 11, 5, 2, 1, Self.ruinsLeafLight)
            px(ctx, 16, 3, 2, 1, Self.ruinsLeafMid)
            px(ctx, 21, 6, 2, 1, Self.ruinsLeafLight)
            px(ctx, 26, 2, 2, 1, Self.ruinsLeafMid)
        }
    }

    // MARK: - 5. Vine Wall Climber (6x32)

    /// Vertical vine creeping up a wall with small leaves.
    func vineWallClimber() -> SKTexture {
        ruinsTex(width: 6, height: 32) { [self] ctx in
            // Main vine stem — slightly winding
            px(ctx, 2, 0, 2, 8, Self.ruinsVineDark)
            px(ctx, 3, 8, 2, 8, Self.ruinsVineMid)
            px(ctx, 2, 16, 2, 8, Self.ruinsVineDark)
            px(ctx, 3, 24, 2, 8, Self.ruinsVineMid)

            // Small leaves branching off
            px(ctx, 0, 4, 2, 2, Self.ruinsLeafMid)
            px(ctx, 4, 10, 2, 2, Self.ruinsLeafLight)
            px(ctx, 0, 16, 2, 2, Self.ruinsLeafMid)
            px(ctx, 4, 22, 2, 2, Self.ruinsLeafLight)
            px(ctx, 0, 28, 2, 2, Self.ruinsLeafMid)

            // Tendrils
            px(ctx, 1, 6, 1, 2, Self.ruinsVineLight)
            px(ctx, 5, 12, 1, 2, Self.ruinsVineLight)
            px(ctx, 0, 20, 1, 2, Self.ruinsVineLight)
            px(ctx, 5, 26, 1, 2, Self.ruinsVineLight)
        }
    }

    // MARK: - 6. Glowing Mushroom Cluster (12x10)

    /// 3-4 bioluminescent mushrooms in blue-green glow.
    func glowingMushroomCluster() -> SKTexture {
        ruinsTex(width: 12, height: 10) { [self] ctx in
            // Glow aura (background)
            px(ctx, 0, 0, 12, 4, Self.ruinsMushroomGlow.withAlphaComponent(0.2))
            px(ctx, 1, 2, 10, 4, Self.ruinsMushroomGlow.withAlphaComponent(0.3))

            // Mushroom 1 — large left
            px(ctx, 1, 0, 2, 5, Self.ruinsMushroomStem)
            px(ctx, 0, 5, 4, 3, Self.ruinsMushroomCap)
            px(ctx, 0, 7, 4, 1, Self.ruinsMushroomGlow)
            px(ctx, 1, 8, 2, 1, Self.ruinsMushroomGlowBright)

            // Mushroom 2 — tall center
            px(ctx, 5, 0, 2, 7, Self.ruinsMushroomStem)
            px(ctx, 4, 7, 4, 2, Self.ruinsMushroomCap)
            px(ctx, 4, 8, 4, 1, Self.ruinsMushroomGlow)
            px(ctx, 5, 9, 2, 1, Self.ruinsMushroomGlowBright)

            // Mushroom 3 — small right
            px(ctx, 9, 0, 2, 4, Self.ruinsMushroomStem)
            px(ctx, 8, 4, 4, 2, Self.ruinsMushroomCap)
            px(ctx, 8, 5, 4, 1, Self.ruinsMushroomGlow)
            px(ctx, 9, 6, 2, 1, Self.ruinsMushroomGlowBright)

            // Mushroom 4 — tiny far right
            px(ctx, 11, 0, 1, 3, Self.ruinsMushroomStem)
            px(ctx, 10, 3, 2, 2, Self.ruinsMushroomCap)
            px(ctx, 10, 4, 2, 1, Self.ruinsMushroomGlow)
        }
    }

    // MARK: - 7. Small Glowing Mushroom (8x8)

    /// Single small bioluminescent mushroom.
    func smallGlowingMushroom() -> SKTexture {
        ruinsTex(width: 8, height: 8) { [self] ctx in
            // Subtle glow aura
            px(ctx, 1, 0, 6, 3, Self.ruinsMushroomGlow.withAlphaComponent(0.15))

            // Stem
            px(ctx, 3, 0, 2, 4, Self.ruinsMushroomStem)

            // Cap
            px(ctx, 2, 4, 4, 3, Self.ruinsMushroomCap)
            px(ctx, 1, 5, 6, 2, Self.ruinsMushroomCap)

            // Glow underside
            px(ctx, 2, 4, 4, 1, Self.ruinsMushroomGlow)
            px(ctx, 3, 3, 2, 1, Self.ruinsMushroomGlowBright)

            // Cap top highlight
            px(ctx, 3, 6, 2, 1, Self.ruinsMushroomGlowBright)
        }
    }

    // MARK: - 8. Cracked Server Rack (10x20)

    /// Gray metal rack with vines growing through and one blinking LED.
    func crackedServerRack() -> SKTexture {
        ruinsTex(width: 10, height: 20) { [self] ctx in
            // Main rack body
            px(ctx, 0, 0, 10, 20, Self.ruinsServerDark)
            px(ctx, 1, 1, 8, 18, Self.ruinsServerGray)

            // Rack slots / horizontal dividers
            px(ctx, 1, 4, 8, 1, Self.ruinsServerDark)
            px(ctx, 1, 8, 8, 1, Self.ruinsServerDark)
            px(ctx, 1, 12, 8, 1, Self.ruinsServerDark)
            px(ctx, 1, 16, 8, 1, Self.ruinsServerDark)

            // Server unit faces
            px(ctx, 2, 2, 6, 2, Self.ruinsConcreteDark)
            px(ctx, 2, 5, 6, 3, Self.ruinsConcreteDark)
            px(ctx, 2, 9, 6, 3, Self.ruinsConcreteDark)
            px(ctx, 2, 13, 6, 3, Self.ruinsConcreteDark)

            // Blinking green LED
            px(ctx, 7, 14, 1, 1, Self.ruinsLedGreen)

            // Vines growing through
            px(ctx, 0, 6, 2, 8, Self.ruinsVineDark)
            px(ctx, 1, 8, 1, 4, Self.ruinsVineMid)
            px(ctx, 8, 10, 2, 6, Self.ruinsVineDark)
            px(ctx, 9, 12, 1, 3, Self.ruinsVineMid)

            // Small leaves on vines
            px(ctx, 0, 10, 1, 1, Self.ruinsLeafMid)
            px(ctx, 9, 14, 1, 1, Self.ruinsLeafLight)

            // Crack in front panel
            px(ctx, 4, 1, 1, 4, Self.ruinsConcreteDark)
            px(ctx, 5, 3, 1, 3, Self.ruinsConcreteDark)
        }
    }

    // MARK: - 9. Broken Ceiling Hole (36x12)

    /// Jagged concrete edges revealing blue sky with some rebar.
    func brokenCeilingHole() -> SKTexture {
        ruinsTex(width: 36, height: 12) { [self] ctx in
            // Concrete border
            px(ctx, 0, 0, 36, 12, Self.ruinsConcreteMid)

            // Sky visible through hole
            px(ctx, 6, 3, 24, 7, Self.ruinsSkyBlue)
            px(ctx, 8, 2, 20, 1, Self.ruinsSkyBlue)
            px(ctx, 10, 10, 16, 1, Self.ruinsSkyBlue)

            // Lighter sky center
            px(ctx, 12, 5, 12, 3, Self.ruinsSkyLight)

            // Jagged concrete edges
            px(ctx, 4, 4, 3, 2, Self.ruinsConcreteDark)
            px(ctx, 6, 8, 2, 2, Self.ruinsConcreteDark)
            px(ctx, 28, 3, 3, 3, Self.ruinsConcreteDark)
            px(ctx, 30, 7, 2, 3, Self.ruinsConcreteDark)

            // Rebar sticking out
            px(ctx, 8, 3, 1, 5, Self.ruinsRebar)
            px(ctx, 9, 4, 1, 3, Self.ruinsRust)
            px(ctx, 26, 5, 1, 5, Self.ruinsRebar)
            px(ctx, 27, 6, 1, 3, Self.ruinsRust)

            // Concrete debris fragments
            px(ctx, 2, 0, 2, 2, Self.ruinsConcreteLight)
            px(ctx, 32, 0, 2, 2, Self.ruinsConcreteLight)
        }
    }

    // MARK: - 10. Moss Patch (12x6)

    /// Soft green carpet of moss on concrete.
    func mossPatch() -> SKTexture {
        ruinsTex(width: 12, height: 6) { [self] ctx in
            // Concrete underneath
            px(ctx, 0, 0, 12, 2, Self.ruinsConcreteMid)

            // Moss base
            px(ctx, 1, 1, 10, 4, Self.ruinsMossDark)
            px(ctx, 0, 2, 12, 3, Self.ruinsMossLight)

            // Moss texture variation
            px(ctx, 2, 3, 3, 2, Self.ruinsMossDark)
            px(ctx, 7, 2, 3, 2, Self.ruinsMossDark)

            // Highlights (moisture)
            px(ctx, 4, 4, 2, 1, Self.ruinsLeafLight)
            px(ctx, 9, 3, 2, 1, Self.ruinsLeafLight)

            // Feathered edges
            px(ctx, 0, 5, 1, 1, Self.ruinsMossDark)
            px(ctx, 11, 5, 1, 1, Self.ruinsMossDark)
        }
    }

    // MARK: - 11. Puddle (16x6)

    /// Still water reflecting sky blue with slight ripple pattern.
    func ruinsPuddle() -> SKTexture {
        ruinsTex(width: 16, height: 6) { [self] ctx in
            // Floor around puddle
            px(ctx, 0, 0, 16, 6, Self.ruinsConcreteMid)

            // Puddle shape — oval
            px(ctx, 3, 1, 10, 4, Self.ruinsWaterBlue)
            px(ctx, 2, 2, 12, 2, Self.ruinsWaterBlue)

            // Lighter center reflection
            px(ctx, 5, 2, 6, 2, Self.ruinsWaterLight)
            px(ctx, 7, 3, 3, 1, Self.ruinsSkyLight)

            // Ripple pattern
            px(ctx, 4, 3, 2, 1, Self.ruinsWaterDark)
            px(ctx, 10, 2, 2, 1, Self.ruinsWaterDark)

            // Edge darkening
            px(ctx, 3, 1, 1, 1, Self.ruinsWaterDark)
            px(ctx, 12, 1, 1, 1, Self.ruinsWaterDark)
        }
    }

    // MARK: - 12. Wildflower Patch (16x8)

    /// Assorted tiny flowers (yellow, purple, white) in grass.
    func wildflowerPatch() -> SKTexture {
        ruinsTex(width: 16, height: 8) { [self] ctx in
            // Grass base
            px(ctx, 0, 0, 16, 4, Self.ruinsGrassDark)
            px(ctx, 0, 2, 16, 4, Self.ruinsGrassLight)

            // Grass blade tips
            px(ctx, 1, 5, 1, 2, Self.ruinsGrassDark)
            px(ctx, 5, 4, 1, 2, Self.ruinsGrassDark)
            px(ctx, 9, 5, 1, 2, Self.ruinsGrassDark)
            px(ctx, 13, 4, 1, 2, Self.ruinsGrassDark)

            // Yellow flowers
            px(ctx, 2, 5, 2, 2, Self.ruinsFlowerYellow)
            px(ctx, 3, 6, 1, 1, Self.RGB(0xFFF080))
            px(ctx, 11, 4, 2, 2, Self.ruinsFlowerYellow)

            // Purple flowers
            px(ctx, 6, 5, 2, 2, Self.ruinsFlowerPurple)
            px(ctx, 7, 6, 1, 1, Self.RGB(0xC080E0))
            px(ctx, 14, 5, 2, 2, Self.ruinsFlowerPurple)

            // White flowers
            px(ctx, 9, 6, 2, 2, Self.ruinsFlowerWhite)
            px(ctx, 4, 7, 1, 1, Self.ruinsFlowerWhite)
        }
    }

    // MARK: - 13. Bird Nest (10x6)

    /// Twigs and grass arranged in a circle with tiny blue eggs.
    func ruinsBirdNest() -> SKTexture {
        ruinsTex(width: 10, height: 6) { [self] ctx in
            // Outer nest ring (twigs)
            px(ctx, 1, 0, 8, 2, Self.ruinsNestBrown)
            px(ctx, 0, 1, 10, 4, Self.ruinsNestBrown)
            px(ctx, 1, 4, 8, 2, Self.ruinsNestBrown)

            // Inner nest (lighter grass/straw)
            px(ctx, 2, 1, 6, 3, Self.ruinsNestLight)
            px(ctx, 3, 2, 4, 2, Self.ruinsNestLight)

            // Blue eggs (3)
            px(ctx, 3, 2, 1, 2, Self.ruinsEggBlue)
            px(ctx, 5, 2, 1, 2, Self.ruinsEggBlue)
            px(ctx, 7, 2, 1, 1, Self.ruinsEggBlue)

            // Twig details
            px(ctx, 0, 3, 2, 1, Self.ruinsBarkMid)
            px(ctx, 8, 0, 2, 1, Self.ruinsBarkMid)
        }
    }

    // MARK: - 14. Rubble Pile (20x10)

    /// Concrete chunks, rebar, and broken tiles in grays and rust.
    func rubblePile() -> SKTexture {
        ruinsTex(width: 20, height: 10) { [self] ctx in
            // Large concrete chunks
            px(ctx, 2, 0, 6, 4, Self.ruinsConcreteMid)
            px(ctx, 10, 0, 5, 3, Self.ruinsConcreteLight)
            px(ctx, 0, 2, 4, 4, Self.ruinsConcreteDark)
            px(ctx, 14, 1, 4, 4, Self.ruinsConcreteMid)

            // Stacked chunks
            px(ctx, 4, 4, 8, 4, Self.ruinsConcreteLight)
            px(ctx, 12, 3, 6, 3, Self.ruinsConcreteMid)

            // Top layer
            px(ctx, 6, 6, 6, 3, Self.ruinsConcreteMid)
            px(ctx, 3, 7, 4, 2, Self.ruinsConcreteDark)

            // Rebar sticking out
            px(ctx, 8, 7, 1, 3, Self.ruinsRebar)
            px(ctx, 15, 5, 1, 3, Self.ruinsRebar)

            // Rust stains
            px(ctx, 9, 8, 2, 1, Self.ruinsRust)
            px(ctx, 16, 4, 2, 1, Self.ruinsRust)

            // Broken tile fragments
            px(ctx, 1, 0, 2, 2, Self.RGB(0xC8B898))
            px(ctx, 17, 0, 2, 2, Self.RGB(0xC8B898))

            // Shadow
            px(ctx, 0, 0, 20, 1, Self.ruinsConcreteDark)
        }
    }

    // MARK: - 15. Broken Pipe / Waterfall (6x16)

    /// Vertical pipe dripping water with blue droplets.
    func brokenPipeWaterfall() -> SKTexture {
        ruinsTex(width: 6, height: 16) { [self] ctx in
            // Pipe — upper section (intact)
            px(ctx, 1, 10, 4, 6, Self.ruinsServerGray)
            px(ctx, 2, 10, 2, 6, Self.ruinsConcreteLight)

            // Pipe — broken end
            px(ctx, 0, 8, 6, 3, Self.ruinsServerGray)
            px(ctx, 1, 9, 4, 1, Self.ruinsServerDark)

            // Rust around break
            px(ctx, 0, 8, 1, 2, Self.ruinsRust)
            px(ctx, 5, 8, 1, 2, Self.ruinsRust)

            // Water stream
            px(ctx, 2, 2, 2, 7, Self.ruinsWaterBlue)
            px(ctx, 3, 3, 1, 5, Self.ruinsWaterLight)

            // Droplets at bottom
            px(ctx, 2, 0, 1, 2, Self.ruinsWaterBlue)
            px(ctx, 3, 1, 1, 1, Self.ruinsWaterLight)

            // Splash at base
            px(ctx, 1, 0, 4, 1, Self.ruinsWaterLight)
            px(ctx, 0, 0, 1, 1, Self.ruinsWaterBlue)
            px(ctx, 5, 0, 1, 1, Self.ruinsWaterBlue)
        }
    }

    // MARK: - 16. Sunbeam (16x24)

    /// Golden diagonal light rays, semi-transparent with dust motes.
    func ruinsSunbeam() -> SKTexture {
        ruinsTex(width: 16, height: 24) { [self] ctx in
            // Beam shape — wider at top, narrower at bottom (diagonal)
            // Layer 1: outer glow (very transparent)
            px(ctx, 0, 18, 16, 6, Self.ruinsSunLight.withAlphaComponent(0.08))
            px(ctx, 2, 12, 14, 8, Self.ruinsSunLight.withAlphaComponent(0.1))
            px(ctx, 4, 6, 10, 8, Self.ruinsSunGold.withAlphaComponent(0.1))

            // Layer 2: core beam
            px(ctx, 4, 16, 10, 8, Self.ruinsSunLight.withAlphaComponent(0.15))
            px(ctx, 5, 10, 8, 8, Self.ruinsSunGold.withAlphaComponent(0.15))
            px(ctx, 6, 4, 6, 8, Self.ruinsSunLight.withAlphaComponent(0.2))

            // Layer 3: bright center
            px(ctx, 6, 14, 6, 8, Self.ruinsSunLight.withAlphaComponent(0.25))
            px(ctx, 7, 8, 4, 8, Self.ruinsSunGold.withAlphaComponent(0.25))
            px(ctx, 8, 2, 2, 6, Self.ruinsSunLight.withAlphaComponent(0.3))

            // Dust motes (small bright points)
            px(ctx, 8, 18, 1, 1, Self.ruinsSunLight.withAlphaComponent(0.6))
            px(ctx, 10, 14, 1, 1, Self.ruinsSunLight.withAlphaComponent(0.5))
            px(ctx, 6, 10, 1, 1, Self.ruinsSunGold.withAlphaComponent(0.5))
            px(ctx, 9, 6, 1, 1, Self.ruinsSunLight.withAlphaComponent(0.4))
            px(ctx, 7, 16, 1, 1, Self.ruinsSunGold.withAlphaComponent(0.4))
            px(ctx, 11, 12, 1, 1, Self.ruinsSunLight.withAlphaComponent(0.5))
        }
    }

    // MARK: - 17. Flickering Monitor (8x6)

    /// Old CRT-style monitor with green text on dark screen.
    func flickeringMonitor() -> SKTexture {
        ruinsTex(width: 8, height: 6) { [self] ctx in
            // Monitor casing
            px(ctx, 0, 1, 8, 5, Self.ruinsServerDark)

            // Screen bezel
            px(ctx, 1, 2, 6, 3, Self.ruinsConcreteDark)

            // Dark screen
            px(ctx, 2, 2, 4, 3, Self.RGB(0x0A1A0A))

            // Green text lines (terminal output)
            px(ctx, 2, 4, 3, 1, Self.ruinsLedGreen)
            px(ctx, 2, 3, 2, 1, Self.RGB(0x30C030))
            px(ctx, 3, 2, 2, 1, Self.ruinsLedGreen)

            // Stand
            px(ctx, 3, 0, 2, 2, Self.ruinsServerGray)
            px(ctx, 2, 0, 4, 1, Self.ruinsServerDark)

            // Screen glow reflection
            px(ctx, 5, 4, 1, 1, Self.RGB(0x20A020))
        }
    }

    // MARK: - 18. Broken Door Frame (14x24)

    /// Bent metal door frame with one hinge hanging and rust stains.
    func brokenDoorFrame() -> SKTexture {
        ruinsTex(width: 14, height: 24) { [self] ctx in
            // Door frame — left post
            px(ctx, 0, 0, 3, 24, Self.ruinsServerGray)
            px(ctx, 1, 0, 1, 24, Self.ruinsConcreteLight)

            // Door frame — right post (bent outward)
            px(ctx, 11, 0, 3, 20, Self.ruinsServerGray)
            px(ctx, 12, 0, 1, 18, Self.ruinsConcreteLight)
            // Bent top portion
            px(ctx, 12, 18, 2, 4, Self.ruinsServerGray)
            px(ctx, 13, 20, 1, 4, Self.ruinsServerDark)

            // Top lintel (cracked)
            px(ctx, 0, 22, 12, 2, Self.ruinsServerGray)
            px(ctx, 5, 22, 1, 2, Self.ruinsConcreteDark) // crack

            // Hinge — top (intact)
            px(ctx, 0, 18, 2, 2, Self.ruinsServerDark)
            px(ctx, 1, 19, 1, 1, Self.ruinsRust)

            // Hinge — bottom (hanging loose)
            px(ctx, 0, 4, 2, 3, Self.ruinsServerDark)
            px(ctx, 2, 3, 1, 2, Self.ruinsRust)
            px(ctx, 1, 3, 1, 1, Self.ruinsRust)

            // Rust stains dripping down
            px(ctx, 1, 1, 1, 3, Self.ruinsRust)
            px(ctx, 12, 6, 1, 4, Self.ruinsRust)

            // Door opening (empty space / darker)
            px(ctx, 3, 0, 8, 22, Self.RGB(0x1A1A1A))
        }
    }

    // MARK: - 19. Old Cracked Whiteboard (24x16)

    /// Whiteboard with a visible crack and faded writing marks.
    func oldCrackedWhiteboard() -> SKTexture {
        ruinsTex(width: 24, height: 16) { [self] ctx in
            // Frame
            px(ctx, 0, 0, 24, 16, Self.ruinsConcreteLight)
            px(ctx, 0, 0, 24, 1, Self.ruinsConcreteDark)
            px(ctx, 0, 15, 24, 1, Self.ruinsConcreteDark)
            px(ctx, 0, 0, 1, 16, Self.ruinsConcreteDark)
            px(ctx, 23, 0, 1, 16, Self.ruinsConcreteDark)

            // White surface
            px(ctx, 1, 1, 22, 14, Self.RGB(0xE8E8E0))

            // Crack running diagonally
            px(ctx, 6, 1, 1, 3, Self.ruinsConcreteDark)
            px(ctx, 7, 3, 1, 3, Self.ruinsConcreteDark)
            px(ctx, 8, 5, 1, 3, Self.ruinsConcreteDark)
            px(ctx, 9, 7, 1, 3, Self.ruinsConcreteDark)
            px(ctx, 10, 9, 1, 4, Self.ruinsConcreteDark)

            // Faded writing (barely visible)
            px(ctx, 3, 11, 5, 1, Self.RGB(0xC0C8D0))
            px(ctx, 3, 9, 7, 1, Self.RGB(0xC0C8D0))
            px(ctx, 14, 10, 4, 1, Self.RGB(0xD0B0B0))
            px(ctx, 13, 12, 6, 1, Self.RGB(0xC0C8D0))

            // Faded diagram circle
            px(ctx, 15, 4, 4, 1, Self.RGB(0xB0D0C0))
            px(ctx, 14, 5, 1, 3, Self.RGB(0xB0D0C0))
            px(ctx, 19, 5, 1, 3, Self.RGB(0xB0D0C0))
            px(ctx, 15, 8, 4, 1, Self.RGB(0xB0D0C0))

            // Marker tray (broken, tilted)
            px(ctx, 2, 0, 18, 1, Self.ruinsConcreteMid)
            px(ctx, 5, 1, 1, 1, Self.RGB(0x4080D0)) // blue marker
            px(ctx, 8, 1, 1, 1, Self.RGB(0xD04040)) // red marker (fallen)
        }
    }

    // MARK: - 20. Tilted Desk (16x10)

    /// Office desk at an angle with one broken leg and scattered papers.
    func tiltedDesk() -> SKTexture {
        ruinsTex(width: 16, height: 10) { [self] ctx in
            // Desktop surface (tilted — left side lower)
            px(ctx, 0, 4, 16, 3, Self.woodMid)
            px(ctx, 0, 7, 16, 1, Self.woodLight) // front edge
            px(ctx, 0, 4, 16, 1, Self.woodDark)  // back edge

            // Tilt indication: left side drops 1px
            px(ctx, 0, 3, 4, 1, Self.woodMid)

            // Legs — left side (broken, short)
            px(ctx, 1, 0, 2, 3, Self.woodDark)
            px(ctx, 2, 2, 1, 1, Self.woodMid) // broken end

            // Legs — right side (intact)
            px(ctx, 13, 0, 2, 4, Self.woodDark)

            // Middle support (cracked)
            px(ctx, 7, 1, 2, 3, Self.woodDark)
            px(ctx, 8, 2, 1, 1, Self.ruinsRust) // rust at crack

            // Scattered papers on surface
            px(ctx, 3, 5, 3, 2, Self.RGB(0xF0F0E8))
            px(ctx, 7, 6, 2, 1, Self.RGB(0xE8E8E0))
            px(ctx, 11, 5, 2, 2, Self.RGB(0xF0F0E8))

            // Paper fallen on floor
            px(ctx, 4, 0, 2, 1, Self.RGB(0xF0F0E8))
            px(ctx, 10, 0, 3, 1, Self.RGB(0xE8E8E0))

            // Drawer (hanging open)
            px(ctx, 4, 2, 3, 2, Self.woodMid)
            px(ctx, 4, 2, 3, 1, Self.woodDark)
        }
    }
}
