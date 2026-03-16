import SpriteKit
import Models

/// Manages loading and caching of textures for sprites.
/// Tries to load from texture atlases first, falls back to programmatic
/// placeholder textures (colored rectangles) when PNGs are not available.
public final class TextureManager: @unchecked Sendable {

    /// Shared singleton instance
    public static let shared = TextureManager()

    /// Atlas names matching the asset manifest
    public static let atlasNames = ["claude", "codex", "furniture", "decorations", "tiles", "cat"]

    /// Cached textures keyed by name
    private var cache: [String: SKTexture] = [:]

    /// Lock for thread safety
    private let lock = NSLock()

    private init() {}

    // MARK: - Texture Name Constants

    // Agent textures (per type, per state)
    public static let charClaudeIdle = "char_claude_idle"
    public static let charClaudeThinking = "char_claude_thinking"
    public static let charClaudeWritingCode = "char_claude_writingCode"
    public static let charClaudeReadingFiles = "char_claude_readingFiles"
    public static let charClaudeRunningCommand = "char_claude_runningCommand"
    public static let charClaudeSearching = "char_claude_searching"
    public static let charClaudeWaitingForInput = "char_claude_waitingForInput"
    public static let charClaudeError = "char_claude_error"
    public static let charClaudeFinished = "char_claude_finished"
    public static let charClaudeSupervisingAgents = "char_claude_supervisingAgents"

    public static let charCodexIdle = "char_codex_idle"
    public static let charCodexThinking = "char_codex_thinking"
    public static let charCodexWritingCode = "char_codex_writingCode"
    public static let charCodexReadingFiles = "char_codex_readingFiles"
    public static let charCodexRunningCommand = "char_codex_runningCommand"
    public static let charCodexSearching = "char_codex_searching"
    public static let charCodexWaitingForInput = "char_codex_waitingForInput"
    public static let charCodexError = "char_codex_error"
    public static let charCodexFinished = "char_codex_finished"
    public static let charCodexSupervisingAgents = "char_codex_supervisingAgents"

    // Furniture textures
    public static let furnitureDesk = "furniture_desk"
    public static let furnitureChair = "furniture_chair"
    public static let furnitureMonitorOff = "furniture_monitor_off"
    public static let furnitureMonitorOn = "furniture_monitor_on"
    public static let furnitureLamp = "furniture_lamp"
    public static let furnitureCoffeeMug = "furniture_coffee_mug"
    public static let furnitureLaptopDesk = "furniture_laptop_desk"
    public static let furnitureLaptopOn = "furniture_laptop_on"
    public static let furnitureLaptopOff = "furniture_laptop_off"
    public static let furnitureLaptopScreensaver = "furniture_laptop_screensaver"
    public static let furnitureLongTable = "furniture_long_table"

    // Decoration textures
    public static let decorationPlant = "decoration_plant"
    public static let decorationWindow = "decoration_window"
    public static let decorationWhiteboard = "decoration_whiteboard"
    public static let decorationClock = "decoration_clock"
    public static let decorationBookshelf = "decoration_bookshelf"
    public static let decorationBulletinBoard = "decoration_bulletin_board"
    public static let decorationWaterCooler = "decoration_water_cooler"
    public static let decorationPoster = "decoration_poster"
    public static let decorationDoor = "decoration_door"
    public static let decorationCouch = "decoration_couch"
    public static let decorationPrinter = "decoration_printer"
    public static let decorationCoatRack = "decoration_coat_rack"
    public static let decorationAchievementShelf = "decoration_achievement_shelf"
    public static let decorationRadio = "decoration_radio"

    // Item textures
    public static let itemStickyNoteYellow = "item_sticky_note_yellow"
    public static let itemStickyNotePink = "item_sticky_note_pink"
    public static let itemStickyNoteBlue = "item_sticky_note_blue"
    public static let itemCrumpledPaper = "item_crumpled_paper"
    public static let itemRubberDuck = "item_rubber_duck"
    public static let itemCoffeeCup = "item_coffee_cup"
    public static let itemPizzaBox = "item_pizza_box"

