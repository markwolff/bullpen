import Foundation
import UserNotifications
import Models

public struct NotificationMessage: Sendable, Equatable {
    public let identifier: String
    public let title: String
    public let body: String
    public let usesDefaultSound: Bool

    public init(identifier: String, title: String, body: String, usesDefaultSound: Bool) {
        self.identifier = identifier
        self.title = title
        self.body = body
        self.usesDefaultSound = usesDefaultSound
    }
}

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

    private let authorizationStatusProvider: @Sendable () async -> UNAuthorizationStatus
    private let authorizationRequester: @Sendable (UNAuthorizationOptions) async throws -> Bool
    private let notificationPoster: @Sendable (NotificationMessage) async throws -> Void
    private let nowProvider: @Sendable () -> Date

    public init(
        authorizationStatusProvider: @escaping @Sendable () async -> UNAuthorizationStatus = {
            await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        },
        authorizationRequester: @escaping @Sendable (UNAuthorizationOptions) async throws -> Bool = { options in
            try await UNUserNotificationCenter.current().requestAuthorization(options: options)
        },
        notificationPoster: @escaping @Sendable (NotificationMessage) async throws -> Void = { message in
            let content = UNMutableNotificationContent()
            content.title = message.title
            content.body = message.body
            if message.usesDefaultSound {
                content.sound = .default
            }

            let request = UNNotificationRequest(
                identifier: message.identifier,
                content: content,
                trigger: nil
            )
            try await UNUserNotificationCenter.current().add(request)
        },
        nowProvider: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.authorizationStatusProvider = authorizationStatusProvider
        self.authorizationRequester = authorizationRequester
        self.notificationPoster = notificationPoster
        self.nowProvider = nowProvider
    }

    /// Ensures notification permission has been requested.
    public func ensurePermission() async {
        guard !permissionRequested else { return }
        permissionRequested = true
        if await authorizationStatusProvider() == .notDetermined {
            _ = try? await authorizationRequester([.alert, .sound])
        }
    }

    /// Sends a notification when an agent finishes its task.
    /// Only sends if the window is not currently visible.
    public func notifyAgentFinished(agent: AgentInfo, windowVisible: Bool) async {
        guard !windowVisible else { return }
        await ensurePermission()
        let dir = agent.workspacePath.flatMap { URL(fileURLWithPath: $0).lastPathComponent } ?? "session"
        let message = NotificationMessage(
            identifier: "finished-\(agent.id)",
            title: "Agent finished",
            body: "\(agent.name) completed in \(dir)",
            usesDefaultSound: false
        )
        try? await notificationPoster(message)
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
        let now = nowProvider()
        if let lastTime = lastErrorNotificationTime[agent.id],
           now.timeIntervalSince(lastTime) < errorDebounceInterval {
            return
        }
        lastErrorNotificationTime[agent.id] = now

        await ensurePermission()
        let errorSummary = String(agent.currentTaskDescription.prefix(100))
        let dir = agent.workspacePath.flatMap { URL(fileURLWithPath: $0).lastPathComponent } ?? "session"
        let message = NotificationMessage(
            identifier: "error-\(agent.id)",
            title: "Agent error",
            body: "\(agent.name) in \(dir): \(errorSummary)",
            usesDefaultSound: true
        )
        try? await notificationPoster(message)
    }
}
