import SpriteKit
import Models

// MARK: - WorldTheme

/// Holds all color tokens for a single world preset.
///
/// Created via ``WorldTheme/theme(for:)`` from a ``WorldPreset``.
/// Contains only visual data — no geometry, desk count, or room IDs.
internal struct WorldTheme {

    // MARK: - Background

    let backgroundColor: SKColor
    let wallColor: SKColor
    let floorColor: SKColor
    let trimColor: SKColor

    // MARK: - Room Architecture (keyed by room ID)

    let roomFillColors: [String: SKColor]
    let roomBorderColors: [String: SKColor]
    let roomHeaderColors: [String: SKColor]
    let labelTextColor: SKColor

    // MARK: - Walls

    let solidWallColor: SKColor
    let glassWallColor: SKColor
    let glassStrokeColor: SKColor

    // MARK: - Rugs

    let rugColors: [String: SKColor]

    // MARK: - Furniture

    let tableColor: SKColor
    let tableAccentColor: SKColor

    // MARK: - Daylight

    let windowDaylightMorning: SKColor
    let windowDaylightAfternoon: SKColor
    let windowDaylightEvening: SKColor
    let windowDaylightNight: SKColor
    let dustMoteAlpha: CGFloat
    let windowBlendFactor: CGFloat

    // MARK: - Factory

    /// Returns the theme for a given preset.
    internal static func theme(for preset: WorldPreset) -> WorldTheme {
        switch preset {
        case .classicBullpen: return classicBullpen()
        case .zenStudio:      return zenStudio()
        case .overgrownRuins: return overgrownRuins()
        }
    }

    // MARK: - Classic Bullpen

    private static func classicBullpen() -> WorldTheme {
        WorldTheme(
            backgroundColor: SKColor(red: 0.86, green: 0.88, blue: 0.84, alpha: 1.0),
            wallColor: SKColor(red: 0.92, green: 0.93, blue: 0.90, alpha: 1.0),
            floorColor: SKColor(red: 0.75, green: 0.78, blue: 0.72, alpha: 1.0),
            trimColor: SKColor(red: 0.46, green: 0.42, blue: 0.36, alpha: 1.0),
            roomFillColors: [
                "focus_studio": SKColor(red: 0.80, green: 0.84, blue: 0.78, alpha: 1.0),
                "recreation_lounge": SKColor(red: 0.84, green: 0.80, blue: 0.73, alpha: 1.0),
                "collaboration_room": SKColor(red: 0.78, green: 0.82, blue: 0.77, alpha: 1.0),
                "build_room": SKColor(red: 0.76, green: 0.79, blue: 0.73, alpha: 1.0),
            ],
            roomBorderColors: [
                "recreation_lounge": SKColor(red: 0.47, green: 0.40, blue: 0.30, alpha: 1.0),
            ],
            roomHeaderColors: [
                "gallery": SKColor(red: 0.55, green: 0.60, blue: 0.54, alpha: 1.0),
                "circulation_spine": SKColor(red: 0.55, green: 0.60, blue: 0.54, alpha: 1.0),
            ],
            labelTextColor: SKColor(red: 0.24, green: 0.27, blue: 0.24, alpha: 1.0),
            solidWallColor: SKColor(red: 0.32, green: 0.35, blue: 0.31, alpha: 1.0),
            glassWallColor: SKColor(red: 0.82, green: 0.90, blue: 0.88, alpha: 1.0),
            glassStrokeColor: SKColor(red: 0.47, green: 0.56, blue: 0.54, alpha: 0.8),
            rugColors: [
                "gallery": SKColor(red: 0.62, green: 0.69, blue: 0.61, alpha: 0.55),
                "loungeBorder": SKColor(red: 0.42, green: 0.31, blue: 0.24, alpha: 0.40),
                "lounge": SKColor(red: 0.74, green: 0.61, blue: 0.46, alpha: 0.58),
                "focus": SKColor(red: 0.62, green: 0.56, blue: 0.46, alpha: 0.60),
                "build": SKColor(red: 0.55, green: 0.48, blue: 0.38, alpha: 0.55),
                "collab": SKColor(red: 0.50, green: 0.56, blue: 0.62, alpha: 0.42),
            ],
            tableColor: SKColor(red: 0.30, green: 0.31, blue: 0.27, alpha: 1.0),
            tableAccentColor: SKColor(red: 0.72, green: 0.77, blue: 0.72, alpha: 0.85),
            windowDaylightMorning: SKColor(red: 0.961, green: 0.902, blue: 0.784, alpha: 1.0),
            windowDaylightAfternoon: SKColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
            windowDaylightEvening: SKColor(red: 0.910, green: 0.753, blue: 0.565, alpha: 1.0),
            windowDaylightNight: SKColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
            dustMoteAlpha: 0.25,
            windowBlendFactor: 0.4
        )
    }