    // NPC textures
    public static let npcJanitor = "npc_janitor"
    public static let npcPizzaDelivery = "npc_pizza_delivery"

    // Plant growth textures
    public static let plantSeedling = "plant_seedling"
    public static let plantSmall = "plant_small"
    public static let plantMedium = "plant_medium"
    public static let plantLarge = "plant_large"

    // Overlay textures
    public static let overlaySleepyEyes = "overlay_sleepy_eyes"

    // Trophy textures
    public static let trophyCup = "trophy_cup"
    public static let trophyStar = "trophy_star"
    public static let trophyMoon = "trophy_moon"
    public static let trophyHouse = "trophy_house"
    public static let trophyLightning = "trophy_lightning"

    // Planning texture
    public static let itemPlanningClipboard = "item_planning_clipboard"

    // Tile textures
    public static let tileFloor = "tile_floor"
    public static let tileWall = "tile_wall"

    // Cat textures
    public static let catIdle = "cat_idle"
    public static let catSleep = "cat_sleep"
    public static let catWalk = "cat_walk"

    // Dog textures - Pancake the Maltipoo
    public static let dogIdle = "dog_idle"
    public static let dogSleep = "dog_sleep"
    public static let dogWalk = "dog_walk"
    public static let dogEat = "dog_eat"
    public static let dogBowl = "dog_bowl"
    public static let dogToyBall = "dog_toy_ball"
    public static let dogToyBone = "dog_toy_bone"
    public static let dogToyRope = "dog_toy_rope"

    /// All known texture names for validation
    public static let allTextureNames: [String] = [
        charClaudeIdle, charClaudeThinking, charClaudeWritingCode, charClaudeReadingFiles,
        charClaudeRunningCommand, charClaudeSearching, charClaudeWaitingForInput,
        charClaudeError, charClaudeFinished, charClaudeSupervisingAgents,
        charCodexIdle, charCodexThinking, charCodexWritingCode, charCodexReadingFiles,
        charCodexRunningCommand, charCodexSearching, charCodexWaitingForInput,
        charCodexError, charCodexFinished, charCodexSupervisingAgents,
        furnitureDesk, furnitureChair, furnitureMonitorOff, furnitureMonitorOn,
        furnitureLamp, furnitureCoffeeMug,
        furnitureLaptopDesk, furnitureLaptopOn, furnitureLaptopOff, furnitureLaptopScreensaver, furnitureLongTable,
        decorationPlant, decorationWindow, decorationWhiteboard, decorationClock,
        decorationBookshelf, decorationBulletinBoard, decorationWaterCooler, decorationPoster, decorationDoor,
        decorationCouch, decorationPrinter, decorationCoatRack,
        decorationAchievementShelf, decorationRadio,
        itemStickyNoteYellow, itemStickyNotePink, itemStickyNoteBlue,
        itemCrumpledPaper, itemRubberDuck, itemCoffeeCup, itemPizzaBox, itemPlanningClipboard,
        npcJanitor, npcPizzaDelivery,
        plantSeedling, plantSmall, plantMedium, plantLarge,
        overlaySleepyEyes,
        trophyCup, trophyStar, trophyMoon, trophyHouse, trophyLightning,
        tileFloor, tileWall,
        catIdle, catSleep, catWalk,
        dogIdle, dogSleep, dogWalk, dogEat, dogBowl,
        dogToyBall, dogToyBone, dogToyRope,
    ]

    // MARK: - Public API

