#!/bin/bash
# Builds one edition of the game: ./build.sh [sf|nyc]   (default sf)
set -euo pipefail
cd "$(dirname "$0")"
REGION="${1:-sf}"
case "$REGION" in
  sf)  NAME="Bay Day";    EXE="BayDay";    ID="local.bayday.flight";    EXTRA="" ;;
  nyc) NAME="Harbor Day"; EXE="HarborDay"; ID="local.harborday.flight"; EXTRA=" Water areas: USGS National Land Cover Database." ;;
  *) echo "usage: ./build.sh [sf|nyc]" >&2; exit 1 ;;
esac
APP="$PWD/build/$NAME.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/music"
swiftc -O -swift-version 5 -target arm64-apple-macos14.0 Sources/*.swift -o "$APP/Contents/MacOS/$EXE" -framework AppKit -framework SwiftUI -framework MetalKit -framework AVFoundation -framework GameController -framework MapKit
for name in Shaders.metal collect.wav crash.wav; do cp "Resources/$name" "$APP/Contents/Resources/$name"; done
for name in height.bin AppIcon.icns; do cp "Resources/$REGION/$name" "$APP/Contents/Resources/$name"; done
for name in bossa-antigua backbay-lounge carefree; do cp "Resources/music/$name.mp3" "$APP/Contents/Resources/music/$name.mp3"; done
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>$NAME</string><key>CFBundleDisplayName</key><string>$NAME</string>
<key>CFBundleIdentifier</key><string>$ID</string><key>CFBundleExecutable</key><string>$EXE</string>
<key>BayDayRegion</key><string>$REGION</string>
<key>CFBundleIconFile</key><string>AppIcon</string><key>CFBundlePackageType</key><string>APPL</string><key>CFBundleVersion</key><string>5</string><key>CFBundleShortVersionString</key><string>3.2</string>
<key>LSMinimumSystemVersion</key><string>14.0</string><key>NSHighResolutionCapable</key><true/>
<key>NSSupportsAutomaticGraphicsSwitching</key><true/>
<key>NSHumanReadableCopyright</key><string>$NAME. Scenery: Apple Maps. Elevation: Mapzen / AWS Terrain Tiles.$EXTRA Music: Kevin MacLeod, CC BY 4.0.</string>
</dict></plist>
PLIST
codesign --force --deep --sign - "$APP"
printf '%s\n' "$APP"