    // MARK: - Zen Studio (warm wood, cream, indigo accents)

    private static func zenStudio() -> WorldTheme {
        WorldTheme(
            backgroundColor: SKColor(red: 0.90, green: 0.86, blue: 0.78, alpha: 1.0),
            wallColor: SKColor(red: 0.94, green: 0.91, blue: 0.84, alpha: 1.0),
            floorColor: SKColor(red: 0.82, green: 0.76, blue: 0.64, alpha: 1.0),
            trimColor: SKColor(red: 0.42, green: 0.32, blue: 0.22, alpha: 1.0),
            roomFillColors: [
                "meditation_garden": SKColor(red: 0.88, green: 0.86, blue: 0.78, alpha: 1.0),
                "tea_room": SKColor(red: 0.90, green: 0.85, blue: 0.76, alpha: 1.0),
                "koi_courtyard": SKColor(red: 0.84, green: 0.82, blue: 0.74, alpha: 1.0),
                "engawa": SKColor(red: 0.86, green: 0.83, blue: 0.75, alpha: 1.0),
                "main_work_hall": SKColor(red: 0.86, green: 0.84, blue: 0.76, alpha: 1.0),
                "scroll_library": SKColor(red: 0.88, green: 0.85, blue: 0.78, alpha: 1.0),
            ],
            roomBorderColors: [
                "tea_room": SKColor(red: 0.50, green: 0.38, blue: 0.26, alpha: 1.0),
                "meditation_garden": SKColor(red: 0.50, green: 0.38, blue: 0.26, alpha: 1.0),
            ],
            roomHeaderColors: [
                "koi_courtyard": SKColor(red: 0.52, green: 0.44, blue: 0.34, alpha: 1.0),
                "engawa": SKColor(red: 0.52, green: 0.44, blue: 0.34, alpha: 1.0),
            ],
            labelTextColor: SKColor(red: 0.22, green: 0.18, blue: 0.12, alpha: 1.0),
            solidWallColor: SKColor(red: 0.36, green: 0.26, blue: 0.16, alpha: 1.0),
            glassWallColor: SKColor(red: 0.94, green: 0.90, blue: 0.82, alpha: 1.0),  // Paper-white for shoji
            glassStrokeColor: SKColor(red: 0.56, green: 0.44, blue: 0.32, alpha: 0.6),
            rugColors: [
                "focus": SKColor(red: 0.76, green: 0.72, blue: 0.56, alpha: 0.50),
                "lounge": SKColor(red: 0.78, green: 0.74, blue: 0.58, alpha: 0.50),
                "collab": SKColor(red: 0.74, green: 0.70, blue: 0.54, alpha: 0.50),
                "build": SKColor(red: 0.76, green: 0.72, blue: 0.56, alpha: 0.50),
                "gallery": SKColor(red: 0.68, green: 0.66, blue: 0.60, alpha: 0.40),
                "custom1": SKColor(red: 0.72, green: 0.62, blue: 0.48, alpha: 0.45),
            ],
            tableColor: SKColor(red: 0.28, green: 0.18, blue: 0.10, alpha: 1.0),
            tableAccentColor: SKColor(red: 0.62, green: 0.50, blue: 0.36, alpha: 0.85),
            windowDaylightMorning: SKColor(red: 0.96, green: 0.92, blue: 0.80, alpha: 1.0),
            windowDaylightAfternoon: SKColor(red: 1.0, green: 0.98, blue: 0.92, alpha: 1.0),
            windowDaylightEvening: SKColor(red: 0.92, green: 0.78, blue: 0.56, alpha: 1.0),
            windowDaylightNight: SKColor(red: 0.88, green: 0.84, blue: 0.74, alpha: 1.0),
            dustMoteAlpha: 0.20,
            windowBlendFactor: 0.35
        )
    }

    // MARK: - Overgrown Ruins (dark concrete, nature green, bioluminescent accents)

