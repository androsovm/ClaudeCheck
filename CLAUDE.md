# ClaudeCheck — project map for Claude

A tiny macOS menu bar app (SwiftUI `MenuBarExtra`, `LSUIElement=true`) that polls
`https://status.claude.com/api/v2/summary.json` and shows whether Claude is up.
macOS 14+, Swift 5.9, SPM executable assembled into an `.app` via a shell script —
there is **no Xcode project file**; Xcode users open `Package.swift`.

## What it actually does

1. **Polls** Statuspage summary JSON on a timer (30 s / 1 min / 5 min, user-picked).
2. **Derives a single `Severity`** from the `max` of only two components —
   **Claude API** + **Claude Code** — matched by case-insensitive *prefix* on
   `Component.name` so minor rebrands don't break us. Everything else
   (claude.ai, platform.claude.com, Cowork, Government) is informational only.
3. **Renders the menu bar label** as the Claude logo (`Resources/Claude.svg`)
   tinted per severity, plus an optional short text label (`OK` / `Degraded` /
   `DOWN` / …). Falls back to `Severity.emoji` (🟢 🟡 🟠 💤 🔧 ⚫) if the SVG
   can't be loaded. We do **not** use SF Symbols or SwiftUI `.foregroundStyle`
   for the tint — `MenuBarExtra` labels don't reliably propagate either. See
   *Menu bar icon* under gotchas.
4. **Opens a dropdown** with: headline (random break quip on outage),
   monitored components with colored dot + status, relevant incidents
   (linkable), Refresh / Open status page / Quit. `StatusPoller` also
   exposes `otherComponents` and `lastUpdated`, but the current
   `MenuContent` does not render them — see *Gaps* below.