    /// Returns a texture for the given name, using pixel art generator first.
    public func texture(for name: String) -> SKTexture {
        lock.lock()
        defer { lock.unlock() }

        if let cached = cache[name] {
            return cached
        }

        // Priority 1: Generate pixel art (Stardew Valley style)
        if let pixelArt = generatePixelArt(for: name) {
            pixelArt.filteringMode = .nearest
            cache[name] = pixelArt
            return pixelArt
        }

        // Priority 2: Try loading from atlas
        if let atlasTexture = loadFromAtlas(name: name) {
            atlasTexture.filteringMode = .nearest
            cache[name] = atlasTexture
            return atlasTexture
        }

        // Fall back to placeholder
        let placeholder = Self.generatePlaceholder(for: name)
        placeholder.filteringMode = .nearest
        cache[name] = placeholder
        return placeholder
    }

    /// Returns animation frames for a given agent prefix and state.
    /// Each frame is a distinct pixel art variation for fluid animation.
    public func animationFrames(prefix: String, state: AgentState) -> [SKTexture] {
        let frameCount = Self.frameCount(for: state)
        let gen = PixelArtGenerator.shared

        var frames: [SKTexture] = []
        for i in 0..<frameCount {
            let cacheKey = "\(prefix)_\(state.rawValue)_frame\(i)"

            lock.lock()
            if let cached = cache[cacheKey] {
                lock.unlock()
                frames.append(cached)
                continue
            }
            lock.unlock()

            let texture: SKTexture
            let stateStr = state.rawValue
            if prefix == "char_claude" {
                texture = gen.claudeCharacter(state: stateStr, frame: i)
            } else if prefix == "char_codex" {
                texture = gen.codexCharacter(state: stateStr, frame: i)
            } else {
                // Fallback: use the base state texture
                texture = self.texture(for: "\(prefix)_\(stateStr)")
            }

            texture.filteringMode = .nearest
            lock.lock()
            cache[cacheKey] = texture
            lock.unlock()
            frames.append(texture)
        }

        return frames
    }

    /// Returns animation frames for a trait-based character.
    /// Cache key includes a hash of the traits so each unique character is cached separately.
    public func animationFrames(traits: CharacterTraits, state: AgentState) -> [SKTexture] {
        let frameCount = Self.frameCount(for: state)
        let gen = PixelArtGenerator.shared
        let traitKey = "char_\(traits.hoodieColor)_\(traits.skinColor)_\(traits.hairStyle.rawValue)_\(traits.accessory.rawValue)"

        var frames: [SKTexture] = []
        for i in 0..<frameCount {
            let cacheKey = "\(traitKey)_\(state.rawValue)_frame\(i)"

            lock.lock()
            if let cached = cache[cacheKey] {
                lock.unlock()
                frames.append(cached)
                continue
            }
            lock.unlock()

            let texture = gen.character(traits: traits, state: state.rawValue, frame: i)
            texture.filteringMode = .nearest

            lock.lock()
            cache[cacheKey] = texture
            lock.unlock()
            frames.append(texture)
        }

        return frames
    }

    /// Returns the expected frame count for a given state.
    public static func frameCount(for state: AgentState) -> Int {
        switch state {
        case .idle: 4
        case .thinking: 4
        case .writingCode: 2
        case .readingFiles: 3
        case .runningCommand: 2
        case .searching: 4
        case .waitingForInput: 4
        case .error: 2
        case .finished: 4
        case .supervisingAgents: 4
        }
    }

    /// Clears the texture cache (useful for testing).
    public func clearCache() {
        lock.lock()
        cache.removeAll()
        lock.unlock()
    }

    // MARK: - Placeholder Generation

