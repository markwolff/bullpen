import SwiftUI
import SpriteKit
import SpriteWorld
import Services
import Models

/// The main content view that hosts the SpriteKit office scene
/// and a minimal toolbar showing agent information.
struct ContentView: View {
    @ObservedObject var monitorService: AgentMonitorService

    /// The selected world preset — loaded from persistence at init
    @State private var selectedWorldPreset: WorldPreset

    /// The SpriteKit office scene — initialized with the persisted preset
    @State private var officeScene: OfficeScene

    /// The agent currently selected for the detail popover (7.6)
    @State private var selectedAgentID: String?

    /// Whether the detail popover is shown
    @State private var showingPopover: Bool = false

    /// Whether the world picker menu is shown
    @State private var showingWorldMenu: Bool = false

    init(monitorService: AgentMonitorService) {
        self.monitorService = monitorService
        let preset = WorldPresetStore.load()
        _selectedWorldPreset = State(initialValue: preset)
        let scene = OfficeScene(worldPreset: preset)
        scene.scaleMode = .aspectFit
        _officeScene = State(initialValue: scene)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbar

            // Office area as a ZStack for overlays
            ZStack(alignment: .top) {
                // SpriteKit scene
                SpriteView(scene: officeScene)
                    .frame(minWidth: 512, minHeight: 384)
                    .ignoresSafeArea()
                    .popover(isPresented: $showingPopover, arrowEdge: .bottom) {
                        if let agentID = selectedAgentID,
                           let agent = monitorService.agents.first(where: { $0.id == agentID }) {
                            AgentDetailView(agent: agent)
                        }
                    }

                // World menu overlay
                if showingWorldMenu {
                    // Transparent scrim to close on outside click
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showingWorldMenu = false
                        }

                    WorldMenuOverlay(
                        currentPreset: selectedWorldPreset,
                        onSelect: { preset in
                            selectedWorldPreset = preset
                            WorldPresetStore.save(preset)
                            officeScene.applyWorld(preset)
                            showingWorldMenu = false
                        },
                        onDismiss: {
                            showingWorldMenu = false
                        }
                    )
                    .padding(.top, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(.easeInOut(duration: 0.15), value: showingWorldMenu)
        }
        .background(EscapeKeyMonitor(onEscape: handleEscapeKey))
        .onChange(of: monitorService.agents) { _, newAgents in
            officeScene.updateAgents(newAgents)
        }
        .onAppear {
            officeScene.onAgentClicked = { agentID in
                if let id = agentID {
                    selectedAgentID = id
                    showingPopover = true
                } else {
                    showingPopover = false
                    selectedAgentID = nil
                }
            }
        }
    }

    // MARK: - ESC Key Handling

    /// Handles ESC with exact priority:
    /// 1. Close popover first
    /// 2. Close world menu second
    /// 3. Open world menu if nothing else is open
    private func handleEscapeKey() {
        if showingPopover {
            showingPopover = false
            selectedAgentID = nil
        } else if showingWorldMenu {
            showingWorldMenu = false
        } else {
            showingWorldMenu = true
        }
    }

    // MARK: - Toolbar

    /// Minimal toolbar showing agent count and status summary
    @ViewBuilder
    private var toolbar: some View {
        HStack {
            Image(systemName: "desktopcomputer")
                .foregroundStyle(.secondary)

            Spacer()

            // Agent count
            let activeAgents = monitorService.agents.filter { $0.state != .finished && $0.state != .idle && !$0.isSubagent }.count
            let activeSubagents = monitorService.agents.filter { $0.state != .finished && $0.state != .idle && $0.isSubagent }.count
            let totalCount = monitorService.agents.count

            Group {
                if activeSubagents > 0 {
                    Text("\(activeAgents) agents, \(activeSubagents) subagents / \(totalCount) total")
                } else {
                    Text("\(activeAgents) active / \(totalCount) total")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            // Status dots for each agent
            HStack(spacing: 4) {
                ForEach(monitorService.agents) { agent in
                    Circle()
                        .fill(colorForState(agent.state))
                        .frame(width: 8, height: 8)
                        .help("\(agent.name): \(agent.state.displayLabel)")
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private func colorForState(_ state: AgentState) -> Color {
        let rgb = state.displayColorRGB
        return Color(red: rgb.red, green: rgb.green, blue: rgb.blue)
    }
}
