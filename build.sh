#!/bin/bash
# Build ArgoTimecode.app from source — the repo is the single source of truth.
# Produces a self-contained, adhoc-signed arm64 bundle in ./build/.
#
#   ./build.sh            build the bundle into ./build/ArgoTimecode.app
#   ./build.sh --install  also copy it into /Applications
#
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="ArgoTimecode"
DISPLAY_NAME="Argo Timecode"
BUNDLE_ID="tv.argonautas.timecode"
VERSION="1.2"
BUILD_NUM="3"
MIN_MACOS="14.0"

BUILD_DIR="build"
APP="$BUILD_DIR/$APP_NAME.app"

echo "▸ Compiling release binary…"
swift build -c release
BIN="$(swift build -c release --show-bin-path)/TimecodeCalc"

echo "▸ Assembling $APP…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BIN" "$APP/Contents/MacOS/$APP_NAME"
cp "Icon/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleIdentifier</key>        <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>              <string>$DISPLAY_NAME</string>
  <key>CFBundleDisplayName</key>       <string>$DISPLAY_NAME</string>
  <key>CFBundleExecutable</key>        <string>$APP_NAME</string>
  <key>CFBundleIconFile</key>          <string>AppIcon</string>
  <key>CFBundlePackageType</key>       <string>APPL</string>
  <key>CFBundleVersion</key>           <string>$BUILD_NUM</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>NSPrincipalClass</key>          <string>NSApplication</string>
  <key>NSHighResolutionCapable</key>   <true/>
  <key>LSMinimumSystemVersion</key>    <string>$MIN_MACOS</string>
  <key>NSSupportsAutomaticTermination</key><false/>
</dict>
</plist>
PLIST

echo "▸ Signing (adhoc)…"
codesign --force --deep --sign - "$APP"

echo "▸ Built $APP  (v$VERSION build $BUILD_NUM)"

if [[ "${1:-}" == "--install" ]]; then
  echo "▸ Installing to /Applications…"
  rm -rf "/Applications/$APP_NAME.app"
  cp -R "$APP" "/Applications/$APP_NAME.app"
  echo "▸ Installed /Applications/$APP_NAME.app"
fi
