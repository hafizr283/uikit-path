# Day 20: Professional delivery & codebase readiness

Turn a working app into a reproducible, reviewable release.

**Time:** 3–4 hours · **Target:** Swift 6 / iOS 17+

[Interactive lesson](http://hafizr283.me/uikit-path/#/day/20/lesson) · [Course overview](../README.md)

## Outcomes

- Explain targets, schemes, build configurations, and package dependencies.
- Build and test the project reproducibly from the command line.
- Understand signing, archives, TestFlight, and the release-review boundary.
- Prepare a reviewable change with safe diagnostics and explicit release evidence.

## Before you begin

- Day 13: composition roots and dependency boundaries.
- Day 16: meaningful tests.
- Day 17: profiling and crash investigation.
- Day 18: accessibility and localization checks.

## 1. Know what Xcode is building

A target defines a product and the sources, resources, dependencies, and settings used to build it. A scheme selects targets and configurations for actions such as Run, Test, Profile, and Archive. Debug and Release are build configurations; they are not separate applications unless you define different bundle identifiers or targets. If a file is visible in Xcode but absent from the target's sources or resources, it may not be included in the app.

Share the scheme in source control so another developer and CI can select the same build. Keep environment-specific configuration explicit through build settings or xcconfig files, and validate required values at startup. A staging API URL is configuration; a production signing credential is a secret. Do not put confidential service credentials into an iOS app merely because the value is loaded from an Info.plist or xcconfig file. A shipped client can be inspected.

## 2. Make dependencies and changes reviewable

Swift Package Manager can attach packages and products to the appropriate targets. Evaluate a dependency's maintenance, license, supported platforms, API surface, and necessity before adding it. Keep resolved package versions under the repository's intended policy so CI and teammates can reproduce builds. Do not commit DerivedData, local user settings, simulator data, or signing secrets.

A useful pull request describes the user-visible problem, the resulting behavior, and the evidence that supports it. Keep unrelated formatting or architectural rewrites out of a focused fix. Review error handling, cancellation, ownership, accessibility, data migration, and privacy as applicable to the change. A screenshot proves one visual state; a test proves the behavior it actually asserts. State what was not tested instead of expanding either into a blanket quality claim.

## 3. Separate simulator validation from release signing

The simulator can build and run UIKit apps without a physical-device provisioning profile. A device or distributable archive requires the correct bundle identifier, team, certificates, capabilities, and provisioning arrangement. Automatic signing can manage parts of this for an authorized Apple developer account, but it does not remove the need for matching entitlements and access. Keep signing material in the approved developer account or CI secret system.

Create an archive using the Release configuration and a device destination, inspect it in Organizer, and use the supported distribution workflow. TestFlight adds an installable distribution stage where testers can exercise the real signed build. It is separate from App Store submission and approval. Before sending a build, verify version and build numbers, supported OS versions, privacy declarations, required usage strings, icons, screenshots, account access for review where needed, and the behavior of the actual release configuration.

## 4. Automate evidence, not unchecked publishing

A CI job should start from a clean checkout, select a known Xcode environment, resolve dependencies, and run meaningful build and test commands. Store test-result bundles and logs that help diagnose failure. Make the job fail when a build or test fails; a shell pipeline that discards an exit code can produce a misleading green badge. Do not skip failing tests merely to get a release artifact.

Start with unsigned simulator builds and tests. Add archive and distribution automation only after the team has a clear signing and release policy. Protect release credentials and use narrow permissions. A course repository can provide a macOS build workflow, but its presence is not proof that it ran successfully. Inspect the actual CI result and download the evidence when investigating failures. Reproducibility includes the toolchain and destination, not just the source commit.

## 5. Prepare to maintain what you ship

A release is the beginning of maintenance. Use minimal structured diagnostics, retain matching symbols for crashes, and connect issues to the deployed version. Do not log tokens, passwords, complete request bodies, or user documents. If you use third-party analytics or crash reporting, understand what it collects and ensure the app's privacy disclosures and consent behavior match the actual integration.

For PocketTasks, perform a final user journey: first launch, create/edit/complete a task, relaunch and verify persistence, recover from a failed load, navigate with VoiceOver, use large text, and exercise the selected platform integrations. Record remaining limitations such as mock authentication or an unimplemented synchronization service. Twenty days gives you a structured foundation; your next growth step is maintaining this app through a real feature change, a migration, and a bug investigation while preserving the tests and user experience.

## Worked example: A repeatable simulator validation script

**File:** validate-ios.sh

```bash
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
```

### Walkthrough and setup

1. Save this as validate-ios.sh at the repository root on your Mac. The path assumes the accompanying native/PocketTasks project; adjust it for another checkout.
2. Use xcrun simctl list devices available and choose an installed iOS simulator UUID. Supplying a destination avoids assuming that every Xcode installation has the same device name.
3. The generic simulator build checks that the app compiles; the test action runs the shared scheme's tests on the concrete simulator.
4. set -euo pipefail preserves failure. No log-formatting pipeline is used here, so xcodebuild's result remains directly visible.
5. The script creates local build artifacts and a uniquely named result bundle. Add .build to .gitignore. It does not sign, archive for devices, upload to TestFlight, or submit an App Store release.

**Expected behavior:** On a Mac with a compatible Xcode and installed simulator, the script exits successfully only if both build and test actions succeed. A .xcresult bundle remains available for inspection.

## Challenge 1: Validate environment configuration

**Level:** Warm-up

Read an API_BASE_URL string from an injected configuration dictionary and reject missing or non-HTTPS values. Keep this separate from the live Bundle so tests can supply fixtures.

### Requirements

- Require a nonempty host and HTTPS.
- Reject embedded credentials, a query string, and a fragment.
- Return a typed configuration or a specific error.
- Do not hard-code a production secret.

### Starter

```swift
import Foundation
enum ConfigurationError: Error { case invalidBaseURL }
struct AppConfiguration {
    let apiBaseURL: URL
    init(values: [String: String]) throws {
        // Validate API_BASE_URL.
        throw ConfigurationError.invalidBaseURL
    }
}
```

<details>
<summary>Hints</summary>

- Construct URLComponents to inspect the parsed URL.
- Validation should fail early instead of silently choosing a production default.

</details>

### Acceptance checks

- A valid HTTPS fixture URL is accepted.
- Missing, HTTP, credential-bearing, and query-bearing values are rejected.
- The parser can be tested without editing the app's Info.plist.

<details>
<summary>Worked solution</summary>

```swift
import Foundation

enum ConfigurationError: Error {
    case invalidBaseURL
}

struct AppConfiguration {
    let apiBaseURL: URL

    init(values: [String: String]) throws {
        guard let raw = values["API_BASE_URL"],
              let parts = URLComponents(string: raw),
              parts.scheme?.lowercased() == "https",
              let host = parts.host, !host.isEmpty,
              parts.user == nil, parts.password == nil,
              parts.query == nil, parts.fragment == nil,
              let url = parts.url else {
            throw ConfigurationError.invalidBaseURL
        }
        apiBaseURL = url
    }
}
```

Injecting a dictionary keeps parsing deterministic. Configuration validation is separate from a credential-origin allowlist: an app that attaches tokens must still enforce the trusted server boundary from Day 15. A configured URL is public client configuration, not a secret.

</details>

## Challenge 2: Create diagnostics that cannot accept a raw token

**Level:** Core

Define a tiny network logging API that accepts a known operation, status code, and duration. Its public interface should have no parameter for an Authorization header, request body, or arbitrary URL.

### Requirements

- Use structured Logger output.
- Represent operations with a small enum.
- Clamp negative elapsed values or otherwise define the invalid-input behavior.
- Keep the logging helper out of model business logic.

### Starter

```swift
import Foundation
import os

enum NetworkOperation: String {
    case fetchTasks, saveTask
}
// Add a logger that accepts only safe operational fields.
```

<details>
<summary>Hints</summary>

- Restricting the API makes accidental sensitive logging harder.
- An operation name identifies a route category without exposing a complete URL.

</details>

### Acceptance checks

- The API cannot be called with a token or arbitrary URL parameter.
- A negative or non-finite duration has a defined sanitized value.
- The log contains operation, status, and duration without request contents.

<details>
<summary>Worked solution</summary>

```swift
import Foundation
import os

enum NetworkOperation: String {
    case fetchTasks
    case saveTask
}

struct NetworkDiagnostics {
    private let logger = Logger(
        subsystem: "com.example.PocketTasks",
        category: "network"
    )

    func completed(
        operation: NetworkOperation,
        status: Int,
        elapsedSeconds: Double
    ) {
        let duration = elapsedSeconds.isFinite
            ? max(0, elapsedSeconds) : 0
        logger.info(
            "operation=\(operation.rawValue, privacy: .public) status=\(status) seconds=\(duration)"
        )
    }
}
```

This helper accepts only a known operation and numeric diagnostics. It reduces opportunities for accidentally dumping a request, though the team still needs a broader logging policy. Public operation names are intentionally non-sensitive; real user identifiers should not be added casually.

</details>

## Challenge 3: Write a simulator CI job that preserves failures

**Level:** Stretch

Create a GitHub Actions job that checks out the repository and builds the shared PocketTasks scheme on macOS. Explain what is still needed before it can act as a release gate.

### Requirements

- Use a macOS runner and a simulator SDK.
- Give the workflow read-only repository permissions.
- Do not introduce signing credentials for a simulator build.
- Fail on xcodebuild errors.

### Starter

```swift
name: iOS build
on: [push, pull_request]
# Add a read-only macOS build job.
```

<details>
<summary>Hints</summary>

- The generic simulator destination does not require a specific installed device name.
- A build-only check does not execute tests or validate signing.

</details>

### Acceptance checks

- A compilation error makes the job fail.
- The workflow contains no token, certificate, or provisioning profile.
- Its documentation calls it a build check rather than an App Store release.

<details>
<summary>Worked solution</summary>

```swift
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
```

This is a minimal compile gate, not a complete release pipeline. Add tests on an available simulator, preserve result bundles, select a team-supported Xcode version, and check the release configuration. Signed archives, privacy review, and distribution credentials require separate deliberate setup.

</details>

## Knowledge check

### 1. What does an Xcode scheme determine?

A. Only the app icon

B. Which targets and configurations actions such as Run and Test use

C. The user's Apple ID password

D. The contents of every API response

<details>
<summary>Answer and explanation</summary>

**B. Which targets and configurations actions such as Run and Test use**

Schemes connect buildable targets to actions and configurations and should be shared for CI.

</details>

### 2. Does a successful unsigned simulator build prove App Store readiness?

A. Yes, all signing is automatic

B. No; signing, release behavior, distribution, and review requirements remain

C. Yes, if the app uses UIKit

D. Only if the repository is public

<details>
<summary>Answer and explanation</summary>

**B. No; signing, release behavior, distribution, and review requirements remain**

Simulator compilation is useful evidence with a limited scope.

</details>

### 3. Which item should generally stay out of source control?

A. Shared schemes

B. Tests

C. DerivedData and signing secrets

D. Source files

<details>
<summary>Answer and explanation</summary>

**C. DerivedData and signing secrets**

Generated local build output and private signing material do not belong in the normal source repository.

</details>

### 4. What makes a useful pull-request validation statement?

A. A blanket claim that everything works

B. Specific checks and results with material limits

C. Only the number of lines changed

D. A screenshot presented as proof of all behavior

<details>
<summary>Answer and explanation</summary>

**B. Specific checks and results with material limits**

Reviewers need concrete evidence and its scope to assess the change.

</details>

### 5. Why preserve the matching archive and symbols for a released build?

A. To change the user's locale

B. To interpret and symbolize crash reports from that build

C. To bypass authorization

D. To enable infinite background execution

<details>
<summary>Answer and explanation</summary>

**B. To interpret and symbolize crash reports from that build**

Matching symbols connect release crash addresses to meaningful code locations.

</details>

## Common pitfalls

- A local unshared scheme may work for one developer but be invisible to CI.
- Putting a secret into an xcconfig does not make it safe to ship in the app.
- A green compile job is not proof that tests ran.
- A staging build may hide a broken Release configuration.
- Passing TestFlight installation does not mean the App Store review is complete.

## PocketTasks milestone: Prepare a reviewable PocketTasks handoff

1. Run and record the available build, unit-test, UI-test, accessibility, and persistence checks.
2. Document setup, architecture, supported iOS version, and which integrations are fixtures.
3. Create a focused release checklist and a known-limitations section without claiming production auth or sync is complete.
4. On your authorized Apple account, create and inspect a signed archive; proceed to TestFlight only when the release setup and checks are ready.

## Before you move on

- Explain the project's app target, test target, shared scheme, and configurations.
- Run a clean simulator build and the relevant test suite on your Mac.
- Write a pull-request description with concrete behavior and validation.
- Check release configuration, privacy strings, and known product limitations.
- Prepare a follow-up roadmap based on real gaps rather than claiming mastery after twenty days.

## Official references

- [Apple: Building and running an app](https://developer.apple.com/documentation/xcode/building-and-running-an-app)
- [Apple: Distributing your app for beta testing and releases](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases)
- [Apple: Adding package dependencies to your app](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app)
- [Apple: App privacy details](https://developer.apple.com/app-store/app-privacy-details/)

## Reflection

- What can I now explain without the example?
- What did I build and test in Xcode?
- Which bug or design tradeoff do I want to revisit?
