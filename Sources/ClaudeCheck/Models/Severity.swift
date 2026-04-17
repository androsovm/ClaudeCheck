import SwiftUI

/// Locally-derived severity, computed from the monitored components only
/// (Claude API + Claude Code). Ordered from "all good" to "very bad" so we
/// can take `.max()` across multiple components.
enum Severity: Int, Comparable {
    case unknown = -1   // never polled yet / network error on first fetch
    case ok = 0
    case maintenance = 1
    case degraded = 2
    case partial = 3
    case down = 4

    static func < (lhs: Severity, rhs: Severity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var color: Color {
        switch self {
        case .ok:           return .green
        case .maintenance:  return .gray
        case .degraded:     return .yellow
        // Not `.orange`: that's Anthropic's brand color, so an orange logo
        // reads as "normal branding" rather than "something is wrong".
        case .partial:      return Color(red: 0.95, green: 0.25, blue: 0.55)
        case .down:         return .red
        case .unknown:      return .gray
        }
    }

    /// SF Symbol for the menu bar. Same "sparkle" shape across healthy-ish
    /// states (color carries the signal), but when the service is actually
    /// down we switch to a moon-with-zzz — Claude is literally asleep.
    /// Different shape for a different mood, matching the playful tone.
    var symbolName: String {
        switch self {
        case .ok:           return "sparkle"
        case .degraded:     return "sparkle"
        case .partial:      return "sparkle"
        case .down:         return "moon.zzz.fill"
        case .maintenance:  return "wrench.and.screwdriver.fill"
        case .unknown:      return "questionmark.circle"
        }
    }

    /// Emoji shown in the menu bar itself. We use emoji (not SF Symbols)
    /// because `Image(systemName:)` in a `MenuBarExtra` label is always
    /// template-tinted by macOS, and `Text(Image(...))` renders as an
    /// empty glyph for some symbols. Emoji bypass both issues.
    ///
    /// Minimal "mood" storytelling: colored dots for normal states, but
    /// when things are actually down we swap to 💤 so you can tell at a
    /// glance (and colorblind-safely) that it's break time.
    var emoji: String {
        switch self {
        case .ok:           return "🟢"
        case .degraded:     return "🟡"
        case .partial:      return "🟠"
        case .down:         return "💤"
        case .maintenance:  return "🔧"
        case .unknown:      return "⚫"
        }
    }

    var isOK: Bool { self == .ok }

    /// "Down enough that a human should care" — partial or major outage.
    /// Degraded performance does NOT count as down (used for "Only downtime" notification mode).
    var isDown: Bool { self == .partial || self == .down }

    var headline: String {
        switch self {
        case .ok:           return "All good."
        case .degraded:     return "Degraded performance."
        case .partial:      return "Partial outage."
        case .down:         return "Claude is down."
        case .maintenance:  return "Scheduled maintenance."
        case .unknown:      return "Can't reach status page."
        }
    }

    /// Very short label shown next to the menu bar icon when the user opts in.
    var shortLabel: String {
        switch self {
        case .ok:           return "OK"
        case .degraded:     return "Degraded"
        case .partial:      return "Partial"
        case .down:         return "DOWN"
        case .maintenance:  return "Maint"
        case .unknown:      return "?"
        }
    }
}
