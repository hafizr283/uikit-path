# PocketTasks — native UIKit practice app

A small UIKit foundation for the 20-day course. It runs as a real iOS app in Xcode and the iOS Simulator. The browser course's UI preview is separate; it does not compile or execute this app.

## Open and run

1. Use a Mac with Xcode 16 or later and an installed iOS Simulator runtime. The project uses Swift 6 language mode and targets iOS 17 or later.
2. Open `native/PocketTasks/PocketTasks.xcodeproj`.
3. Select the shared **PocketTasks** scheme and an available iPhone or iPad simulator.
4. Press **Command–R** to run.
5. Press **Command–U** to run the six unit tests.

A simulator run needs no paid developer account. For a physical device, choose your own team in Signing & Capabilities and use a bundle identifier available to that team. Do not add signing credentials to Git.

## What is implemented

- Scene-based UIKit app startup and a navigation controller.
- A diffable task list with stable UUID identifiers and explicit item reconfiguration.
- Add, detail, edit, complete/incomplete, and confirmed deletion.
- Title validation, multiline text, semantic colors, Dynamic Type, and accessible control identifiers.
- A keyboard-aware editor and scrollable task details.
- A MainActor repository that publishes changes only after saving succeeds.
- An actor-owned, versioned Codable JSON file store with atomic writes.
- First-launch empty state, refresh, recoverable load/save errors, and persistence across launches.
- Six unit tests covering title boundaries; add/edit/complete/delete; failed-save rollback behavior; disk round-trip; preserving corrupt files; and rejecting duplicate stored identifiers.

This is a capstone **foundation**, not a completed production service. Networking, accounts, Keychain, synchronization, Core Data, collection views, push notifications, Universal Links, localization resources, and automated UI tests are learning extensions from the course. The app deliberately makes no network requests and asks for no camera, photo, or notification permissions.

## File map

| File | Responsibility |
| --- | --- |
| `TaskItem.swift` | Value model and title validation |
| `TaskFileStore.swift` | Persistence protocol and actor-isolated file I/O |
| `TaskRepository.swift` | MainActor state, mutation rules, and save-before-publish behavior |
| `AppDelegate.swift`, `SceneDelegate.swift` | App lifecycle and dependency composition |
| `TaskListViewController.swift` | Diffable table, empty state, navigation |
| `TaskEditorViewController.swift` | Form input, keyboard layout, validation feedback |
| `TaskDetailViewController.swift` | Reading, editing, completion, and deletion |
| `PocketTasksTests/PocketTasksTests.swift` | Deterministic model, repository, and file tests |

The repository's single `onChange` callback is intentionally sufficient for one list observer. A larger app with multiple observing screens should adopt an explicit multi-observer state mechanism instead of overwriting that callback from each controller.

Mutations are serialized at the repository boundary: a second mutation receives a busy error while a save is in progress. This keeps the sample's actor reentrancy behavior visible and avoids silently losing an overlapping change.

## Storage and recovery

The app writes `PocketTasks/tasks.json` inside its Application Support directory. The envelope has `version: 1`. Invalid JSON or an unsupported version is reported, not silently replaced. Adding a task is disabled until an initial load succeeds, so a failed initial load cannot overwrite an unknown existing file.

For a clean practice run, remove the app from your simulator and install it again. This deletes that simulator app's local tasks. Do not use this as a production recovery or migration policy.

## Use lessons with this project

For a self-contained example controller, add a new Swift file to the **PocketTasks app target**. To display it, temporarily change the root controller created in `SceneDelegate`. Revert that change to return to the capstone.

Put XCTest examples in the **PocketTasksTests target**, not the app target. Some course test examples include private teaching types so they can run independently. When testing the actual app, use `@testable import PocketTasks` and test its real types.

Contextual snippets in the course state their setup. They are not all drop-in replacements for the app, and the native project does not claim to implement every lesson automatically.

## Command-line verification

From the repository root on your Mac:

```bash
xcodebuild -list -project native/PocketTasks/PocketTasks.xcodeproj
xcrun simctl list devices available

xcodebuild build \
  -project native/PocketTasks/PocketTasks.xcodeproj \
  -scheme PocketTasks \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath .build/DerivedData \
  CODE_SIGNING_ALLOWED=NO

# Substitute an available simulator UUID from simctl:
xcodebuild test \
  -project native/PocketTasks/PocketTasks.xcodeproj \
  -scheme PocketTasks \
  -destination 'platform=iOS Simulator,id=YOUR-SIMULATOR-UUID' \
  -derivedDataPath .build/DerivedData \
  -resultBundlePath .build/PocketTasksTests.xcresult \
  CODE_SIGNING_ALLOWED=NO
```

Choose a fresh result-bundle path if one already exists. The macOS workflow at `.github/workflows/native.yml` discovers an available iPhone simulator, builds, tests, and uploads the result bundle.

## Verification scope

The files and project references were statically checked in the Windows authoring environment. Xcode and the iOS SDK are not available in that environment, so local iOS compilation was not performed there. The actual macOS CI result and your Xcode run determine native build/test status; a workflow file alone is not a passing result.

The starter uses system-provided UI and intentionally has no branded app-icon set. Add proper icons, supported-language resources, distribution signing, privacy review, and release testing before treating it as an App Store submission.
