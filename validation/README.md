# Course source validation

This directory contains **test-only fixtures and assertions**, not alternate course implementations.
`scripts/check-swift-examples.py` extracts code directly from each day's JSON when it runs.
It records source hashes, toolchain versions, exact compiler commands, exit codes, and diagnostics.
It does not modify the lesson code to make a test pass.

Run on a Mac with Xcode selected:

```sh
python3 scripts/check-swift-examples.py
```

The GitHub Actions workflow `examples.yml` runs the same command on `macos-15`.
Its artifact includes the report, logs, and extracted sources. A failing check returns a
nonzero exit code; later independent checks still run so the report shows all observed failures.

On Windows or another host without Xcode, preparation can be checked separately:

```sh
python scripts/check-swift-examples.py --prepare-only
```

Preparation marks every native check **not run**. It verifies extraction and declared inputs,
but provides no Swift compilation or runtime evidence.

## What runs

- Days 1–19: each complete worked example is typechecked independently using `swiftc`,
  `-swift-version 6`, complete strict-concurrency checking, and an iOS 17 simulator target.
  The installed Xcode iOS Simulator SDK supplies UIKit, Foundation, Security, and Core Data.
- Day 12 includes Day 11's unchanged API source because its walkthrough explicitly depends on it.
- Day 16 uses the simulator XCTest framework and Swift-overlay search paths. Its worked example and all three
  solutions are also typechecked together, with the private teaching types and their extension
  kept in the same source file as the exercise requires.
- Day 20 is Bash, not Swift. Only `bash -n` runs for this example. The example's native project
  build/test commands are not executed by this workflow.
- The cases declared in `runtime-cases.json` are typechecked for iOS and compiled/executed on
  the macOS host using Swift 6. Each case has a separate test-only `@main` harness. The source
  snippets themselves do not gain application entry points or replacement implementations.
- Day 16's worked XCTest example plus all three exercise solutions run as actual tests in a
  temporary Swift package. There are eight test methods at initial publication: three state
  tests, three title-validation tests, one retry test, and one intercepted URLSession test.

No live network request is required. The network-boundary XCTest uses its own URLProtocol.
Runtime file and preferences cases use unique temporary paths and suites, with cleanup.

The manual iOS compiler invocation follows the Darwin test-support directory layout used by
[Swift Package Manager 6.1.2](https://github.com/swiftlang/swift-package-manager/blob/swift-6.1.2-RELEASE/Sources/PackageModel/SwiftSDKs/SwiftSDK.swift#L642).
Both platform framework search paths use `-F`; `Developer/usr/lib` uses `-I` for the Swift
XCTest overlay. Using only the framework path finds Objective-C `XCTestCase` but can leave
Swift functions such as `XCTAssertEqual` and `XCTUnwrap` unavailable. No assertion stubs or
diagnostic suppressions are used. The report records the actual paths selected by Xcode.

## Context and limits

`runtime-cases.json` explicitly declares when an exercise needs `import Foundation`, a previous
example's types, or its supplied starter declarations. The runner adds only those declared
imports and assembles those declared inputs. Worked examples are extracted unchanged.

Day 14's worked example accesses `NSManagedObject` dynamically, so source typechecking needs
**no fake model classes or replacement Core Data implementation**. Its documented
`PocketTasks.xcdatamodeld` schema is still required to run the actual store. This workflow does
not open that store or verify Core Data CRUD, migrations, background merges, or relationships.
The separate Day 14 file/preferences exercises do execute, but are not evidence for Core Data.

Typechecking is not an app build. Host runtime tests are not simulator tests. This workflow
does not establish layout correctness, accessibility, entitlements, Keychain persistence,
notification delivery, actual backend availability, or App Store readiness. The report lists
every exercise solution not selected for runtime coverage; no success is inferred for those.
Use the native app workflow and Xcode/device testing for the app-specific checks.
