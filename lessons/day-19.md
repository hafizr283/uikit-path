# Day 19: iOS platform integration

Connect your app to system features without losing control of its state.

**Time:** 3–4 hours · **Target:** Swift 6 / iOS 17+

[Interactive lesson](http://hafizr283.me/uikit-path/#/day/19/lesson) · [Course overview](../README.md)

## Outcomes

- Request permissions in context and handle denial as a normal state.
- Integrate system pickers, sharing, and security-scoped documents.
- Parse deep links into validated routes before navigation.
- Explain notifications, scene transitions, restoration, and background limits.

## Before you begin

- Day 3: scene and view-controller lifecycles.
- Day 6: navigation and presentation.
- Day 10: async work and cancellation.
- Day 15: session boundaries and account authorization.

## 1. Request permission when the user understands why

System permissions protect resources such as camera, microphone, location, and notifications. Ask at the point of a relevant action, with a clear explanation of the benefit. Requesting everything at first launch increases denial and leaves the user without context. The required usage-description keys must explain your actual behavior; a generic 'permission needed' string is not a useful explanation.

Treat notDetermined, authorized, denied, restricted, and feature-specific limited states deliberately. A denied camera permission should lead to an explanation and another way to continue, not a request loop. Prefer a system picker when it provides the access you need without broad library permission. PHPickerViewController lets a user choose photo-library items through a system-managed interface; direct camera capture is a separate capability with its own permission requirements.

## 2. Let system controllers do focused work

Use a photo picker for selected images, a document picker for files, and UIActivityViewController for sharing. These controllers give familiar UI and handle parts of the platform contract, but your app must still handle cancellation, unsupported content, large files, and errors. On iPad, a share sheet presented as a popover needs an anchor such as a bar button item or a source view and rectangle.

An imported document may live outside your sandbox. When appropriate, use startAccessingSecurityScopedResource and balance it with stopAccessingSecurityScopedResource. For a durable copy, import into your own application-support directory instead of retaining a temporary URL forever. If the product needs ongoing access to an external document, study security-scoped bookmarks and file coordination. Keep potentially expensive decoding and file processing away from time-critical UI work.

## 3. Parse links before touching navigation

A deep link is external input. Convert it into a small internal route type, rejecting unsupported schemes, hosts, paths, identifiers, and parameters. Do not treat the URL as an instruction to instantiate an arbitrary class or load an arbitrary authenticated endpoint. Route parsing should be a pure function so malformed links and edge cases can be tested without launching UIKit.

Universal Links require both the Associated Domains entitlement and the website's apple-app-site-association configuration; adding a URL parser alone does not establish the association. Custom URL schemes require app registration and do not offer the same domain ownership guarantee. Handle incoming URLs and user activities in the scene lifecycle, including cold launch connection options. If the route requires login, preserve only a safe internal route, authenticate, then revalidate access to the requested task on the server or repository.

## 4. Notifications are delivery hints, not guaranteed execution

Local notifications are scheduled by the app; remote notifications arrive through APNs after server-side configuration. User permission controls user-facing notification behavior. A notification payload should carry the minimum routing information, not secrets or the only copy of important data. When the user opens a notification, use the same validated routing layer as a deep link and fetch the current authorized content.

Background execution is constrained by the system. Going to the background does not give an app an unlimited timer, and silent push is not a guaranteed job scheduler. BGTaskScheduler requires capabilities, permitted identifiers, registered handlers, and suitable task completion behavior; the system decides when eligible work runs. Always handle expiration and finish promptly. For the course, first build a correct local reminder flow and document which production server and entitlement work remains.

## 5. Restore useful state without storing private screen snapshots

Scenes can connect, disconnect, enter the background, and be discarded. Save durable model changes when the user makes them rather than relying on termination callbacks. Persist a small, versioned description of useful UI state, such as a selected task ID or filter. After restoration, look up that identifier again because the task may have been deleted or access may have changed.

On returning to the foreground, decide what should refresh and what should remain stable. Avoid dismissing an editor or resetting a scroll position merely because a permission sheet temporarily changed activity state. Multiple scenes can show the same underlying data, so the repository should be the shared source of truth rather than a controller-owned copy with hidden persistence. Test cold launch, warm link delivery, cancellation, denial, and background-to-foreground transitions as separate cases.

## Worked example: A validated deep-link parser

**File:** AppRoute.swift

```swift
import Foundation

enum AppRoute: Equatable, Sendable {
    case task(UUID)
}

struct DeepLinkParser {
    let universalLinkHost: String

    func parse(_ url: URL) -> AppRoute? {
        guard url.user == nil, url.password == nil,
              url.query == nil, url.fragment == nil else {
            return nil
        }
        let parts = url.path.split(separator: "/").map(String.init)
        let candidate: String

        switch url.scheme?.lowercased() {
        case "https":
            guard url.host?.lowercased() ==
                    universalLinkHost.lowercased(),
                  url.port == nil || url.port == 443,
                  parts.count == 2,
                  parts[0] == "tasks" else { return nil }
            candidate = parts[1]
        case "pockettasks":
            guard url.host?.lowercased() == "task",
                  url.port == nil,
                  parts.count == 1 else { return nil }
            candidate = parts[0]
        default:
            return nil
        }

        guard let id = UUID(uuidString: candidate) else {
            return nil
        }
        return .task(id)
    }
}

// Fixture use:
// let parser = DeepLinkParser(
//     universalLinkHost: "pockettasks.example"
// )
// let url = URL(string:
//   "pockettasks://task/00000000-0000-0000-0000-000000000001"
// )!
// parser.parse(url) -> .task(the UUID above)
//
// The .example host is documentation-only, not a live service.
```

### Walkthrough and setup

1. Add the parser to the app or a shared model target. It uses Foundation only, so its behavior can be unit tested without constructing a controller.
2. Register the pockettasks custom scheme in the app target's URL Types if you want to open it from the simulator. The parser alone does not register the scheme.
3. For a warm custom-scheme launch, obtain URLs in scene(_:openURLContexts:). For a Universal Link, inspect the webpageURL from the browsing user activity. Also check scene connection options on cold launch.
4. Pass the parsed AppRoute to a MainActor coordinator. Check session state and whether the task exists and is accessible before presenting details.
5. The accepted grammar intentionally rejects all query strings and fragments. Expand it only when a feature needs documented parameters, and add matching tests.

**Expected behavior:** Only recognized HTTPS routes on the configured host and recognized pockettasks task URLs produce a task route. Malformed identifiers, foreign hosts, credentials, and unsupported parameters return nil.

## Challenge 1: Present an iPad-safe share sheet

**Level:** Warm-up

Add a reusable share function for a task's plain-text summary. It must work when UIKit chooses a popover presentation on iPad.

### Requirements

- Use UIActivityViewController.
- Anchor to a supplied source view.
- Do not put credentials or hidden account data in the shared text.

### Starter

```swift
import UIKit
@MainActor
func share(text: String, from controller: UIViewController,
           sourceView: UIView) {
    // Present and configure the popover anchor.
}
```

<details>
<summary>Hints</summary>

- The popoverPresentationController is optional.
- sourceRect uses the source view's own coordinate system.

</details>

### Acceptance checks

- The share sheet opens on an iPhone simulator.
- On an iPad simulator, it is anchored to the source control.
- Cancelling the sheet leaves the task unchanged.

<details>
<summary>Worked solution</summary>

```swift
import UIKit
@MainActor
func share(text: String, from controller: UIViewController,
           sourceView: UIView) {
    let activity = UIActivityViewController(
        activityItems: [text],
        applicationActivities: nil
    )
    if let popover = activity.popoverPresentationController {
        popover.sourceView = sourceView
        popover.sourceRect = sourceView.bounds
    }
    controller.present(activity, animated: true)
}
```

Anchoring avoids the common iPad exception for an unconfigured popover. The caller should pass a currently visible view and avoid presenting while another conflicting presentation is active.

</details>

## Challenge 2: Read a small imported text file safely

**Level:** Core

A document picker returns a URL. Read at most 64 KiB of UTF-8 task notes, balance security-scoped access, and reject larger or invalid text.

### Requirements

- Balance start/stop access with defer.
- Read one byte beyond the limit to detect an oversized file.
- Close the FileHandle even when validation fails.
- Return clear errors; do not substitute an empty successful result.

### Starter

```swift
import Foundation
enum ImportError: Error { case tooLarge, invalidText }
func importNotes(from url: URL) throws -> String {
    // Open, read a bounded amount, and validate UTF-8.
    ""
}
```

<details>
<summary>Hints</summary>

- FileHandle.read(upToCount:) lets you bound the requested read.
- A false startAccessing result does not necessarily mean a sandbox-owned URL is unreadable.

</details>

### Acceptance checks

- A valid short UTF-8 file returns its text.
- A 65,537-byte file is rejected for size.
- Invalid UTF-8 is rejected.
- The resource scope and file handle are released on both success and error.

<details>
<summary>Worked solution</summary>

```swift
import Foundation

enum ImportError: Error {
    case tooLarge
    case invalidText
}

func importNotes(from url: URL) throws -> String {
    let scoped = url.startAccessingSecurityScopedResource()
    defer {
        if scoped { url.stopAccessingSecurityScopedResource() }
    }

    let file = try FileHandle(forReadingFrom: url)
    defer { try? file.close() }

    let limit = 64 * 1024
    var data = Data()
    while data.count <= limit {
        let remaining = limit + 1 - data.count
        guard let chunk = try file.read(upToCount: remaining),
              !chunk.isEmpty else { break }
        data.append(chunk)
    }

    guard data.count <= limit else { throw ImportError.tooLarge }
    guard let text = String(data: data, encoding: .utf8) else {
        throw ImportError.invalidText
    }
    return text
}
```

The loop handles partial reads while never accumulating more than the limit plus one byte. It avoids assuming that a file-size metadata check remains true until reading completes. Perform file I/O through an appropriate service away from time-critical UI work; copy accepted content into your repository if it should persist.

</details>

## Challenge 3: Schedule and cancel a local reminder

**Level:** Stretch

Build a fixture reminder helper that asks for alert permission in context and schedules a one-off reminder at least one second in the future. Use a stable task-specific identifier so rescheduling replaces the pending reminder.

### Requirements

- Surface denial instead of pretending a reminder was scheduled.
- Use UNUserNotificationCenter's async APIs.
- Keep private task details out of notification text by default.
- Provide a cancellation function.

### Starter

```swift
import Foundation
import UserNotifications
enum ReminderError: Error { case denied, invalidDate }
// Add schedule and cancel methods for a task UUID.
```

<details>
<summary>Hints</summary>

- Use a consistent request identifier derived from the task ID.
- A non-repeating UNTimeIntervalNotificationTrigger can use a future interval.
- Adding a request with the same identifier replaces the pending request.

</details>

### Acceptance checks

- Denial produces a recoverable error.
- Rescheduling the same task replaces its pending identifier.
- Cancelling removes the pending request.
- A past date is rejected, including one that passes while permission is being requested.

<details>
<summary>Worked solution</summary>

```swift
import Foundation
import UserNotifications

enum ReminderError: Error {
    case denied
    case invalidDate
}

@MainActor
struct ReminderScheduler {
    private func identifier(for id: UUID) -> String {
        "task-reminder-" + id.uuidString
    }

    func schedule(taskID: UUID, at date: Date) async throws {
        let interval = date.timeIntervalSinceNow
        guard interval >= 1 else {
            throw ReminderError.invalidDate
        }
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(
            options: [.alert, .sound]
        )
        guard granted else { throw ReminderError.denied }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Task reminder")
        content.body = String(localized: "Open PocketTasks to review your task.")
        content.sound = .default
        content.userInfo = ["taskID": taskID.uuidString]

        let remaining = date.timeIntervalSinceNow
        guard remaining >= 1 else {
            throw ReminderError.invalidDate
        }
        let request = UNNotificationRequest(
            identifier: identifier(for: taskID),
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(
                timeInterval: remaining, repeats: false
            )
        )
        try await center.add(request)
    }

    func cancel(taskID: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: [identifier(for: taskID)]
            )
    }
}
```

Authorization can take time, so the solution recomputes the remaining interval afterward. A scheduled request is not a promise of exact visual delivery: user settings and system behavior still apply. Foreground presentation and tap routing require a UNUserNotificationCenterDelegate wired by the app.

</details>

## Knowledge check

### 1. What should happen after a user denies camera permission?

A. Request it repeatedly until they agree

B. Crash to force a restart

C. Explain the limitation and offer a useful alternative or settings path

D. Silently claim the photo was captured

<details>
<summary>Answer and explanation</summary>

**C. Explain the limitation and offer a useful alternative or settings path**

Denial is a supported product state. The user should understand the limitation and be able to continue where possible.

</details>

### 2. What does a deep-link parser alone establish?

A. Universal Link domain association

B. App Store approval

C. A validated internal route from accepted input

D. Authorization to view any task

<details>
<summary>Answer and explanation</summary>

**C. A validated internal route from accepted input**

Domain association and resource authorization are separate requirements.

</details>

### 3. Why use defer around security-scoped access?

A. It encrypts every file

B. It balances resource access even when reading throws

C. It grants permanent permission

D. It turns all file work asynchronous

<details>
<summary>Answer and explanation</summary>

**B. It balances resource access even when reading throws**

Cleanup must run on success and failure. Start/stop calls must remain balanced.

</details>

### 4. Which statement about silent pushes is correct?

A. They are guaranteed timers

B. They allow unlimited background execution

C. Delivery and background execution are controlled by the system

D. They replace all local persistence

<details>
<summary>Answer and explanation</summary>

**C. Delivery and background execution are controlled by the system**

Design for delays, non-delivery, and expiration rather than treating background push as a guaranteed scheduler.

</details>

### 5. What is appropriate state to restore for a task detail screen?

A. An unchecked old array index

B. A password in plain text

C. A stable task ID that is looked up and revalidated

D. A complete copy of every network header

<details>
<summary>Answer and explanation</summary>

**C. A stable task ID that is looked up and revalidated**

Persist minimal state and revalidate the underlying content and permissions.

</details>

## Common pitfalls

- A usage-description key is not a substitute for a contextual permission flow.
- An unanchored share popover can fail on iPad.
- Temporary document URLs are not a durable storage strategy.
- A parsed link still needs authentication and authorization checks.
- Background execution and notification delivery are not guaranteed schedules.

## PocketTasks milestone: Connect PocketTasks to system workflows

1. Add sharing for a task summary with a correct iPad anchor.
2. Import small text notes through a document picker and persist the accepted text.
3. Use the shared route parser for custom links and future notification taps.
4. Add fixture local reminders, then document the additional Universal Links and remote-notification configuration needed for production.

## Before you move on

- Handle permission approval, denial, and cancellation without trapping the user.
- Present sharing correctly on both phone and tablet.
- Test accepted and rejected deep-link inputs.
- Read an imported file with bounded size and balanced resource access.
- Explain cold launch, warm link delivery, and foreground restoration separately.

## Official references

- [Apple: PHPickerViewController](https://developer.apple.com/documentation/photosui/phpickerviewcontroller)
- [Apple: Supporting Universal Links in your app](https://developer.apple.com/documentation/xcode/supporting-universal-links-in-your-app)
- [Apple: User Notifications](https://developer.apple.com/documentation/usernotifications)
- [Apple: Background Tasks](https://developer.apple.com/documentation/backgroundtasks)

## Reflection

- What can I now explain without the example?
- What did I build and test in Xcode?
- Which bug or design tradeoff do I want to revisit?
