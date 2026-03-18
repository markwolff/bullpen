import Foundation

// MARK: - Notification

public extension Notification.Name {
    /// Posted when the user changes the display mode from the ESC overlay.
    static let displayModeChanged = Notification.Name("displayModeChanged")
}

// MARK: - DisplayMode

/// The display mode for the Bullpen office scene.
///
/// Users can switch between a standard draggable window and a compact
/// always-on-top panel anchored to the menu bar icon.
public enum DisplayMode: String, CaseIterable, Sendable, Identifiable {
    case window
    case menuBarPanel

    // MARK: - Identifiable

    public var id: String { rawValue }

    // MARK: - Display Metadata

    /// Human-readable title shown in the context menu.
    public var title: String {
        switch self {
        case .window:       return "Window"
        case .menuBarPanel: return "Menu Bar"
        }
    }

    /// Whether this is the default display mode.
    public var isDefault: Bool { self == .window }
}
