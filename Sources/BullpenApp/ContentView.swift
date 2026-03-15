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
                .frame(minWidth: 800, minHeight: 600)
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

            Text("The Bullpen")
                .font(.headline)

            Spacer()

            // Agent count
            let activeCount = monitorService.agents.filter { $0.state != .finished && $0.state != .idle }.count
            let totalCount = monitorService.agents.count

            Text("\(activeCount) active / \(totalCount) total agents")
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
        switch state {
        case .idle: .gray
        case .thinking: .yellow
        case .writingCode: .green
        case .readingFiles: .cyan
        case .runningCommand: .orange
        case .searching: .purple
        case .waitingForInput: .blue
        case .error: .red
        case .finished: Color(white: 0.4)
        }
    }
}
