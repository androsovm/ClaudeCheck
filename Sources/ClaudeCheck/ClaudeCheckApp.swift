import SwiftUI

@main
struct ClaudeCheckApp: App {
    @StateObject private var poller = StatusPoller()

    var body: some Scene {
        MenuBarExtra {
            MenuContent(poller: poller)
        } label: {
            MenuBarLabel(poller: poller)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
        }
    }
}
