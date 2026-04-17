#!/usr/bin/env bash
# Assembles ClaudeCheck.app from the Swift executable produced by `swift build`.
# Usage:
#   ./Scripts/build-app.sh                 # native arch, ad-hoc signed
#   ARCHS="arm64 x86_64" ./Scripts/build-app.sh   # universal
#   VERSION=1.2.3 ./Scripts/build-app.sh           # stamp a specific version

set -euo pipefail

APP_NAME="ClaudeCheck"
VERSION="${VERSION:-0.1.0}"
CONFIG="${CONFIG:-release}"
ARCHS="${ARCHS:-$(uname -m)}"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

DIST_DIR="$REPO_ROOT/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"

# Build arch flags: "arm64 x86_64" -> "--arch arm64 --arch x86_64"
ARCH_FLAGS=()
for a in $ARCHS; do
  ARCH_FLAGS+=(--arch "$a")
done

echo "==> swift build -c $CONFIG ${ARCH_FLAGS[*]}"
swift build -c "$CONFIG" "${ARCH_FLAGS[@]}"

BIN_DIR="$(swift build --show-bin-path -c "$CONFIG" "${ARCH_FLAGS[@]}")"
BIN="$BIN_DIR/$APP_NAME"
if [[ ! -x "$BIN" ]]; then
  echo "ERROR: built binary not found at $BIN" >&2
  exit 1
fi

echo "==> Assembling $APP_DIR"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$BIN" "$APP_DIR/Contents/MacOS/$APP_NAME"

# Info.plist: substitute version
sed "s/__VERSION__/$VERSION/g" "$REPO_ROOT/Resources/Info.plist" \
  > "$APP_DIR/Contents/Info.plist"

# Optional icon (not shown in menu bar but used if we ever surface the app in Dock/Finder)
if [[ -f "$REPO_ROOT/Resources/AppIcon.icns" ]]; then
  cp "$REPO_ROOT/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/"
fi

# Menu bar logo. Shipped as SVG; macOS 14 loads it via NSImage natively.
if [[ -f "$REPO_ROOT/Resources/Claude.svg" ]]; then
  cp "$REPO_ROOT/Resources/Claude.svg" "$APP_DIR/Contents/Resources/"
fi

# Ad-hoc sign so Gatekeeper lets it launch on the build machine.
# CI can re-sign + notarize with a real Developer ID afterward.
codesign --force --deep --sign - "$APP_DIR" >/dev/null

echo "✓ Built $APP_DIR (version $VERSION, archs: $ARCHS)"
