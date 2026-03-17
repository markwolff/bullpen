import Foundation
import UserNotifications
import Models

/// Manages macOS notifications for agent state changes.
/// Sends notifications when the window is not visible, such as when an agent
/// finishes a task or encounters an error.
@MainActor
public class NotificationService {
    private var permissionRequested = false

    /// Tracks last error notification time per agent for debouncing
    private var lastErrorNotificationTime: [String: Date] = [:]

    /// Minimum interval between error notifications for the same agent (seconds)
    private let errorDebounceInterval: TimeInterval = 30.0

    public init() {}

    /// Ensures notification permission has been requested.
    public func ensurePermission() async {
        guard !permissionRequested else { return }
        permissionRequested = true
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
        }
    }

    /// Sends a notification when an agent finishes its task.
    /// Only sends if the window is not currently visible.
    public func notifyAgentFinished(agent: AgentInfo, windowVisible: Bool) async {
        guard !windowVisible else { return }
        await ensurePermission()
        let content = UNMutableNotificationContent()
        content.title = "Agent finished"
        let dir = agent.workspacePath.flatMap { URL(fileURLWithPath: $0).lastPathComponent } ?? "session"
        content.body = "\(agent.name) completed in \(dir)"
        let request = UNNotificationRequest(identifier: "finished-\(agent.id)", content: content, trigger: nil)
        try? await UNUserNotificationCenter.current().add(request)
    }

    /// Sends a notification when an agent encounters an error.
    /// Only sends if the window is not currently visible. Debounces per agent.
    /// Removes cached state for a removed agent.
    public func cleanup(agentID: String) {
        lastErrorNotificationTime.removeValue(forKey: agentID)
    }

    public func notifyAgentError(agent: AgentInfo, windowVisible: Bool) async {
        guard !windowVisible else { return }

        // Debounce: don't send more than one error notification per agent within the interval
        let now = Date()
        if let lastTime = lastErrorNotificationTime[agent.id],
           now.timeIntervalSince(lastTime) < errorDebounceInterval {
            return
        }
        lastErrorNotificationTime[agent.id] = now

        await ensurePermission()
        let content = UNMutableNotificationContent()
        content.title = "Agent error"
        let errorSummary = String(agent.currentTaskDescription.prefix(100))
        let dir = agent.workspacePath.flatMap { URL(fileURLWithPath: $0).lastPathComponent } ?? "session"
        content.body = "\(agent.name) in \(dir): \(errorSummary)"
        content.sound = .default
        let request = UNNotificationRequest(identifier: "error-\(agent.id)", content: content, trigger: nil)
        try? await UNUserNotificationCenter.current().add(request)
    }
}
