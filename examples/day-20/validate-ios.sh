#!/usr/bin/env bash
set -euo pipefail

# Run on a Mac with Xcode selected.
# First inspect: xcrun simctl list devices available
# Then: SIMULATOR_UDID=<available-device-uuid> bash validate-ios.sh
: "${SIMULATOR_UDID:?Set an available iOS simulator UUID}"

PROJECT="native/PocketTasks/PocketTasks.xcodeproj"
SCHEME="PocketTasks"
BUILD_ROOT="${BUILD_ROOT:-.build/ios-validation}"
mkdir -p "$BUILD_ROOT"

xcodebuild -version
xcodebuild -list -project "$PROJECT"

xcodebuild build \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination "generic/platform=iOS Simulator" \
  -derivedDataPath "$BUILD_ROOT/DerivedData" \
  CODE_SIGNING_ALLOWED=NO

xcodebuild test \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=$SIMULATOR_UDID" \
  -derivedDataPath "$BUILD_ROOT/DerivedData" \
  -resultBundlePath "$BUILD_ROOT/TestResults-$(date +%Y%m%d%H%M%S).xcresult" \
  CODE_SIGNING_ALLOWED=NO
