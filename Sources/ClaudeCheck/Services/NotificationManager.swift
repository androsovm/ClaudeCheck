import UserNotifications

/// Thin wrapper around UNUserNotificationCenter. All methods are best-effort —
/// if the user never granted permission, notifications silently no-op.
@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private var granted = false

    private init() {}

    /// Request `.alert + .sound` on first enable. Subsequent calls are cheap —
    /// macOS caches the decision.
    func requestAuthorizationIfNeeded() async {
        do {
            granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
        } catch {
            granted = false
        }
    }

    /// Fires-and-forgets a simple alert notification. No-op if permission
    /// was never granted.
    func notify(title: String, body: String) {
        guard granted else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request) { _ in }
    }
}