5. **Fires macOS notifications** on severity transitions. Two modes:
   *Only downtime* (partial+major on/off) or *Any change*. Silent on the
   first poll after launch (skips `.unknown → X` so we don't spam at start).
6. **Persists settings** via `@AppStorage` (`UserDefaults`):
   `showStatusText`, `notificationsEnabled`, `notifyOnlyDowntime`,
   `pollIntervalSeconds`, `launchAtLogin`. Launch-at-login uses
   `SMAppService.mainApp`.

## Code layout

```
Sources/ClaudeCheck/
├── ClaudeCheckApp.swift      @main — MenuBarExtra + Settings scenes
├── Models/
│   ├── StatusSummary.swift   summary.json decoder (snake_case → camelCase)
│   ├── Component.swift       Component + ComponentStatus enum
│   ├── Incident.swift        Incident + IncidentImpact enum
│   └── Severity.swift        Our derived enum (ok/maint/degraded/partial/down/unknown)
├── Services/
│   ├── StatusPoller.swift    @MainActor ObservableObject; the only async logic
│   ├── NotificationManager.swift   UNUserNotificationCenter wrapper (singleton)
│   └── LaunchAtLogin.swift   SMAppService shim
├── Views/
│   ├── MenuBarIcon.swift     tinted Claude logo (NSImage mask) + optional shortLabel; emoji fallback
│   ├── MenuBarLabel.swift    owns lifecycle: start poller, severity transitions → notifications
│   ├── MenuContent.swift     dropdown tree (Buttons, Dividers, Menus)
│   └── SettingsView.swift    Form-based settings window
└── Utils/BreakMessages.swift Random English quips for down/recovery

Resources/
├── Info.plist                 __VERSION__ placeholder, LSUIElement=true
└── Claude.svg                 menu-bar logo; tinted per severity at runtime
```

## Severity model (important)

`Severity` is `Int`-backed and `Comparable` so we can take `max()` across
components. Order: `unknown(-1) < ok(0) < maintenance(1) < degraded(2) < partial(3) < down(4)`.
`isDown` is **partial OR down only** — degraded does *not* count as down
(used by the "Only downtime" notification filter).

`computeSeverity` falls back to the page-wide `status.indicator` only when
no monitored components are found (e.g., if Anthropic renames them).

Color palette for the tinted logo (`Severity.color`):
`ok` green · `degraded` yellow · `partial` magenta `rgb(242,64,140)` ·
`down` red · `maintenance`/`unknown` gray. `partial` deliberately isn't
`.orange` — that's Anthropic's brand color and would read as "normal
branding" rather than a warning.

## Build / release

- `make app` → `./Scripts/build-app.sh` → `dist/ClaudeCheck.app` (ad-hoc signed, native arch).
  The script also copies `Resources/Claude.svg` into `Contents/Resources/`
  (and `AppIcon.icns` if present).
- `make run` → builds + `open`s it.
- `make release-zip VERSION=x.y.z` → universal (arm64 + x86_64) zip in `dist/`.
- `Info.plist` has `__VERSION__` placeholders that `build-app.sh` substitutes with `sed`.
- CI: `.github/workflows/release.yml` fires on `v*` tags → builds universal zip,
  creates a GitHub Release, then bumps `Casks/claude-check.rb` in the
  `androsovm/homebrew-tap` repo (version + sha256). `HOMEBREW_TAP_TOKEN`
  secret is set; first working release was `v0.1.0` on 2026-04-17.
- Distribution: `brew install --cask androsovm/tap/claude-check`. Cask
  `postflight` strips quarantine because we don't have a Developer ID
  (ad-hoc signed, not notarized).

## Conventions / gotchas

- **Menu bar icon tinting**: tint the Claude logo at the `NSImage` level,
  not via SwiftUI. `MenuBarIcon.swift` loads `Claude.svg` via
  `NSImage(contentsOf:)` (macOS 14's `_NSSVGImageRep` handles SVG
  natively), then for each severity builds a tinted `NSImage` with
  `NSImage(size:, flipped:) { ... }` — fill the rect with
  `severity.color`, composite the base image with
  `operation: .destinationIn` to use its alpha as a mask, set
  `isTemplate = false` so macOS doesn't override the color. Results are
  cached per-severity. `.foregroundStyle` + `.renderingMode(.template)`
  on SwiftUI `Image` does **not** work inside a `MenuBarExtra` label.
- **SVG em-size quirk**: our logo declares `width="1em" height="1em"`,
  which `_NSSVGImageRep` resolves to `size = 1×1 pt`. Always override
  `image.size = NSSize(...)` right after load or rasterization collapses
  to a single pixel.
- **Debug severity cycle**: `StatusPoller.debugCycleSeverities` (default
  `false`). When `true`, skips real polling and cycles `severity`
  through every case every 5s so you can eyeball all six tinted states
  without waiting for an outage. Flip on locally, rebuild, flip off
  before committing.
- All state in `StatusPoller` is `@MainActor` — UI reads `@Published`
  props directly, no thread hops.
- On fetch error we keep the last-known `severity` (only reset to `.unknown`
  if we've never had a successful poll). `lastError` is surfaced in the
  menu headline.
- Settings window: there is currently **no** "Settings" item in
  `MenuContent`. Users open settings via the system `Settings` scene
  (`⌘,` when the app is frontmost) or via the app menu. The previously
  documented `NSApp.activate(...)` + `showSettingsWindow:` workaround is
  not wired up right now — add it back if/when a Settings button returns
  to the dropdown.
- Bundle ID: `com.androsovm.ClaudeCheck`. User defaults plist is
  `~/Library/Preferences/com.androsovm.ClaudeCheck.plist` (the cask `zap`s it).
- No tests yet. No analytics, no crash reporter, no network calls beyond
  the single Statuspage URL.

## Gaps vs. the original design

Things listed above that `StatusPoller` supports but `MenuContent` does
not currently render:

- **"Other services" submenu** — `poller.otherComponents` is computed
  (claude.ai, platform.claude.com, Cowork, Government) but not shown.
- **"Last checked …" relative time** — `poller.lastUpdated` is tracked
  but no row surfaces it.
- **Settings button** — no entry in the dropdown; see gotcha above.
- **`fireDownNotification` affected-component list** skips
  `.maintenance` (only `.isDown || .degraded` are listed), so "Any
  change" notifications into maintenance fall back to the headline.
