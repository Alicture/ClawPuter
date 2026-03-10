#!/bin/bash
# Build and run CardputerDesktopPet as a proper .app bundle.
# Launched via 'open' so macOS LaunchServices properly registers
# the bundle for TCC (local network permission prompt).

set -e
cd "$(dirname "$0")"

APP_NAME="CardputerDesktopPet"
BUNDLE="$APP_NAME.app"
CONTENTS="$BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"

# Build
swift build

# Create .app bundle structure
rm -rf "$BUNDLE"
mkdir -p "$MACOS"
cp Info.plist "$CONTENTS/"
cp ".build/arm64-apple-macosx/debug/$APP_NAME" "$MACOS/"

# Ad-hoc sign the bundle (required for local network permission)
codesign --force --sign - "$BUNDLE"

echo "=== Launching $BUNDLE ==="
echo "First launch: macOS should ask for Local Network permission — click Allow."
echo ""
echo "Logs below (press Ctrl+C to stop):"
echo "---"

# Launch via LaunchServices (triggers TCC prompt)
open "$BUNDLE"

# Stream app logs from unified logging
sleep 0.5
log stream --predicate 'process == "CardputerDesktopPet"' --level info --style compact 2>/dev/null