    /// Creates a placeholder texture of the given size and color.
    public static func placeholderTexture(size: CGSize, color: SKColor) -> SKTexture {
        let image = NSImage(size: size, flipped: false) { rect in
            color.setFill()
            rect.fill()
            return true
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        return texture
    }

    // MARK: - Pixel Art Generation

    /// Generates a Stardew Valley-style pixel art texture for the given name.
    private func generatePixelArt(for name: String) -> SKTexture? {
        let gen = PixelArtGenerator.shared

        // Tiles
        if name == Self.tileFloor { return gen.floorTile() }
        if name == Self.tileWall { return gen.wallTile() }

        // Furniture
        if name == Self.furnitureDesk { return gen.desk() }
        if name == Self.furnitureChair { return gen.chair() }
        if name == Self.furnitureMonitorOff { return gen.monitorOff() }
        if name == Self.furnitureMonitorOn { return gen.monitorOn() }
        if name == Self.furnitureLamp { return gen.lamp() }
        if name == Self.furnitureCoffeeMug { return gen.coffeeMug() }
        if name == Self.furnitureLaptopDesk { return gen.laptopDesk() }
        if name == Self.furnitureLaptopOn { return gen.laptopOn() }
        if name == Self.furnitureLaptopOff { return gen.laptopOff() }
        if name == Self.furnitureLaptopScreensaver { return gen.laptopScreensaver() }
        if name == Self.furnitureLongTable { return gen.longTable() }

        // Decorations
        if name == Self.decorationPlant { return gen.plant() }
        if name == Self.decorationWindow { return gen.windowDecoration() }
        if name == Self.decorationWhiteboard { return gen.whiteboard() }
        if name == Self.decorationClock { return gen.clock() }
        if name == Self.decorationBookshelf { return gen.bookshelf() }
        if name == Self.decorationBulletinBoard { return gen.bulletinBoard() }
        if name == Self.decorationWaterCooler { return gen.waterCooler() }
        if name == Self.decorationPoster { return gen.poster() }
        if name == Self.decorationDoor { return gen.door() }
        if name == Self.decorationCouch { return gen.couch() }
        if name == Self.decorationPrinter { return gen.printer() }
        if name == Self.decorationCoatRack { return gen.coatRack() }
        if name == Self.decorationAchievementShelf { return gen.achievementShelf() }
        if name == Self.decorationRadio { return gen.officeRadio() }

        // Items
        if name == Self.itemStickyNoteYellow { return gen.stickyNote(color: PixelArtGenerator.RGB(0xFFF8A0)) }
        if name == Self.itemStickyNotePink { return gen.stickyNote(color: PixelArtGenerator.RGB(0xFFB0C0)) }
        if name == Self.itemStickyNoteBlue { return gen.stickyNote(color: PixelArtGenerator.RGB(0xA0D0FF)) }
        if name == Self.itemCrumpledPaper { return gen.crumpledPaper() }
        if name == Self.itemRubberDuck { return gen.rubberDuck() }
        if name == Self.itemCoffeeCup { return gen.coffeeCupSmall() }
        if name == Self.itemPizzaBox { return gen.pizzaBox() }
        if name == Self.itemPlanningClipboard { return gen.planningClipboard() }

        // NPCs
        if name == Self.npcJanitor { return gen.janitorNPC() }
        if name == Self.npcPizzaDelivery { return gen.pizzaDeliveryNPC() }

        // Plant growth stages
        if name == Self.plantSeedling { return gen.plantSeedling() }
        if name == Self.plantSmall { return gen.plantSmall() }
        if name == Self.plantMedium { return gen.plantMedium() }
        if name == Self.plantLarge { return gen.plantLarge() }

        // Overlays
        if name == Self.overlaySleepyEyes { return gen.sleepyEyeOverlay() }

        // Trophies
        if name == Self.trophyCup { return gen.trophyCup() }
        if name == Self.trophyStar { return gen.trophyStar() }
        if name == Self.trophyMoon { return gen.trophyMoon() }
        if name == Self.trophyHouse { return gen.trophyHouse() }
        if name == Self.trophyLightning { return gen.trophyLightning() }

        // Cat (frame variants use the parameterized methods directly)
        if name == Self.catIdle { return gen.catIdle() }
        if name == Self.catSleep { return gen.catSleep() }
        if name == Self.catWalk { return gen.catWalk() }

        // Cat frame variants (cat_idle_frame0, cat_walk_frame1, etc.)
        if name.hasPrefix("cat_idle_frame") {
            let frameStr = String(name.dropFirst("cat_idle_frame".count))
            return gen.catIdle(frame: Int(frameStr) ?? 0)
        }
        if name.hasPrefix("cat_sleep_frame") {
            let frameStr = String(name.dropFirst("cat_sleep_frame".count))
            return gen.catSleep(frame: Int(frameStr) ?? 0)
        }
        if name.hasPrefix("cat_walk_frame") {
            let frameStr = String(name.dropFirst("cat_walk_frame".count))
            return gen.catWalk(frame: Int(frameStr) ?? 0)
        }

        // Dog
        if name == Self.dogIdle { return gen.dogIdle() }
        if name == Self.dogSleep { return gen.dogSleep() }
        if name == Self.dogWalk { return gen.dogWalk() }
        if name == Self.dogEat { return gen.dogEat() }
        if name == Self.dogBowl { return gen.dogBowl() }
        if name == Self.dogToyBall { return gen.dogToyBall() }
        if name == Self.dogToyBone { return gen.dogToyBone() }
        if name == Self.dogToyRope { return gen.dogToyRope() }

        // Dog frame variants (dog_idle_frame0, dog_walk_frame1, etc.)
        if name.hasPrefix("dog_idle_frame") {
            let frameStr = String(name.dropFirst("dog_idle_frame".count))
            return gen.dogIdle(frame: Int(frameStr) ?? 0)
        }
        if name.hasPrefix("dog_sleep_frame") {
            let frameStr = String(name.dropFirst("dog_sleep_frame".count))
            return gen.dogSleep(frame: Int(frameStr) ?? 0)
        }
        if name.hasPrefix("dog_walk_frame") {
            let frameStr = String(name.dropFirst("dog_walk_frame".count))
            return gen.dogWalk(frame: Int(frameStr) ?? 0)
        }
        if name.hasPrefix("dog_wag_frame") {
            let frameStr = String(name.dropFirst("dog_wag_frame".count))
            return gen.dogTailWag(frame: Int(frameStr) ?? 0)
        }

        // Characters - Claude
        if name.hasPrefix("char_claude_") {
            let state = String(name.dropFirst("char_claude_".count))
            return gen.claudeCharacter(state: state)
        }

        // Characters - Codex
        if name.hasPrefix("char_codex_") {
            let state = String(name.dropFirst("char_codex_".count))
            return gen.codexCharacter(state: state)
        }

        return nil
    }

    // MARK: - Private Helpers

    /// Attempts to load a texture from a SpriteKit texture atlas.
    private func loadFromAtlas(name: String) -> SKTexture? {
        for atlasName in Self.atlasNames {
            let atlas = SKTextureAtlas(named: atlasName)
            if atlas.textureNames.contains(name) {
                return atlas.textureNamed(name)
            }
        }
        return nil
    }

    /// Generates a placeholder texture with a color derived from the texture name.
    private static func generatePlaceholder(for name: String) -> SKTexture {
        let size: CGSize
        let color: SKColor

        if name.hasPrefix("char_") {
            size = CGSize(width: 32, height: 48)
            color = colorForTextureName(name)
        } else if name.hasPrefix("furniture_") {
            size = furnitureSize(for: name)
            color = colorForTextureName(name)
        } else if name.hasPrefix("decoration_") {
            size = decorationSize(for: name)
            color = colorForTextureName(name)
        } else if name.hasPrefix("tile_") {
            size = CGSize(width: 32, height: 32)
            color = colorForTextureName(name)
        } else if name.hasPrefix("cat_") {
            size = CGSize(width: 24, height: 24)
            color = SKColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0) // Orange cat
        } else {
            size = CGSize(width: 32, height: 32)
            color = .gray
        }

        return placeholderTexture(size: size, color: color)
    }

