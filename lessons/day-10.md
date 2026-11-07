# Day 10: Concurrency without UI races

Use async/await, actors, and cancellation to keep UIKit responsive and state correct.

**Time:** 3–4 hours · **Target:** Swift 6 / iOS 17+

[Interactive lesson](http://hafizr283.me/uikit-path/#/day/10/lesson) · [Course overview](../README.md)

## Outcomes

- Distinguish suspension from blocking and asynchronous code from background execution.
- Use MainActor for UIKit-owned state and actors for isolated shared mutable state.
- Choose structured child tasks or an explicitly owned Task appropriately.
- Cancel obsolete work and prevent stale results from reaching the screen.
- Recognize Swift 6 Sendable and isolation diagnostics as design feedback.

## Before you begin

- Days 1–2: closures, errors, reference ownership, and weak captures.
- Day 3: controller lifecycle and main-thread UI requirements.

## 1. Async means a function can suspend

An async function can pause at a suspension point while another task makes progress. Awaiting URLSession therefore does not occupy the main thread waiting for network bytes. However, async does not mean every line runs in the background. A large synchronous image transformation placed in a MainActor task still blocks the interface. Identify the expensive operation and its isolation rather than using async as a performance label.

Actors isolate mutable state. MainActor is the global actor used for most UIKit interactions. Marking a view model @MainActor makes its UI-facing state and methods consistently isolated. Swift 6 checks unsafe crossings more strictly, so compiler errors often expose a real ownership ambiguity. Do not silence them with unchecked Sendable or nonisolated(unsafe) as a first response.

## 2. Structured work has a parent and a lifetime

Use async let when a fixed number of independent operations should start together and their results are needed before the function returns. Use a task group when the number of child operations is dynamic. Structured child tasks cannot outlive the scope that owns them; errors and cancellation can propagate through that task tree. This makes their lifetime easier to reason about.

Task { ... } creates an unstructured task, often useful when a synchronous button action must enter asynchronous code. It inherits the surrounding actor context, but you own its cancellation and result handling. Store its handle if replacement, navigation, or explicit cancellation should stop it. Task.detached does not inherit that actor context and is rarely the right first tool for a screen request.

## 3. Cancellation is a request, not a kill switch

Calling cancel sets a cancellation flag and notifies cancellation-aware operations. It does not forcibly stop arbitrary code. Task.sleep and URLSession async operations cooperate with cancellation; your own loops need Task.checkCancellation or another periodic check. A request can also finish near the moment it is cancelled, so check before applying its result.

Search adds a second problem: an older request can finish after a newer one. Cancellation reduces wasted work; a request generation or matching query check guarantees that only the latest result is accepted. Treat CancellationError as an expected control-flow outcome rather than showing an error alert every time the user changes a search term or leaves a screen.

## 4. Sendable describes safe transfer

A Sendable value can cross concurrency boundaries safely. Immutable structs composed of Sendable properties are good transport models; actors are safe references to isolated state. A mutable UIKit view is not a value to send into background work. Capture the needed input value, perform work in the appropriate isolation domain, then return a result to MainActor for rendering.

Actor isolation protects individual synchronous actor segments, not an entire operation across await. While one actor method is suspended, another call can change its state. This is actor reentrancy. For example, read-check-await-write can use stale assumptions after the await. Revalidate conditions, use generation tokens, or move state changes into a synchronous actor transaction when consistency requires it.

## 5. Bridge older APIs deliberately

Company code may use completion handlers, delegates, DispatchQueue, or OperationQueue. Read their contracts: which queue invokes the completion, can it fire more than once, and how is work cancelled? A continuation can adapt a callback API to async, but it must resume exactly once. A checked continuation helps catch missing or repeated resumes during development; it does not automatically provide cancellation.

Use MainActor.run when an asynchronous context needs a short isolated UI mutation and is not already main-actor isolated. Avoid sprinkling DispatchQueue.main.async around a view model that should simply be @MainActor. For CPU-heavy work, design a clear worker boundary and pass Sendable inputs. Modern concurrency complements profiling and API contracts; it does not remove the need for them.

## Worked example: A cancellable UIKit loading screen

**File:** AsyncDemoViewController.swift

```swift
import UIKit

actor MessageService {
    func fetchMessage() async throws -> String {
        try await Task.sleep(for: .milliseconds(900))
        try Task.checkCancellation()
        return "Your task list is ready."
    }
}

@MainActor
final class AsyncDemoViewController: UIViewController {
    private let service = MessageService()
    private let label = UILabel()
    private var loadTask: Task<Void, Never>?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Async loading"
        view.backgroundColor = .systemBackground
        label.text = "Tap Load"
        label.textAlignment = .center
        label.numberOfLines = 0

        let button = UIButton(type: .system)
        button.setTitle("Load", for: .normal)
        button.addTarget(self, action: #selector(load), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [label, button])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)
        ])
    }

    @objc private func load() {
        loadTask?.cancel()
        label.text = "Loading…"
        let service = service
        loadTask = Task { [weak self] in
            do {
                let message = try await service.fetchMessage()
                try Task.checkCancellation()
                self?.label.text = message
            } catch is CancellationError {
                // A newer load or navigation made this work unnecessary.
            } catch {
                self?.label.text = "Could not load. Try again."
            }
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        loadTask?.cancel()
        loadTask = nil
    }
}
```

### Walkthrough and setup

1. Add the file to a UIKit iOS app and push AsyncDemoViewController. MessageService uses a cancellable delay to simulate a network request; it does not access a real server.
2. The controller and its UI state are MainActor isolated. The button starts an unstructured Task from that context, so its UI mutations remain isolated.
3. The actor service suspends during the delay. It does not block the main thread while waiting.
4. The task closure weakly captures the controller and does not promote it to a strong reference before the await, so the request need not keep the screen alive.
5. A second tap cancels the previous task. Leaving the screen cancels outstanding work. The post-await check prevents a cancelled result from being rendered.
6. For production search with services that may ignore cancellation, also use the generation-token exercise below.

**Expected behavior:** Tap Load to see a loading message, then a success message after about 0.9 seconds. Rapid taps restart the request. Navigating away cancels the outstanding delay.

## Challenge 1: Protect a shared counter with an actor

**Level:** Warm-up

Create an actor-backed counter and increment it from 100 child tasks. Return the final value only after every child has completed.

### Requirements

- Keep the mutable counter private to the actor.
- Use a task group rather than 100 untracked Task handles.
- Do not use locks or unchecked Sendable.

### Starter

```swift
actor Counter {
    // Isolated state and methods.
}

func countCompletedWork() async -> Int {
    // Start and await 100 children.
    return 0
}
```

<details>
<summary>Hints</summary>

- An actor method without await runs as one uninterrupted actor segment.
- Call actor methods with await from outside its isolation domain.

</details>

### Acceptance checks

- Await the function and verify the result is always 100.
- Explain why reading the value before waiting for the group would be logically premature.

<details>
<summary>Worked solution</summary>

```swift
actor Counter {
    private var value = 0
    func increment() { value += 1 }
    func currentValue() -> Int { value }
}

func countCompletedWork() async -> Int {
    let counter = Counter()
    await withTaskGroup(of: Void.self) { group in
        for _ in 0..<100 {
            group.addTask { await counter.increment() }
        }
        await group.waitForAll()
    }
    return await counter.currentValue()
}
```

Child tasks may execute in any order. The actor serializes access to its isolated value, and the group scope waits for completion. Serialization here protects a tiny state mutation; placing all expensive unrelated work inside one actor could unnecessarily reduce throughput.

</details>

## Challenge 2: Load independent counts concurrently

**Level:** Core

Write a summary loader that fetches open and completed counts concurrently from an actor service, then returns a Sendable value.

### Requirements

- Use two async let bindings.
- Propagate service errors to the caller.
- Return both values only after both operations finish.

### Starter

```swift
struct TaskSummary: Sendable {
    let open: Int
    let completed: Int
}
// Implement a service and summary loader.
```

<details>
<summary>Hints</summary>

- async let starts a structured child operation.
- A tuple await can collect both results.

</details>

### Acceptance checks

- Verify the result is open 8 and completed 3.
- Observe that elapsed time is approximately the longer delay, allowing scheduler overhead.
- Replace one return with a thrown error and verify the caller receives it.

<details>
<summary>Worked solution</summary>

```swift
struct TaskSummary: Sendable {
    let open: Int
    let completed: Int
}

actor SummaryService {
    func openCount() async throws -> Int {
        try await Task.sleep(for: .milliseconds(400))
        return 8
    }
    func completedCount() async throws -> Int {
        try await Task.sleep(for: .milliseconds(600))
        return 3
    }
}

func loadSummary(from service: SummaryService) async throws -> TaskSummary {
    async let open = service.openCount()
    async let completed = service.completedCount()
    let values = try await (open, completed)
    return TaskSummary(open: values.0, completed: values.1)
}
```

The service actor can accept the second call while the first is suspended in Task.sleep. The two waits overlap even though actor-isolated synchronous work never runs simultaneously on the actor. If an operation throws and the scope exits, remaining structured children are cancelled and awaited.

</details>

## Challenge 3: Reject stale search results

**Level:** Stretch

Implement a MainActor search model with debounce, cancellation, and a generation check. The latest query must win even when earlier work finishes later.

### Requirements

- Use a 250 ms debounce.
- Capture the query value for that request.
- Do not deliver cancellation as an error to the user.
- Provide an explicit cancel method for the screen owner.

### Starter

```swift
actor TaskSearchService {
    func search(_ query: String) async throws -> [String] {
        try await Task.sleep(for: .milliseconds(300))
        return ["Result for \(query)"]
    }
}
// Implement SearchModel.
```

<details>
<summary>Hints</summary>

- Increment a generation before starting each request.
- Compare the captured generation immediately before delivering results.

</details>

### Acceptance checks

- Search for a, then ab, then abc rapidly; only abc is delivered.
- Cancel before the debounce expires and verify no result is delivered.
- Simulate a slow first request and faster second request; the first must never replace the second.

<details>
<summary>Worked solution</summary>

```swift
@MainActor
final class SearchModel {
    private let service = TaskSearchService()
    private var request: Task<Void, Never>?
    private var generation = 0
    var onResults: (([String]) -> Void)?
    var onError: ((String) -> Void)?

    func search(_ query: String) {
        generation += 1
        let current = generation
        request?.cancel()
        let service = service
        request = Task { [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(250))
                let results = try await service.search(query)
                try Task.checkCancellation()
                guard let self, current == self.generation else { return }
                self.onResults?(results)
            } catch is CancellationError {
            } catch {
                guard let self, current == self.generation else { return }
                self.onError?("Search failed. Please retry.")
            }
        }
    }

    func cancel() {
        generation += 1
        request?.cancel()
        request = nil
    }
}
```

The request handle reduces unnecessary work, while the generation check is the acceptance rule for results. Bind onResults from a controller using a weak controller capture, and call cancel when the owning screen no longer needs results. Keeping the entire model on MainActor also makes generation comparisons and delivery one uninterrupted state transition.

</details>

## Knowledge check

### 1. Does adding async to a function move all its computation off the main actor?

A. Yes, always

B. Only if it returns Void

C. No; suspension and execution isolation are separate concerns

D. Yes, if it contains a print statement

<details>
<summary>Answer and explanation</summary>

**C. No; suspension and execution isolation are separate concerns**

Async permits suspension. Actor context and the operation's implementation determine where synchronous work runs.

</details>

### 2. What does Task.cancel() guarantee?

A. It forcibly terminates every instruction immediately

B. It requests cancellation that work must cooperate with

C. It automatically displays an error alert

D. It releases every captured object immediately

<details>
<summary>Answer and explanation</summary>

**B. It requests cancellation that work must cooperate with**

Cancellation is cooperative. Use cancellation-aware APIs and check cancellation before accepting results or during long-running loops.

</details>

### 3. Which tool fits two independent operations whose results are needed in the current function?

A. Two forgotten Task.detached calls

B. async let bindings

C. A global mutable array

D. A blocking semaphore on MainActor

<details>
<summary>Answer and explanation</summary>

**B. async let bindings**

async let provides structured child tasks with a scope-bound lifetime and straightforward result collection.

</details>

### 4. Why can actor state change while an actor method is awaiting?

A. Actors provide no isolation

B. The actor can process other calls during suspension

C. The compiler copies the entire actor

D. Await disables memory management

<details>
<summary>Answer and explanation</summary>

**B. The actor can process other calls during suspension**

Actors are reentrant across suspension points. Revalidate assumptions made before await if correctness depends on them.

</details>

### 5. What is the strongest way to stop an old search from replacing newer results?

A. Only make the spinner slower

B. Always ignore all errors

C. Cancel old work and validate a request generation before delivery

D. Store the old index path

<details>
<summary>Answer and explanation</summary>

**C. Cancel old work and validate a request generation before delivery**

Cancellation saves work but may race with completion or be ignored. Generation validation determines whether a result still belongs to the current request.

</details>

## Common pitfalls

- Doing CPU-heavy synchronous work inside a MainActor task and expecting async to make it cheap.
- Treating Task cancellation as forced termination.
- Strongly retaining a controller across a long await without considering its lifetime.
- Using Task.detached to bypass isolation diagnostics.
- Assuming actor state cannot change across an await.
- Showing cancellation as a user-facing failure during ordinary navigation.

## PocketTasks milestone: PocketTasks milestone: responsive asynchronous work

1. Add an actor-backed mock task service with controllable delay and failure.
2. Represent loading state on MainActor and keep the interface responsive.
3. Give each screen-owned request a cancellation policy.
4. Implement debounced task search with a latest-request acceptance rule.

## Before you move on

- Explain async suspension versus blocking with one UIKit example.
- Show which object owns every unstructured task handle.
- Demonstrate cancellation during navigation and rapid search changes.
- Explain why a generation check protects against stale results.
- Read a Swift 6 isolation diagnostic and identify the boundary it is protecting.

## Official references

- [Swift concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
- [Task](https://developer.apple.com/documentation/swift/task)
- [MainActor](https://developer.apple.com/documentation/swift/mainactor)
- [Sendable](https://developer.apple.com/documentation/swift/sendable)

## Reflection

- What can I now explain without the example?
- What did I build and test in Xcode?
- Which bug or design tradeoff do I want to revisit?
