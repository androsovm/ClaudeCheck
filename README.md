# ClaudeCheck

![A developer happily sipping a cocktail on a beach chair while the laptop on his lap shows a sleeping robot — Claude is down, he's fine](Resources/preview.jpg)

> You've been yelling at Opus for an hour thinking it got lobotomized overnight.
> Turns out it was just down. A tiny dot in your menu bar could have saved you.
> Green = it's you. Red = it's them. Go touch grass either way.

A macOS menu bar app that watches [status.claude.com](https://status.claude.com) so you don't have to.

## Install

```sh
brew install --cask androsovm/tap/claude-check
```

Open the app. A Claude logo appears in your menu bar. Done.

> Requires macOS 14 (Sonoma) or later.

<details>
<summary>No Homebrew? Install manually</summary>

1. Grab the latest `ClaudeCheck-<version>.zip` from [Releases](https://github.com/androsovm/ClaudeCheck/releases).
2. Unzip, drag `ClaudeCheck.app` into `/Applications`.
3. First launch: right-click → **Open** (it's ad-hoc signed, not notarized), or:
   ```sh
   xattr -dr com.apple.quarantine /Applications/ClaudeCheck.app
   ```
</details>

## What the colors mean

| | |
| --- | --- |
| 🟢 | All good — keep vibing |
| 🟡 | Degraded — expect weirdness |
| 🟠 | Partial outage — some requests are toast |
| 🔴 | Major outage — close the laptop, open a window |
| ⚪ | Maintenance, or the status page itself is having a day |

Only **Claude API** and **Claude Code** drive the color. claude.ai, platform.claude.com, Cowork, and Government are tracked but don't trigger alerts — nobody needs a red dot because a dashboard is slow.

## Settings

Click the icon → the system Settings window (`⌘,`) has the knobs:

- **Show status text** — puts `OK` / `Degraded` / `DOWN` next to the icon.
- **Notifications** — ping you when things break (and when they come back).
  - *Only downtime* or *Any change*.
- **Check every** — 30s / 1min / 5min.
- **Launch at login**.

All off by default. No telemetry, no account, no network calls beyond the Statuspage URL.

## Uninstall

```sh
brew uninstall --cask claude-check
```

Or drag `ClaudeCheck.app` to the Trash. The cask's `zap` also removes the preferences plist — otherwise delete `~/Library/Preferences/com.androsovm.ClaudeCheck.plist` by hand.

## Build from source

```sh
git clone https://github.com/androsovm/ClaudeCheck
cd ClaudeCheck
make run          # build + launch
make app          # dist/ClaudeCheck.app
make release-zip  # universal (arm64 + x86_64) zip
```

Or open `Package.swift` in Xcode — there's no `.xcodeproj`.

See [CLAUDE.md](CLAUDE.md) for a tour of the code.

## License

MIT — see [LICENSE](LICENSE).