    /// Returns the appropriate size for furniture textures.
    private static func furnitureSize(for name: String) -> CGSize {
        switch name {
        case furnitureDesk: CGSize(width: 150, height: 40)
        case furnitureChair: CGSize(width: 20, height: 20)
        case furnitureMonitorOff, furnitureMonitorOn: CGSize(width: 20, height: 14)
        case furnitureLamp: CGSize(width: 16, height: 32)
        case furnitureCoffeeMug: CGSize(width: 10, height: 12)
        case furnitureLaptopDesk: CGSize(width: 48, height: 30)
        case furnitureLaptopOn, furnitureLaptopOff, furnitureLaptopScreensaver: CGSize(width: 24, height: 18)
        case furnitureLongTable: CGSize(width: 240, height: 30)
        default: CGSize(width: 32, height: 32)
        }
    }

    /// Returns the appropriate size for decoration textures.
    private static func decorationSize(for name: String) -> CGSize {
        switch name {
        case decorationPlant: CGSize(width: 24, height: 40)
        case decorationWindow: CGSize(width: 80, height: 50)
        case decorationWhiteboard: CGSize(width: 100, height: 60)
        case decorationClock: CGSize(width: 20, height: 20)
        case decorationCouch: CGSize(width: 60, height: 36)
        case decorationPrinter: CGSize(width: 30, height: 30)
        case decorationCoatRack: CGSize(width: 18, height: 48)
        default: CGSize(width: 32, height: 32)
        }
    }

