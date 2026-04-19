#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-local}"

echo "Swift quality gate mode: $MODE"

if [ -d "Kubebar.xcodeproj" ]; then
  XCODE_DERIVED_DATA_PATH="${XCODE_DERIVED_DATA_PATH:-DerivedData}"
  XCODE_DESTINATION="${XCODE_DESTINATION:-platform=macOS}"

  echo "Running Xcode build check"
  xcodebuild \
    -project Kubebar.xcodeproj \
    -scheme Kubebar \
    -destination "$XCODE_DESTINATION" \
    -derivedDataPath "$XCODE_DERIVED_DATA_PATH" \
    build \
    CODE_SIGNING_ALLOWED=NO

  echo "Running Xcode test check"
  xcodebuild \
    -project Kubebar.xcodeproj \
    -scheme Kubebar \
    -destination "$XCODE_DESTINATION" \
    -derivedDataPath "$XCODE_DERIVED_DATA_PATH" \
    test \
    CODE_SIGNING_ALLOWED=NO
fi

echo "Running Swift build check"
swift build

echo "Running Swift test check"
swift test
