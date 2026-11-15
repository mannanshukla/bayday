#!/bin/bash
# Runs the checks for one edition: ./test.sh [sf|nyc]   (default sf)
set -euo pipefail
cd "$(dirname "$0")"
REGION="${1:-sf}"
mkdir -p build/tests
cp Sources/NativeTests.txt build/tests/NativeTests.swift
swiftc -O -swift-version 5 Sources/Math.swift Sources/Mesh.swift Sources/Region.swift Sources/RegionSF.swift Sources/RegionNYC.swift Sources/RegionNYCNeighbourhoods.swift Sources/Discoveries.swift Sources/Game.swift Sources/Physics.swift Sources/Place.swift Sources/AppleScenery.swift Sources/AeroKit.swift Sources/Renderer.swift build/tests/NativeTests.swift -o build/tests/NativeTests -framework AppKit -framework SwiftUI -framework MetalKit -framework AVFoundation -framework GameController -framework MapKit
BAYDAY_REGION="$REGION" build/tests/NativeTests "$PWD/Resources/$REGION/height.bin"
