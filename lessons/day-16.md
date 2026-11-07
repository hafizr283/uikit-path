# Day 16: Testing UIKit applications

Prove behavior with fast, deterministic tests.

**Time:** 3–4 hours · **Target:** Swift 6 / iOS 17+

[Interactive lesson](http://hafizr283.me/uikit-path/#/day/16/lesson) · [Course overview](../README.md)

## Outcomes

- Separate testable behavior from UIKit rendering and infrastructure.
- Use XCTest for pure functions, async services, and MainActor view models.
- Choose a stub, mock, or fake based on the question under test.
- Write focused UI tests for critical user journeys and error recovery.

## Before you begin

- Day 10: async functions and actor isolation.
- Day 11: API response validation and decoding.
- Day 13: protocols and dependency injection.

## 1. Test decisions at the lowest useful layer

A useful test describes a behavior the product needs and fails when that behavior breaks. Start with decisions: whether a task title is valid, which state follows an empty response, and whether a retry replaces an error. These are easier to verify in small types than by launching the entire app. Keep a few UI tests for flows whose correctness depends on controls, navigation, keyboard behavior, or app integration.

Arrange the inputs and dependencies, act once, and assert the observable result. Avoid asserting private method names, exact internal call order without a requirement, or every line of implementation. A refactor that preserves behavior should normally preserve your tests. Name tests with a condition and expected result, such as testLoadEmptyResponseShowsEmptyState. When a test fails, its name and assertion should tell the next engineer what behavior changed.

## 2. Use test doubles deliberately

A stub returns a prepared value. A fake implements a lightweight working substitute, such as an in-memory task store. A mock records interaction when the interaction itself matters, such as ensuring one refresh occurs for simultaneous callers. These are roles, not frameworks you must install. A tiny Swift struct or actor is often enough.

Inject dependencies through an initializer and keep production defaults at the composition boundary. A view model that constructs URLSession.shared or reads global UserDefaults directly forces tests to share hidden state. Prefer separate UserDefaults suites, in-memory Core Data stores, temporary directories, and unique Keychain services. Clean them up even when a test fails. A test that works only after another test has run is exposing an unwanted dependency.

## 3. Async tests need synchronization, not sleeps

XCTest supports async test methods, so await the operation under test directly when it returns a value. Use expectations for callback-based APIs and fulfill them on the actual completion event. Do not sleep for a guessed number of milliseconds and assume a request has finished. That approach becomes flaky on a busy CI machine and needlessly slow on a fast one.

Keep MainActor-isolated view-model work on MainActor. Apply @MainActor to the relevant test method rather than weakening production isolation to make a test compile. A Sendable test stub should genuinely contain values safe to cross isolation boundaries. For race tests, use a controlled continuation or a small actor-based gate so the test decides when a response is released. Cancellation is a behavior to assert, not a failure to hide with try?.

## 4. Control the network boundary

Most unit tests should never need the public internet. Inject a service protocol to test view-model states, and test the API client separately using URLProtocol with an ephemeral URLSession. Return known bytes, a deliberate status code, or a transport error. Verify decoding and status handling independently; a JSON decoding error must not accidentally mask a missing HTTP validation step.

A common sample uses one mutable static URLProtocol handler. That shared global becomes a race when tests run in parallel and can conflict with Swift 6 concurrency checks. Prefer per-session or per-request fixture routing with synchronization if you need mutable state. The stretch exercise uses an immutable fixture protocol, avoiding a shared mutable handler entirely. Its fixed response is suitable for one client boundary test, not a general-purpose networking framework.

## 5. Use UI tests where interaction matters

XCUITest launches and drives your app through accessibility. Give important controls stable accessibilityIdentifier values such as task.titleField and task.saveButton; localized visible text should not be the only test selector. Launch the app with a documented argument that selects an in-memory fixture environment, so UI tests can exercise empty, loaded, and failed screens reproducibly without depending on a real account.

Wait for a specific element with waitForExistence(timeout:) and assert the visible result of an action. Cover a small set of valuable flows: create a task, reject an empty title, recover from an error, and navigate to details and back. Test visual adaptivity with accessibility settings and manual inspection as well. Passing unit tests does not prove that text is readable, VoiceOver order is sensible, or a button remains visible above the keyboard.

## Worked example: An async view-model test suite

**File:** TaskListViewModelTests.swift

```swift
import Foundation
import XCTest

// Self-contained teaching types. Put this entire file in an iOS
// Unit Testing target; no app module import is required.
private struct TaskItem: Equatable, Sendable {
    let id: Int
    let title: String
}

private enum StubError: Error {
    case offline
}

private protocol TaskLoading: Sendable {
    func fetchTasks() async throws -> [TaskItem]
}

private struct StubLoader: TaskLoading {
    let result: Result<[TaskItem], StubError>

    func fetchTasks() async throws -> [TaskItem] {
        try result.get()
    }
}

@MainActor
private final class TaskListViewModel {
    enum State: Equatable {
        case idle, loading, empty
        case loaded([TaskItem])
        case failed(String)
    }

    private(set) var state: State = .idle
    private let loader: any TaskLoading

    init(loader: any TaskLoading) {
        self.loader = loader
    }

    func load() async {
        state = .loading
        do {
            let items = try await loader.fetchTasks()
            try Task.checkCancellation()
            state = items.isEmpty ? .empty : .loaded(items)
        } catch is CancellationError {
            state = .idle
        } catch {
            // Cancellation may arrive as a transport error instead.
            guard !Task.isCancelled else {
                state = .idle
                return
            }
            state = .failed("Could not load tasks.")
        }
    }
}

final class TaskListViewModelTests: XCTestCase {
    @MainActor
    func testLoadSuccessPublishesItems() async {
        let items = [TaskItem(id: 1, title: "Study UIKit")]
        let model = TaskListViewModel(
            loader: StubLoader(result: .success(items))
        )
        await model.load()
        let actual = model.state
        XCTAssertEqual(actual, .loaded(items))
    }

    @MainActor
    func testEmptyResponseShowsEmptyState() async {
        let model = TaskListViewModel(
            loader: StubLoader(result: .success([]))
        )
        await model.load()
        let actual = model.state
        XCTAssertEqual(actual, .empty)
    }

    @MainActor
    func testFailureShowsRecoverableMessage() async {
        let model = TaskListViewModel(
            loader: StubLoader(result: .failure(.offline))
        )
        await model.load()
        let actual = model.state
        XCTAssertEqual(actual, .failed("Could not load tasks."))
    }
}
```

### Walkthrough and setup

1. In Xcode, add an iOS Unit Testing Bundle if the project has none. Add this file to that test target only, then use Product > Test.
2. The teaching types are private and self-contained. In your app, keep the real implementation in the app or a library target and use @testable import PocketTasks in tests instead of duplicating production code.
3. StubLoader is immutable and Sendable. Its result makes success, empty, and failure cases immediate and independent of a server.
4. Only test methods that touch the MainActor view model are annotated. Each assertion compares a local snapshot of observable state.
5. This small model assumes one load at a time. A real searchable list also needs stale-request protection and tests for out-of-order responses from Day 12.
6. The model also checks Task.isCancelled in its generic catch: a cancelled URLSession operation may throw URLError.cancelled instead of CancellationError. A cancelled owning task returns to idle; ordinary failures still produce the recoverable message.

**Expected behavior:** Three tests pass in an iOS test destination. A change that stops mapping an empty result to .empty should fail the empty-state test.

## Challenge 1: Test title validation at its boundaries

**Level:** Warm-up

Write tests for a title normalizer that trims whitespace, rejects empty titles, and accepts titles with at most 80 characters after trimming.

### Requirements

- Test whitespace-only input, exactly 80 characters, and 81 characters.
- Check the returned normalized value.
- Avoid relying on test execution order.

### Starter

```swift
import Foundation
func normalizedTitle(_ input: String) -> String? {
    let value = input.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !value.isEmpty, value.count <= 80 else { return nil }
    return value
}
// Add XCTest assertions for the boundaries.
```

<details>
<summary>Hints</summary>

- String(repeating:count:) creates exact boundary inputs.
- Swift String.count counts characters, not UTF-8 bytes.

</details>

### Acceptance checks

- Changing <= 80 to < 80 breaks the boundary test.
- Removing trimming breaks the normalization test.
- No test reads a global clock, network, or shared store.

<details>
<summary>Worked solution</summary>

```swift
import Foundation
import XCTest

private func normalizedTitle(_ input: String) -> String? {
    let value = input.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !value.isEmpty, value.count <= 80 else { return nil }
    return value
}

final class TitleValidationTests: XCTestCase {
    func testTrimsBeforeValidation() {
        XCTAssertEqual(normalizedTitle("  Read docs\n"), "Read docs")
    }

    func testWhitespaceIsRejected() {
        XCTAssertNil(normalizedTitle(" \n\t "))
    }

    func testMaximumBoundary() {
        let accepted = String(repeating: "a", count: 80)
        XCTAssertEqual(normalizedTitle(accepted), accepted)
        XCTAssertNil(normalizedTitle(accepted + "a"))
    }
}
```

Boundary tests are more valuable than repeating many ordinary inputs. The contract here uses user-perceived characters; if a backend limits bytes, define and test a matching contract rather than assuming the two are equivalent.

</details>

## Challenge 2: Prove recovery after an initial failure

**Level:** Core

Using the teaching types from the example, provide an actor-based loader that fails once, then succeeds. Test that calling load again replaces the error with loaded content.

### Requirements

- Make the loader state safe for async calls.
- Assert the first failure and the successful retry separately.
- Do not use sleep or a real network request.

### Starter

```swift
// Add this exercise to TaskListViewModelTests.swift.
private actor RetryLoader: TaskLoading {
    func fetchTasks() async throws -> [TaskItem] {
        // Fail once, then return a fixture.
        []
    }
}
```

<details>
<summary>Hints</summary>

- An actor can keep a private call counter.
- An async method can satisfy the TaskLoading protocol.

</details>

### Acceptance checks

- The first load publishes an error.
- The second load publishes the fixture item.
- The test remains independent of connection speed and server availability.

<details>
<summary>Worked solution</summary>

```swift
// Add to the same test file as the example.
private actor RetryLoader: TaskLoading {
    private var calls = 0
    func fetchTasks() async throws -> [TaskItem] {
        calls += 1
        if calls == 1 { throw StubError.offline }
        return [TaskItem(id: 2, title: "Retry succeeded")]
    }
}

extension TaskListViewModelTests {
    @MainActor
    func testRetryReplacesFailureWithContent() async {
        let model = TaskListViewModel(loader: RetryLoader())
        await model.load()
        let first = model.state
        XCTAssertEqual(first, .failed("Could not load tasks."))

        await model.load()
        let second = model.state
        XCTAssertEqual(
            second,
            .loaded([TaskItem(id: 2, title: "Retry succeeded")])
        )
    }
}
```

This fake models an important temporal behavior with a controlled sequence. It verifies that failure does not permanently trap the model. It does not prove the retry button is wired correctly; a separate UI test covers that connection.

</details>

## Challenge 3: Test a URLSession boundary without the internet

**Level:** Stretch

Use an immutable URLProtocol fixture to deliver a known HTTP response. Verify that an ephemeral session receives the exact bytes and status code.

### Requirements

- Intercept only requests to fixture.test.
- Do not introduce a mutable static handler.
- Invalidate the URLSession at the end.
- Keep the test in the test target.

### Starter

```swift
import Foundation
import XCTest
// Implement FixtureURLProtocol and a URLSession test.
```

<details>
<summary>Hints</summary>

- Override canInit, canonicalRequest, startLoading, and stopLoading.
- Set configuration.protocolClasses before constructing the session.
- Notify the URLProtocol client of response, data, and completion in that order.

</details>

### Acceptance checks

- No request reaches the public network.
- Changing the fixture status or bytes changes the assertion result.
- The protocol has no shared mutable static state.

<details>
<summary>Worked solution</summary>

```swift
import Foundation
import XCTest

private final class FixtureURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == "fixture.test"
    }

    override class func canonicalRequest(
        for request: URLRequest
    ) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url,
              let response = HTTPURLResponse(
                url: url, statusCode: 200, httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
              ) else { return }
        let bytes = Data("[{\"id\":1,\"title\":\"Fixture\"}]".utf8)
        client?.urlProtocol(
            self, didReceive: response, cacheStoragePolicy: .notAllowed
        )
        client?.urlProtocol(self, didLoad: bytes)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

final class SessionBoundaryTests: XCTestCase {
    func testReceivesFixtureResponse() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [FixtureURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }

        let url = try XCTUnwrap(URL(string: "https://fixture.test/tasks"))
        let (data, response) = try await session.data(from: url)
        let http = try XCTUnwrap(response as? HTTPURLResponse)
        XCTAssertEqual(http.statusCode, 200)
        XCTAssertEqual(
            String(data: data, encoding: .utf8),
            "[{\"id\":1,\"title\":\"Fixture\"}]"
        )
    }
}
```

This validates that your test harness controls the URLSession boundary. Next inject this session into the actual API client and assert decoded models and non-2xx behavior. The fixture finishes synchronously, so stopLoading has no outstanding operation to cancel. An asynchronous fixture would need cancellation handling.

</details>

## Knowledge check

### 1. Which test double simply supplies a prepared response?

A. A profiler

B. A stub

C. A provisioning profile

D. A storyboard

<details>
<summary>Answer and explanation</summary>

**B. A stub**

A stub controls returned data. A mock is useful when verifying an interaction itself is part of the requirement.

</details>

### 2. What is the best synchronization for an async function returning a result?

A. Sleep for two seconds

B. Run the test twice

C. Await the function

D. Disable concurrency checks

<details>
<summary>Answer and explanation</summary>

**C. Await the function**

Await observes actual completion and avoids timing guesses.

</details>

### 3. Why use accessibilityIdentifier in UI tests?

A. It grants camera permission

B. It gives a stable selector independent of visible translations

C. It hides the control from VoiceOver

D. It makes every test synchronous

<details>
<summary>Answer and explanation</summary>

**B. It gives a stable selector independent of visible translations**

Identifiers let UI tests locate controls without depending entirely on localized labels.

</details>

### 4. Where should most view-model state tests perform network calls?

A. Against a production server

B. Against a random public API

C. Through an injected deterministic test double

D. Only over cellular data

<details>
<summary>Answer and explanation</summary>

**C. Through an injected deterministic test double**

A controlled dependency makes states reproducible and keeps tests fast and independent.

</details>

### 5. A test fails only when the suite runs in parallel. What should you inspect first?

A. The app icon

B. Shared mutable state and fixture isolation

C. The font family

D. Whether the device has a SIM card

<details>
<summary>Answer and explanation</summary>

**B. Shared mutable state and fixture isolation**

Shared handlers, defaults, files, and databases can contaminate parallel tests.

</details>

## Common pitfalls

- A sleep-based test can pass locally and fail on CI.
- Duplicating production logic in a test can repeat the same defect.
- Shared defaults, Keychain items, and URLProtocol handlers can leak across tests.
- A passing service test does not prove that the UI button calls the service.
- Disabling actor isolation to satisfy tests hides the production ownership problem.

## PocketTasks milestone: Protect PocketTasks behavior

1. Add title-validation, empty-list, successful-load, failed-load, and retry tests.
2. Inject fixture services through the app's composition root when a UI-test launch argument is present.
3. Give the add, title, save, retry, and first task controls stable identifiers.
4. Add a UI test that creates a task and verifies its title appears in the list.

## Before you move on

- Write a pure boundary test that fails for a meaningful behavior change.
- Test success, empty, failure, and recovery in the list view model.
- Explain why each test double was chosen.
- Run one critical UI flow with fixture data and stable accessibility identifiers.
- Describe how out-of-order async responses would be tested without arbitrary sleeps.

## Official references

- [Apple: XCTest](https://developer.apple.com/documentation/xctest)
- [Apple: URLProtocol](https://developer.apple.com/documentation/foundation/urlprotocol)
- [Apple: XCUIAutomation](https://developer.apple.com/documentation/xcuiautomation)

## Reflection

- What can I now explain without the example?
- What did I build and test in Xcode?
- Which bug or design tradeoff do I want to revisit?
