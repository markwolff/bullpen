import Foundation

// MARK: - DisplayModeStore

/// Persistence helper for the user's selected display mode.
///
/// Backed by `UserDefaults`. Invalid or missing persisted values
/// fall back to ``DisplayMode/window``.
public struct DisplayModeStore: Sendable {

    /// The `UserDefaults` key used to store the selected display mode.
    public static let key = "selectedDisplayMode"

    /// Load the persisted display mode.
    ///
    /// Returns ``DisplayMode/window`` when the stored value is
    /// `nil` or does not match any known case.
    public static func load(from defaults: UserDefaults = .standard) -> DisplayMode {
        guard let raw = defaults.string(forKey: key),
              let mode = DisplayMode(rawValue: raw) else {
            return .window
        }
        return mode
    }

    /// Persist the selected display mode.
    public static func save(_ mode: DisplayMode, to defaults: UserDefaults = .standard) {
        defaults.set(mode.rawValue, forKey: key)
    }
}
