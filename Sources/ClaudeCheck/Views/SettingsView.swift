import SwiftUI

struct SettingsView: View {
    @AppStorage("showStatusText")       private var showStatusText = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("notifyOnlyDowntime")   private var notifyOnlyDowntime = true
    @AppStorage("pollIntervalSeconds")  private var pollIntervalSeconds: Int = 60
    @AppStorage("launchAtLogin")        private var launchAtLogin = false

    var body: some View {
        Form {
            Section("Display") {
                Toggle("Show status text in menu bar", isOn: $showStatusText)
            }

            Section("Notifications") {
                Toggle("Notify on status changes", isOn: $notificationsEnabled)
                    .onChange(of: notificationsEnabled) { _, newValue in
                        if newValue {
                            Task { await NotificationManager.shared.requestAuthorizationIfNeeded() }
                        }
                    }
                Picker("Notify on", selection: $notifyOnlyDowntime) {
                    Text("Only downtime (partial + major)").tag(true)
                    Text("Any status change").tag(false)
                }
                .disabled(!notificationsEnabled)
            }

            Section("Polling") {
                Picker("Check every", selection: $pollIntervalSeconds) {
                    Text("30 seconds").tag(30)
                    Text("1 minute").tag(60)
                    Text("5 minutes").tag(300)
                }
            }

            Section("Startup") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        LaunchAtLogin.isEnabled = newValue
                    }
            }

            Section {
                Link("Source on GitHub",
                     destination: URL(string: "https://github.com/androsovm/ClaudeCheck")!)
                Link("Anthropic status page",
                     destination: URL(string: "https://status.claude.com")!)
            } footer: {
                Text("ClaudeCheck v\(appVersion)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 480)
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
    }
}
