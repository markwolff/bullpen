import SwiftUI
import Models

/// A compact transient card showing world presets and display mode.
///
/// Appears as an overlay anchored near the top of the office area.
/// Selecting a preset fires the `onSelect` closure and the parent
/// view handles persistence and scene switching.
struct WorldMenuOverlay: View {
    let currentPreset: WorldPreset
    let currentDisplayMode: DisplayMode
    let onSelect: (WorldPreset) -> Void
    let onDisplayModeChange: (DisplayMode) -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("SETTINGS")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("ESC to close")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 6)

            Divider()

            // World preset section
            sectionHeader("WORLD")

            VStack(spacing: 2) {
                ForEach(WorldPreset.allCases) { preset in
                    presetRow(preset)
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 6)

            Divider()

            // Display mode section
            sectionHeader("DISPLAY")

            VStack(spacing: 2) {
                ForEach(DisplayMode.allCases) { mode in
                    displayModeRow(mode)
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
            .padding(.bottom, 4)
        }
        .frame(width: 260)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 4)
    }

    // MARK: - Section Header

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.top, 6)
        .padding(.bottom, 2)
    }

    // MARK: - Display Mode Row

    @ViewBuilder
    private func displayModeRow(_ mode: DisplayMode) -> some View {
        Button {
            onDisplayModeChange(mode)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: mode == .window ? "macwindow" : "menubar.rectangle")
                    .frame(width: 20)
                    .foregroundStyle(mode == currentDisplayMode ? .primary : .secondary)

                Text(mode.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)

                Spacer()

                if mode == currentDisplayMode {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                mode == currentDisplayMode
                    ? Color.primary.opacity(0.08)
                    : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func presetRow(_ preset: WorldPreset) -> some View {
        Button {
            onSelect(preset)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: preset.symbolName)
                    .frame(width: 20)
                    .foregroundStyle(preset == currentPreset ? .primary : .secondary)

                VStack(alignment: .leading, spacing: 1) {
                    Text(preset.title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.primary)
                    Text(preset.subtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if preset == currentPreset {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                preset == currentPreset
                    ? Color.primary.opacity(0.08)
                    : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
