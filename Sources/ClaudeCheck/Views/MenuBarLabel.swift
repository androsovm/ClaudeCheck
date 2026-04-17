import SwiftUI

/// The always-visible label in the menu bar. Lives separately from the
/// dropdown so it can own lifecycle side-effects (start polling, react to
/// settings changes, fire notifications on severity transitions) without
/// waiting for the user to open the menu.
struct MenuBarLabel: View {
    @ObservedObject var poller: StatusPoller

    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("notifyOnlyDowntime")   private var notifyOnlyDowntime = true
    @AppStorage("pollIntervalSeconds")  private var pollIntervalSeconds: Int = 60

    var body: some View {
        MenuBarIcon(severity: poller.severity, showText: false)
            .onAppear {
                poller.start(interval: TimeInterval(pollIntervalSeconds))
                if notificationsEnabled {
                    Task { await NotificationManager.shared.requestAuthorizationIfNeeded() }
                }
            }
            .onChange(of: poller.severity) { oldValue, newValue in
                handleSeverityTransition(from: oldValue, to: newValue)
            }
            .onChange(of: pollIntervalSeconds) { _, new in
                poller.setInterval(TimeInterval(new))
            }
    }

    // MARK: - Notification logic

    private func handleSeverityTransition(from old: Severity, to new: Severity) {
        guard notificationsEnabled else { return }
        // Don't spam the user on the very first successful poll after launch.
        guard old != .unknown else { return }
        guard old != new else { return }

        if notifyOnlyDowntime {
            let wasDown = old.isDown
            let isDown = new.isDown
            if !wasDown && isDown {
                fireDownNotification()
            } else if wasDown && !isDown {
                fireRecoveryNotification()
            }
        } else {
            // "Any change" mode — notify on any category shift.
            if new.rawValue > old.rawValue {
                fireDownNotification(headline: new.headline)
            } else if new.rawValue < old.rawValue {
                fireRecoveryNotification(headline: new.headline)
            }
        }
    }

    private func fireDownNotification(headline: String? = nil) {
        let affected = poller.monitoredComponents
            .filter { $0.status.severity.isDown || $0.status.severity == .degraded }
            .map(\.name)
            .joined(separator: " + ")
        let title: String
        if let headline {
            title = headline
        } else if affected.isEmpty {
            title = "Claude is down"
        } else {
            title = "\(affected) is down"
        }
        NotificationManager.shared.notify(title: title, body: BreakMessages.randomDown())
    }

    private func fireRecoveryNotification(headline: String? = nil) {
        NotificationManager.shared.notify(
            title: headline ?? "Claude is back",
            body: BreakMessages.randomRecovery()
        )
    }
}
