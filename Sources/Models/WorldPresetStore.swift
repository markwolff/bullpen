import Foundation

// MARK: - WorldPresetStore

/// Persistence helper for the user's selected world preset.
///
/// Backed by `UserDefaults`. Invalid or missing persisted values
/// fall back to ``WorldPreset/classicBullpen``.
public struct WorldPresetStore: Sendable {

    /// The `UserDefaults` key used to store the selected preset.
    public static let key = "selectedWorldPreset"

    /// Load the persisted preset.
    ///
    /// Returns ``WorldPreset/classicBullpen`` when the stored value is
    /// `nil` or does not match any known case.
    public static func load(from defaults: UserDefaults = .standard) -> WorldPreset {
        guard let raw = defaults.string(forKey: key),
              let preset = WorldPreset(rawValue: raw) else {
            return .classicBullpen
        }
        return preset
    }

    /// Persist the selected preset.
    public static func save(_ preset: WorldPreset, to defaults: UserDefaults = .standard) {
        defaults.set(preset.rawValue, forKey: key)
    }
}
