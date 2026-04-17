import Foundation
import ServiceManagement

/// Best-effort wrapper around SMAppService for the "Launch at login" toggle.
/// Requires the app to be installed in /Applications (or similar) and run at
/// least once — macOS won't register a quarantined or ad-hoc-signed binary
/// from arbitrary locations in all cases.
enum LaunchAtLogin {
    static var isEnabled: Bool {
        get {
            SMAppService.mainApp.status == .enabled
        }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                // Swallow — the Settings toggle will just reflect the next read.
                // Surfacing this via UI can come later if users hit it.
            }
        }
    }
}
