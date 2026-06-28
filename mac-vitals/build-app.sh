#!/usr/bin/env bash
#
# Builds MacVitals into a proper menu-bar .app bundle.
#
# `swift run` works for quick testing, but a real menu-bar agent needs an .app
# bundle with an Info.plist (LSUIElement so there is no Dock icon, minimum OS,
# etc). This script compiles a release binary and assembles that bundle.
#
# Usage:
#   ./build-app.sh            # build into ./dist/MacVitals.app
#   ./build-app.sh --run      # build, then launch the app
#   ./build-app.sh --install  # build, then copy into /Applications
set -euo pipefail

APP_NAME="MacVitals"
BUNDLE_ID="dev.mac-vitals.MacVitals"
MIN_OS="14.0"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="$ROOT/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"
RES_DIR="$APP_DIR/Contents/Resources"

echo "==> Compiling release binary"
swift build -c release --package-path "$ROOT"
BIN_PATH="$(swift build -c release --package-path "$ROOT" --show-bin-path)/$APP_NAME"

echo "==> Assembling $APP_NAME.app"
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RES_DIR"
cp "$BIN_PATH" "$MACOS_DIR/$APP_NAME"

cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>            <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>     <string>Mac Vitals</string>
    <key>CFBundleIdentifier</key>      <string>$BUNDLE_ID</string>
    <key>CFBundleExecutable</key>      <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>     <string>APPL</string>
    <key>CFBundleShortVersionString</key> <string>0.1.0</string>
    <key>CFBundleVersion</key>         <string>1</string>
    <key>LSMinimumSystemVersion</key>  <string>$MIN_OS</string>
    <key>LSUIElement</key>             <true/>
    <key>NSHumanReadableCopyright</key><string>POC experiment</string>
</dict>
</plist>
PLIST

echo "==> Ad-hoc code signing"
codesign --force --deep --sign - "$APP_DIR" >/dev/null 2>&1 || \
    echo "    (codesign skipped — running unsigned is fine for local use)"

echo "==> Done: $APP_DIR"

case "${1:-}" in
    --run)
        echo "==> Launching"
        open "$APP_DIR"
        ;;
    --install)
        echo "==> Installing to /Applications"
        rm -rf "/Applications/$APP_NAME.app"
        cp -R "$APP_DIR" "/Applications/"
        echo "    Installed. Launch from Spotlight or /Applications."
        ;;
esac