    /// Derives a placeholder color from a texture name.
    private static func colorForTextureName(_ name: String) -> SKColor {
        if name.contains("claude") {
            return SKColor(red: 0.82, green: 0.56, blue: 0.30, alpha: 1.0) // Warm tan
        } else if name.contains("codex") {
            return SKColor(red: 0.30, green: 0.65, blue: 0.30, alpha: 1.0) // Green
        } else if name.contains("desk") {
            return SKColor(red: 0.55, green: 0.35, blue: 0.20, alpha: 1.0) // Brown
        } else if name.contains("chair") {
            return SKColor(red: 0.30, green: 0.30, blue: 0.30, alpha: 1.0) // Dark gray
        } else if name.contains("monitor_on") {
            return SKColor(red: 0.20, green: 0.30, blue: 0.50, alpha: 1.0) // Blue screen
        } else if name.contains("monitor_off") {
            return SKColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0) // Dark
        } else if name.contains("lamp") {
            return SKColor(red: 0.95, green: 0.90, blue: 0.50, alpha: 1.0) // Yellow
        } else if name.contains("coffee") || name.contains("mug") {
            return SKColor(red: 0.60, green: 0.40, blue: 0.25, alpha: 1.0) // Coffee brown
        } else if name.contains("plant") {
            return SKColor(red: 0.20, green: 0.60, blue: 0.20, alpha: 1.0) // Green
        } else if name.contains("window") {
            return SKColor(red: 0.70, green: 0.85, blue: 1.0, alpha: 1.0) // Sky blue
        } else if name.contains("whiteboard") {
            return SKColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0) // White
        } else if name.contains("clock") {
            return SKColor(red: 0.80, green: 0.80, blue: 0.80, alpha: 1.0) // Light gray
        } else if name.contains("floor") {
            return SKColor(red: 0.769, green: 0.714, blue: 0.627, alpha: 1.0) // Floor
        } else if name.contains("wall") {
            return SKColor(red: 0.918, green: 0.902, blue: 0.875, alpha: 1.0) // Wall
        } else {
            return .gray
        }
    }

    /// Creates a slightly varied color for animation frame differentiation.
    private static func varyColor(_ color: SKColor, by amount: CGFloat) -> SKColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        // Alternate lighter/darker
        let direction: CGFloat = amount.truncatingRemainder(dividingBy: 0.16) < 0.08 ? 1 : -1
        r = min(1, max(0, r + direction * amount * 0.5))
        g = min(1, max(0, g + direction * amount * 0.5))
        b = min(1, max(0, b + direction * amount * 0.5))
        return SKColor(red: r, green: g, blue: b, alpha: a)
    }
}
