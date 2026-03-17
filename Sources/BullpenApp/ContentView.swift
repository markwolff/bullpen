import SwiftUI
import SpriteKit
import SpriteWorld
import Services
import Models

/// The main content view that hosts the SpriteKit office scene
/// and a minimal toolbar showing agent information.
struct ContentView: View {
    @ObservedObject var monitorService: AgentMonitorService

    /// The SpriteKit office scene
    @State private var officeScene: OfficeScene = {
        let scene = OfficeScene()
        scene.scaleMode = .aspectFit
        return scene
    }()

    /// The agent currently selected for the detail popover (7.6)
    @State private var selectedAgentID: String?

    /// Whether the detail popover is shown
    @State private var showingPopover: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbar

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
        }
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
