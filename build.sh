#!/bin/bash
# Builds Bay Day with every region.
set -euo pipefail
cd "$(dirname "$0")"
APP="$PWD/build/Bay Day.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/music" "$APP/Contents/Resources/regions"
swiftc -O -swift-version 5 -target arm64-apple-macos14.0 Sources/*.swift -o "$APP/Contents/MacOS/BayDay" -framework AppKit -framework SwiftUI -framework MetalKit -framework AVFoundation -framework GameController -framework MapKit
for name in Shaders.metal collect.wav crash.wav AppIcon.icns; do cp "Resources/$name" "$APP/Contents/Resources/$name"; done
# Each region has an elevation grid, and optionally a water mask and a data file.
for dir in Resources/regions/*/; do
  id="$(basename "$dir")"
  cp "$dir/height.bin" "$APP/Contents/Resources/height-$id.bin"
  if [ -f "$dir/water.bin" ]; then cp "$dir/water.bin" "$APP/Contents/Resources/water-$id.bin"; fi
  if [ -f "$dir/region.json" ]; then cp "$dir/region.json" "$APP/Contents/Resources/regions/$id.json"; fi
done
cp Resources/music/*.m4a Resources/music/*.mp3 "$APP/Contents/Resources/music/" 2>/dev/null || true
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>Bay Day</string><key>CFBundleDisplayName</key><string>Bay Day</string>
<key>CFBundleIdentifier</key><string>local.bayday.flight</string><key>CFBundleExecutable</key><string>BayDay</string>
<key>CFBundleIconFile</key><string>AppIcon</string><key>CFBundlePackageType</key><string>APPL</string><key>CFBundleVersion</key><string>6</string><key>CFBundleShortVersionString</key><string>4.0</string>
<key>LSMinimumSystemVersion</key><string>14.0</string><key>NSHighResolutionCapable</key><true/>
<key>NSSupportsAutomaticGraphicsSwitching</key><true/>
<key>NSHumanReadableCopyright</key><string>Bay Day. Scenery: Apple Maps. Elevation: Mapzen / AWS Terrain Tiles. Water: USGS NLCD, JRC Global Surface Water. Music: Kevin MacLeod, CC BY 4.0.</string>
</dict></plist>
PLIST
codesign --force --deep --sign - "$APP"
printf '%s\n' "$APP"
