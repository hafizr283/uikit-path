// Worked solution: Write a simulator CI job that preserves failures
// This is a minimal compile gate, not a complete release pipeline. Add tests on an available simulator, preserve result bundles, select a team-supported Xcode version, and check the release configuration. Signed archives, privacy review, and distribution credentials require separate deliberate setup.
// Read lessons/day-20.md for any surrounding types or setup.

name: iOS build
on: [push, pull_request]
permissions:
  contents: read

jobs:
  build:
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4
      - name: Show selected toolchain
        run: xcodebuild -version
      - name: Build UIKit app
        shell: bash
        run: |
          set -euo pipefail
          xcodebuild build \
            -project native/PocketTasks/PocketTasks.xcodeproj \
            -scheme PocketTasks \
            -configuration Debug \
            -sdk iphonesimulator \
            -destination "generic/platform=iOS Simulator" \
            -derivedDataPath .build/DerivedData \
            CODE_SIGNING_ALLOWED=NO