    private static func overgrownRuins() -> WorldTheme {
        WorldTheme(
            backgroundColor: SKColor(red: 0.48, green: 0.52, blue: 0.46, alpha: 1.0),
            wallColor: SKColor(red: 0.58, green: 0.60, blue: 0.56, alpha: 1.0),
            floorColor: SKColor(red: 0.50, green: 0.54, blue: 0.48, alpha: 1.0),
            trimColor: SKColor(red: 0.36, green: 0.38, blue: 0.34, alpha: 1.0),
            roomFillColors: [
                "greenhouse_breach": SKColor(red: 0.52, green: 0.58, blue: 0.48, alpha: 1.0),
                "collapsed_wing": SKColor(red: 0.46, green: 0.48, blue: 0.44, alpha: 1.0),
                "tree_atrium": SKColor(red: 0.44, green: 0.52, blue: 0.42, alpha: 1.0),
                "mushroom_grove": SKColor(red: 0.38, green: 0.42, blue: 0.40, alpha: 1.0),
                "rooftop_opening": SKColor(red: 0.54, green: 0.58, blue: 0.50, alpha: 1.0),
                "server_room": SKColor(red: 0.42, green: 0.44, blue: 0.46, alpha: 1.0),
            ],
            roomBorderColors: [
                "collapsed_wing": SKColor(red: 0.40, green: 0.40, blue: 0.38, alpha: 1.0),
                "server_room": SKColor(red: 0.36, green: 0.38, blue: 0.40, alpha: 1.0),
            ],
            roomHeaderColors: [
                "tree_atrium": SKColor(red: 0.38, green: 0.46, blue: 0.36, alpha: 1.0),
                "mushroom_grove": SKColor(red: 0.32, green: 0.38, blue: 0.36, alpha: 1.0),
            ],
            labelTextColor: SKColor(red: 0.78, green: 0.82, blue: 0.74, alpha: 1.0),
            solidWallColor: SKColor(red: 0.34, green: 0.36, blue: 0.32, alpha: 1.0),
            glassWallColor: SKColor(red: 0.56, green: 0.60, blue: 0.56, alpha: 1.0),  // Cracked glass
            glassStrokeColor: SKColor(red: 0.42, green: 0.46, blue: 0.42, alpha: 0.7),
            rugColors: [
                "focus": SKColor(red: 0.32, green: 0.50, blue: 0.30, alpha: 0.40),
                "lounge": SKColor(red: 0.30, green: 0.44, blue: 0.28, alpha: 0.35),
                "collab": SKColor(red: 0.36, green: 0.52, blue: 0.34, alpha: 0.40),
                "build": SKColor(red: 0.28, green: 0.38, blue: 0.30, alpha: 0.30),
                "gallery": SKColor(red: 0.34, green: 0.48, blue: 0.32, alpha: 0.45),
                "custom1": SKColor(red: 0.25, green: 0.60, blue: 0.55, alpha: 0.20),
            ],
            tableColor: SKColor(red: 0.34, green: 0.36, blue: 0.32, alpha: 1.0),
            tableAccentColor: SKColor(red: 0.42, green: 0.54, blue: 0.40, alpha: 0.85),
            windowDaylightMorning: SKColor(red: 0.70, green: 0.78, blue: 0.60, alpha: 1.0),
            windowDaylightAfternoon: SKColor(red: 0.80, green: 0.86, blue: 0.72, alpha: 1.0),
            windowDaylightEvening: SKColor(red: 0.68, green: 0.62, blue: 0.44, alpha: 1.0),
            windowDaylightNight: SKColor(red: 0.30, green: 0.50, blue: 0.45, alpha: 1.0),  // Bioluminescent glow at night
            dustMoteAlpha: 0.35,
            windowBlendFactor: 0.50
        )
    }

    // MARK: - Helpers

    /// Returns the room fill color for a given room ID, with a default fallback.
    func roomFillColor(for roomID: String) -> SKColor {
        roomFillColors[roomID] ?? SKColor(red: 0.72, green: 0.76, blue: 0.70, alpha: 1.0)
    }

    /// Returns the room border color for a given room ID, with a default fallback.
    func roomBorderColor(for roomID: String) -> SKColor {
        roomBorderColors[roomID] ?? SKColor(red: 0.35, green: 0.40, blue: 0.35, alpha: 1.0)
    }

    /// Returns the room header color for a given room ID, with a default fallback.
    func roomHeaderColor(for roomID: String) -> SKColor {
        roomHeaderColors[roomID] ?? SKColor(red: 0.60, green: 0.64, blue: 0.58, alpha: 1.0)
    }

    /// Returns the display label for a room using the room's name directly.
    func roomLabel(for room: OfficeLayout.RoomDefinition) -> String {
        room.name
    }

    /// Returns a rug color by key, with a fallback.
    func rugColor(for key: String) -> SKColor {
        rugColors[key] ?? SKColor(red: 0.60, green: 0.56, blue: 0.48, alpha: 0.40)
    }

    /// Returns the daylight color for a given hour (0-23).
    func daylightColor(for hour: Int) -> SKColor {
        switch hour {
        case 6..<12:  return windowDaylightMorning
        case 12..<18: return windowDaylightAfternoon
        case 18..<21: return windowDaylightEvening
        default:      return windowDaylightNight
        }
    }
}
