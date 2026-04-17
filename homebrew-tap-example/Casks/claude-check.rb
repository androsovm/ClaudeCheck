# Place this file at Casks/claude-check.rb inside a tap repo named
# homebrew-tap (so users can install via `brew install --cask androsovm/tap/claude-check`).
# The release.yml workflow in the main repo bumps `version` + `sha256` on each tag push.

cask "claude-check" do
  version "0.1.0"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  url "https://github.com/androsovm/ClaudeCheck/releases/download/v#{version}/ClaudeCheck-#{version}.zip"
  name "ClaudeCheck"
  desc "Menu bar app showing Anthropic/Claude service health"
  homepage "https://github.com/androsovm/ClaudeCheck"

  depends_on macos: ">= :sonoma"

  app "ClaudeCheck.app"

  # Ad-hoc signed builds from CI land quarantined; strip the flag so the
  # first launch doesn't trip Gatekeeper. Users installing via brew never
  # see the "unidentified developer" dialog.
  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/ClaudeCheck.app"],
                   sudo: false
  end

  zap trash: [
    "~/Library/Preferences/com.androsovm.ClaudeCheck.plist",
    "~/Library/Application Support/ClaudeCheck",
  ]
end
