import SwiftUI
import Models

/// A detail popover view displaying comprehensive information about a single agent. (7.6)
struct AgentDetailView: View {
    let agent: AgentInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: name + type badge
            HStack {
                Text(agent.name).font(.headline)
                Spacer()
                Text(agent.agentType == .claudeCode ? "Claude Code" : "Codex CLI")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(agent.agentType == .claudeCode ? Color.orange.opacity(0.2) : Color.blue.opacity(0.2))
                    .cornerRadius(4)
            }

            Divider()

            // Current state
            HStack {
                Circle()
                    .fill(colorForState(agent.state))
                    .frame(width: 8, height: 8)
                Text(agent.state.displayLabel)
                    .font(.subheadline)
                Text("· \(stateDurationText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Current activity
            if !agent.currentTaskDescription.isEmpty {
                Text(agent.currentTaskDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Session info
            LabeledContent("Session") {
                Text(sessionDurationText)
                    .font(.caption)
            }

            // Token usage
            LabeledContent("Tokens") {
                Text("In: \(agent.totalInputTokens.formatted()) · Out: \(agent.totalOutputTokens.formatted())")
                    .font(.caption)
            }

            // Working directory
            if let dir = agent.workspacePath {
                LabeledContent("Directory") {
                    Text(dir)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            // Recent tools
            if !agent.recentTools.isEmpty {
                Divider()
                Text("Recent Activity").font(.caption).foregroundStyle(.secondary)
                ForEach(agent.recentTools.indices, id: \.self) { i in
                    HStack {
                        Circle()
                            .fill(colorForState(agent.recentTools[i].activityType.correspondingAgentState))
                            .frame(width: 4, height: 4)
                        Text(agent.recentTools[i].summary)
                            .font(.caption2)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding()
        .frame(width: 280)
    }

    // MARK: - Computed Properties

    private var stateDurationText: String {
        let elapsed = Date.now.timeIntervalSince(agent.stateEnteredAt)
        return Self.formatDuration(elapsed)
    }

    private var sessionDurationText: String {
        let elapsed = Date.now.timeIntervalSince(agent.startedAt)
        return Self.formatDuration(elapsed)
    }

    /// Formats a duration in seconds into a human-readable string.
    static func formatDuration(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(max(0, seconds))
        if totalSeconds < 60 {
            return "\(totalSeconds)s"
        }
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        if minutes < 60 {
            return "\(minutes)m \(secs)s"
        }
        let hours = minutes / 60
        let mins = minutes % 60
        return "\(hours)h \(mins)m"
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
        case .supervisingAgents: .teal
        case .deepThinking: .orange
        }
    }
}
