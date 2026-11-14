#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
APP="$PWD/build/Bay Day.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
swiftc -O -swift-version 5 -target arm64-apple-macos14.0 Sources/*.swift -o "$APP/Contents/MacOS/BayDay" -framework AppKit -framework SwiftUI -framework MetalKit -framework AVFoundation -framework GameController -framework MapKit
for name in Shaders.metal collect.wav crash.wav height.bin AppIcon.icns; do cp "Resources/$name" "$APP/Contents/Resources/$name"; done
mkdir -p "$APP/Contents/Resources/music"
for name in bossa-antigua backbay-lounge carefree; do cp "Resources/music/$name.mp3" "$APP/Contents/Resources/music/$name.mp3"; done
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>Bay Day</string><key>CFBundleDisplayName</key><string>Bay Day</string>
<key>CFBundleIdentifier</key><string>local.bayday.flight</string><key>CFBundleExecutable</key><string>BayDay</string>
<key>CFBundleIconFile</key><string>AppIcon</string><key>CFBundlePackageType</key><string>APPL</string><key>CFBundleVersion</key><string>4</string><key>CFBundleShortVersionString</key><string>3.1</string>
<key>LSMinimumSystemVersion</key><string>14.0</string><key>NSHighResolutionCapable</key><true/>
<key>NSSupportsAutomaticGraphicsSwitching</key><true/>
<key>NSHumanReadableCopyright</key><string>Bay Day. Scenery: Apple Maps. Elevation: Mapzen / AWS Terrain Tiles. Music: Kevin MacLeod, CC BY 4.0.</string>
</dict></plist>
PLIST
codesign --force --deep --sign - "$APP"
printf '%s\n' "$APP"
