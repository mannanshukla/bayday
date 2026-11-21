#!/bin/bash
# Runs the checks for one city, or for every city: ./test.sh [region id | all]   (default sf)
set -uo pipefail
cd "$(dirname "$0")"
mkdir -p build/tests
cp Sources/NativeTests.txt build/tests/NativeTests.swift
rm -f build/tests/NativeTests
if ! swiftc -O -swift-version 5 Sources/Math.swift Sources/Mesh.swift Sources/Region.swift Sources/RegionSF.swift Sources/RegionNYC.swift Sources/RegionNYCNeighbourhoods.swift Sources/Discoveries.swift Sources/Game.swift Sources/Physics.swift Sources/Place.swift Sources/AppleScenery.swift Sources/LookAround.swift Sources/AeroKit.swift Sources/Renderer.swift build/tests/NativeTests.swift -o build/tests/NativeTests -framework AppKit -framework SwiftUI -framework MetalKit -framework AVFoundation -framework GameController -framework MapKit 2> build/tests/compile.log; then grep -E "error" -A3 build/tests/compile.log | head -40; echo "The tests did not compile."; exit 1; fi
REGIONS="${1:-sf}"
if [ "$REGIONS" = "all" ]; then REGIONS="$(ls Resources/regions)"; fi
FAILED=0
for REGION in $REGIONS; do
  printf '%s: ' "$REGION"
  BAYDAY_REGION="$REGION" BAYDAY_REGIONS_DIR="$PWD/Resources/regions" build/tests/NativeTests "$PWD/Resources/regions/$REGION/height.bin" 2>&1 | tail -1 || FAILED=1
done
exit $FAILED
