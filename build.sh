#!/bin/bash
# Builds ClaudeSessionTracker.app from the Swift package.
# Requires macOS + Xcode command line tools (run: xcode-select --install).

set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="ClaudeSessionTracker"
BUILD_CONFIG="release"

echo "Building $APP_NAME ($BUILD_CONFIG)..."
swift build -c "$BUILD_CONFIG"

BIN_PATH=".build/$BUILD_CONFIG/$APP_NAME"
APP_BUNDLE="$APP_NAME.app"

echo "Packaging $APP_BUNDLE..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BIN_PATH" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

echo "Done. Move $APP_BUNDLE to /Applications, then double-click to launch."
echo "(First launch: right-click > Open, since it isn't notarized.)"
