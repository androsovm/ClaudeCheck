import SwiftUI

/// The dropdown rendered when the user clicks our menu bar icon.
/// Uses MenuBarExtra's default `.menu` style — so this is an NSMenu-like
/// tree of Buttons, Dividers, and Menus (submenus).
struct MenuContent: View {
    @ObservedObject var poller: StatusPoller
    @Environment(\.openURL) private var openURL

    var body: some View {
        // 1. Headline: changes with severity. For partial/major outages we
        //    show a random break quip instead of a dry sentence.
        Text(headlineText)

        Divider()

        // 2. Monitored services — always shown (these drive the icon).
        ForEach(poller.monitoredComponents) { component in
            componentRow(component)
        }

        // 3. Active incidents affecting monitored components.
        if !poller.relevantIncidents.isEmpty {
            Divider()
            ForEach(poller.relevantIncidents) { incident in
                Button("\(incident.status.capitalized): \(incident.name)") {
                    if let link = incident.shortlink, let url = URL(string: link) {
                        openURL(url)
                    } else {
                        openURL(URL(string: "https://status.claude.com")!)
                    }
                }
            }
        }

        Divider()

        Button("Refresh now") { poller.refresh() }
            .keyboardShortcut("r")

        Button("Open status.claude.com") {
            openURL(URL(string: "https://status.claude.com")!)
        }

        Divider()

        Button("Quit ClaudeCheck") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    // MARK: - Subviews

    @ViewBuilder
    private func componentRow(_ component: Component) -> some View {
        // We'd prefer a colored dot next to the label. In the .menu style,
        // SF Symbols render monochrome based on the system accent, so we
        // use a character dot that accepts foregroundStyle reliably — and
        // fall back to text if even that is stripped by NSMenu.
        Label {
            Text("\(component.name) — \(component.status.displayName)")
        } icon: {
            Image(systemName: "circle.fill")
                .foregroundStyle(component.status.severity.color)
        }
    }

    private var headlineText: String {
        switch poller.severity {
        case .ok:           return "✓ All good."
        case .degraded:     return "⚠ Degraded performance."
        case .partial:      return BreakMessages.randomDown()
        case .down:         return BreakMessages.randomDown()
        case .maintenance:  return "🛠 Scheduled maintenance."
        case .unknown:
            if let err = poller.lastError {
                return "Can't reach status page — \(err)"
            }
            return "Checking…"
        }
    }

}
