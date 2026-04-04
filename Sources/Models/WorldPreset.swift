import Foundation

// MARK: - WorldPreset

/// One of the selectable world presets, each with a unique layout,
/// furniture set, decorations, and color palette.
///
/// Unlike earlier versions which shared geometry and only varied colors,
/// each preset now maps to a completely different ``OfficeLayout`` with
/// its own rooms, desks, barriers, and points of interest.
public enum WorldPreset: String, CaseIterable, Codable, Sendable, Identifiable {
    case classicBullpen
    case zenStudio
    case overgrownRuins
    case livingOffice

    // MARK: - Identifiable

    public var id: String { rawValue }

    // MARK: - Display Metadata

    /// Human-readable title shown in the world picker.
    public var title: String {
        switch self {
        case .classicBullpen: return "Classic Bullpen"
        case .zenStudio:      return "Zen Studio"
        case .overgrownRuins: return "Overgrown Ruins"
        case .livingOffice:   return "Living Office"
        }
    }

    /// Short tagline describing the world.
    public var subtitle: String {
        switch self {
        case .classicBullpen: return "The cozy original"
        case .zenStudio:      return "Tatami & tranquility"
        case .overgrownRuins: return "Nature reclaims tech"
        case .livingOffice:   return "Expands with the crew"
        }
    }

    /// SF Symbol name for the world picker card.
    public var symbolName: String {
        switch self {
        case .classicBullpen: return "building.2"
        case .zenStudio:      return "leaf.circle"
        case .overgrownRuins: return "tree"
        case .livingOffice:   return "rectangle.3.group.bubble"
        }
    }

    /// Longer description for the world picker detail view.
    public var description: String {
        switch self {
        case .classicBullpen:
            return "Warm wood and sage tones. The cozy startup office where it all began."
        case .zenStudio:
            return "A serene Japanese workspace with tatami floors, shoji screens, and a koi pond courtyard."
        case .overgrownRuins:
            return "A crumbling research lab consumed by nature. Vines on server racks, mushrooms in dark corners, a tree through the ceiling."
        case .livingOffice:
            return "A responsive bullpen that starts compact, opens more desks as the team grows, and settles back down when the office empties."
        }
    }

    /// Whether this is the default preset for new installs.
    public var isDefault: Bool { self == .classicBullpen }
}
