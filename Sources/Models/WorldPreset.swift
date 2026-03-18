import Foundation

// MARK: - WorldPreset

/// One of five selectable visual world presets for the office scene.
///
/// Each preset defines a distinct color palette and room label set while
/// sharing the same geometry, desk count, and room IDs from ``OfficeLayout``.
public enum WorldPreset: String, CaseIterable, Codable, Sendable, Identifiable {
    case classicBullpen
    case libraryLoft
    case greenhouseStudio
    case missionControl
    case nightShift

    // MARK: - Identifiable

    public var id: String { rawValue }

    // MARK: - Display Metadata

    /// Human-readable title shown in the world picker.
    public var title: String {
        switch self {
        case .classicBullpen:    return "Classic Bullpen"
        case .libraryLoft:       return "Library Loft"
        case .greenhouseStudio:  return "Greenhouse Studio"
        case .missionControl:    return "Mission Control"
        case .nightShift:        return "Night Shift"
        }
    }

    /// Short tagline describing the palette.
    public var subtitle: String {
        switch self {
        case .classicBullpen:    return "The cozy original"
        case .libraryLoft:       return "Walnut & parchment"
        case .greenhouseStudio:  return "Sage & glass"
        case .missionControl:    return "Slate & cyan"
        case .nightShift:        return "Indigo & amber"
        }
    }

    /// SF Symbol name for the world picker card.
    public var symbolName: String {
        switch self {
        case .classicBullpen:    return "building.2"
        case .libraryLoft:       return "books.vertical"
        case .greenhouseStudio:  return "leaf"
        case .missionControl:    return "antenna.radiowaves.left.and.right"
        case .nightShift:        return "moon.stars"
        }
    }

    /// Longer description for the world picker detail view.
    public var description: String {
        switch self {
        case .classicBullpen:
            return "Warm wood and sage tones with the original office layout."
        case .libraryLoft:
            return "A quiet reading room with walnut shelves and warm parchment tones."
        case .greenhouseStudio:
            return "A bright studio filled with natural light and glass partitions."
        case .missionControl:
            return "A high-tech command center with cool slate and cyan accents."
        case .nightShift:
            return "A moody after-hours office bathed in indigo and warm amber light."
        }
    }

    /// Whether this is the default preset for new installs.
    public var isDefault: Bool { self == .classicBullpen }

    // MARK: - Room Label Overrides

    /// Display label overrides keyed by room ID.
    ///
    /// An empty dictionary means the preset uses the default labels from ``OfficeLayout``.
    /// Non-default presets override all six room labels.
    public var roomLabelOverrides: [String: String] {
        switch self {
        case .classicBullpen:
            return [:]
        case .libraryLoft:
            return [
                "focus_studio": "Reading Room",
                "recreation_lounge": "Fireside Lounge",
                "circulation_spine": "Aisle",
                "gallery": "Stacks",
                "collaboration_room": "Seminar Room",
                "build_room": "Bindery",
            ]
        case .greenhouseStudio:
            return [
                "focus_studio": "Focus Studio",
                "recreation_lounge": "Garden Lounge",
                "circulation_spine": "Glass Walk",
                "gallery": "Atrium",
                "collaboration_room": "Studio",
                "build_room": "Potting Bench",
            ]
        case .missionControl:
            return [
                "focus_studio": "Focus Pods",
                "recreation_lounge": "Crew Lounge",
                "circulation_spine": "Central Corridor",
                "gallery": "Telemetry Bay",
                "collaboration_room": "War Room",
                "build_room": "Build Lab",
            ]
        case .nightShift:
            return [
                "focus_studio": "Quiet Room",
                "recreation_lounge": "Break Nook",
                "circulation_spine": "Night Walk",
                "gallery": "After Hours",
                "collaboration_room": "Team Room",
                "build_room": "Ops Room",
            ]
        }
    }
}
