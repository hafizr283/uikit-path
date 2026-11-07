# Day 13: Architecture that makes changes easier

Use MVC, MVVM, dependency injection, and repositories to give each responsibility a clear owner.

**Time:** 3–4 hours · **Target:** Swift 6 / iOS 17+

[Interactive lesson](http://hafizr283.me/uikit-path/#/day/13/lesson) · [Course overview](../README.md)

## Outcomes

- Recognize when a view controller has accumulated unrelated responsibilities.
- Separate transport models, domain rules, presentation state, and UIKit rendering.
- Inject replaceable dependencies through small protocols.
- Keep one authoritative owner for shared task data.
- Use coordinators where navigation complexity justifies them.

## Before you begin

- Days 10–12: async services, screen state, cancellation, and rendering.
- Protocols, initializers, value types, and ARC.

## 1. Start with responsibilities, not folder names

MVC remains a useful UIKit model: models represent application data and rules, views display content and accept input, and controllers connect them. Problems arise when the controller also constructs HTTP requests, decodes JSON, manages a database, formats every field, and coordinates several navigation flows. The issue is the number of responsibilities, not the fact that a class ends with ViewController.

Architecture should make a likely change local and testable. Ask where a new API field, a business validation rule, or a different presentation belongs. Moving a thousand-line controller into a thousand-line view model does not solve unclear ownership. Split along meaningful boundaries and keep small features simple until there is a demonstrated need for another abstraction.

## 2. MVVM separates presentation decisions from widgets

A view model owns UI-facing state and transforms domain values into display values. A controller creates and configures UIKit objects, forwards user actions, and renders state. The view model should not need a UILabel or UINavigationController to decide that a completed task has a Completed subtitle. That lets tests evaluate behavior without constructing a window.

For a UIKit application, marking the view model @MainActor is often a clear choice because its state is observed by the UI. It can await a repository without blocking network waits. Decide whether the view model owns unstructured task handles or exposes async methods whose caller owns the task; both can work, but mixing the policies unpredictably makes cancellation and lifetime harder to reason about.

## 3. A repository is a data policy boundary

An API client speaks HTTP. A persistence store speaks files or database operations. A repository exposes domain operations such as listTasks or toggleTask and decides where authoritative data comes from. An offline-first repository might read local records immediately, synchronize remote changes, and publish accepted updates. A small in-memory repository is excellent for learning and deterministic tests.

Do not maintain separate writable task arrays in the inbox, board, and detail controller with no synchronization rule. Let a repository or shared domain store own task values, and let screens own presentation state such as selected filters. A screen may hold a snapshot for rendering, but mutations should flow through the authoritative owner so other screens can refresh or observe changes consistently.

## 4. Dependency injection makes choices explicit

Constructor injection gives a type the services it needs when it is created. A protocol describes the smallest useful capability, such as fetchTasks, rather than duplicating every method of a concrete class. A composition root near app or scene setup chooses production implementations and connects the graph. Tests choose a fake without changing the view model.

Protocols are not mandatory for every struct. They are valuable at changeable or nondeterministic boundaries: network, storage, time, authentication, and navigation. Avoid service locators and shared singletons as a shortcut for every dependency; they hide requirements and make tests depend on global state. Also avoid dozens of one-line layers that simply forward a call without clarifying a responsibility.

## 5. Navigation and ownership belong in the design

A coordinator can own a navigation flow and construct its screens, keeping route decisions outside presentation logic. The coordinator typically owns the navigation controller and any active child coordinators; a screen signals intent through a delegate or closure. Ensure these references do not form a retain cycle. A parent must retain a coordinator for as long as its flow is active.

For a single simple push, a controller can navigate directly. Introduce a coordinator when routes, authentication gates, deep links, or multi-step flows become difficult to maintain. Folder organization can group code by feature, with shared infrastructure separate, but folder structure is only a map. Review actual dependency direction: business rules should not import your entire UI layer just to validate a task title.

## Worked example: A repository-backed, UIKit-independent view model

**File:** TasksArchitecture.swift

```swift
import Foundation

struct TaskRecord: Identifiable, Sendable {
    let id: UUID
    var title: String
    var isDone: Bool
}

protocol TaskRepository: Sendable {
    func fetchTasks() async throws -> [TaskRecord]
    func toggleTask(id: UUID) async throws
}

enum RepositoryError: Error { case missingTask }

actor MemoryTaskRepository: TaskRepository {
    private var tasks: [TaskRecord]

    init(tasks: [TaskRecord]) { self.tasks = tasks }

    func fetchTasks() async throws -> [TaskRecord] { tasks }

    func toggleTask(id: UUID) async throws {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else {
            throw RepositoryError.missingTask
        }
        tasks[index].isDone.toggle()
    }
}

struct TaskRow: Identifiable, Equatable, Sendable {
    let id: UUID
    let title: String
    let subtitle: String

    init(task: TaskRecord) {
        id = task.id
        title = task.title
        subtitle = task.isDone ? "Completed" : "To do"
    }
}

enum TasksPresentation {
    case idle
    case loading
    case ready([TaskRow])
    case failed(String)
}

@MainActor
final class TasksViewModel {
    private let repository: any TaskRepository
    private var generation = 0
    private(set) var state: TasksPresentation = .idle {
        didSet { onChange?(state) }
    }
    var onChange: ((TasksPresentation) -> Void)?

    init(repository: any TaskRepository) {
        self.repository = repository
    }

    func reload() async {
        generation += 1
        let current = generation
        state = .loading
        do {
            let records = try await repository.fetchTasks()
            try Task.checkCancellation()
            guard current == generation else { return }
            state = .ready(records.map(TaskRow.init))
        } catch is CancellationError {
            // The owner cancelled this presentation request.
        } catch {
            // URLSession may report cancellation as URLError.cancelled.
            guard !Task.isCancelled, current == generation else { return }
            state = .failed("Unable to load tasks. Please retry.")
        }
    }
}

// A small composition root for an example or test.
// A UIKit controller can observe onChange and render rows with a diffable source.
@MainActor
func makeDemoViewModel() -> TasksViewModel {
    let repository = MemoryTaskRepository(tasks: [
        TaskRecord(id: UUID(), title: "Separate rendering from data access", isDone: false),
        TaskRecord(id: UUID(), title: "Inject a repository", isDone: true)
    ])
    return TasksViewModel(repository: repository)
}

@MainActor
func demonstrateArchitecture() async {
    let model = makeDemoViewModel()
    model.onChange = { state in
        if case .ready(let rows) = state {
            print(rows.map(\.subtitle))
        }
    }
    await model.reload()
}
```

### Walkthrough and setup

1. This Foundation-only file demonstrates the architecture boundary; it deliberately contains no UIKit widgets. Add it to an app or suitable Swift target and await demonstrateArchitecture() from an async context.
2. TaskRepository is Sendable so its implementation can cross from the main-actor view model to an actor-backed store safely. The actor serializes mutations to its task array.
3. TaskRecord represents domain data. TaskRow represents one screen's display values. They need not remain separate in every tiny app, but the distinction becomes useful when formatting and server contracts evolve.
4. The view model exposes an async reload method. In a controller, store the Task handle that calls it and cancel according to the screen's lifecycle; do not create an untracked load on every appearance.
5. The composition root decides the concrete repository. Replacing MemoryTaskRepository with a tested remote/local implementation does not require rewriting the renderer.
6. Cancellation can surface as CancellationError or as a transport error from URLSession. The generic catch checks the owning task's cancellation flag and the current generation before publishing a genuine failure.

**Expected behavior:** The demonstration prints ["To do", "Completed"]. A controller can render the same state without knowing whether the records came from memory, HTTP, or persistent storage.

## Challenge 1: Move presentation logic out of a cell

**Level:** Warm-up

A custom cell formats a task's status in several conditionals. Create a pure presentation value with a title, status text, and accessibility summary.

### Requirements

- Keep UIKit out of the presentation type.
- Retain stable task identity.
- Make complete and incomplete behavior explicit.

### Starter

```swift
struct AccessibleTaskRow {
    // Initialize from TaskRecord.
}
```

<details>
<summary>Hints</summary>

- A value type can calculate display properties during initialization.
- Keep styling in UIKit while returning meaningful text.

</details>

### Acceptance checks

- A completed task maps to Completed and an incomplete task to To do.
- The UUID matches the original task.
- The type can be tested without importing UIKit.

<details>
<summary>Worked solution</summary>

```swift
struct AccessibleTaskRow: Identifiable, Equatable, Sendable {
    let id: UUID
    let title: String
    let status: String
    let accessibilitySummary: String

    init(task: TaskRecord) {
        id = task.id
        title = task.title
        status = task.isDone ? "Completed" : "To do"
        accessibilitySummary = "\(task.title), \(status)"
    }
}
```

The cell now applies values instead of deciding domain meaning. These strings are English for the exercise; production localization should use localized resources and appropriate formatting. Do not set an accessibility label blindly if it would duplicate text already read from accessible subviews.

</details>

## Challenge 2: Inject a repository that fails predictably

**Level:** Core

Build a fake repository that throws a known error. Use it to verify that TasksViewModel reaches its recoverable failure state.

### Requirements

- Conform to TaskRepository without a network call.
- Keep the fake Sendable.
- Await reload before inspecting state.
- Do not depend on a real server being offline.

### Starter

```swift
struct FailingRepository: TaskRepository {
    // Implement both protocol operations.
}
```

<details>
<summary>Hints</summary>

- A stateless struct can safely conform to Sendable.
- A dedicated test error keeps the failure deterministic.

</details>

### Acceptance checks

- The verification returns true every time without internet access.
- Changing the fake to return an empty array leads to ready with zero rows.
- Explain why a real timeout would be a slower and less reliable unit test.

<details>
<summary>Worked solution</summary>

```swift
enum DemoFailure: Error { case unavailable }

struct FailingRepository: TaskRepository {
    func fetchTasks() async throws -> [TaskRecord] {
        throw DemoFailure.unavailable
    }

    func toggleTask(id: UUID) async throws {
        throw DemoFailure.unavailable
    }
}

@MainActor
func verifyFailureState() async -> Bool {
    let model = TasksViewModel(repository: FailingRepository())
    await model.reload()
    if case .failed(let message) = model.state {
        return message.contains("retry")
    }
    return false
}
```

This fake represents a specific boundary outcome and makes the test repeatable. It verifies behavior that matters to the user: the view model offers a recoverable failure state. Day 16 converts this kind of check into XCTest assertions and adds success, empty, and cancellation coverage.

</details>

## Challenge 3: Extract a navigation flow

**Level:** Stretch

Create a small coordinator that owns a navigation controller and pushes a task detail controller when a list emits a task-selection closure.

### Requirements

- Use a weak coordinator capture in the selection closure.
- Retain the coordinator from the scene or another owner.
- Pass the selected task ID to the detail screen.
- Keep this routing choice out of the view model.

### Starter

```swift
// UIKit routing exercise; use these small standalone placeholder controllers.
@MainActor
final class TaskListScreen: UIViewController {
    var onSelect: ((UUID) -> Void)?
}
```

<details>
<summary>Hints</summary>

- The coordinator can create the list in start().
- The scene must keep a strong property for the coordinator.

</details>

### Acceptance checks

- Trigger onSelect with a UUID and inspect that same UUID in the detail screen.
- Pop the detail controller and confirm it can be released.
- Remove the scene's coordinator reference during teardown and inspect the ownership graph.

<details>
<summary>Worked solution</summary>

```swift
import UIKit

@MainActor
final class TaskListScreen: UIViewController {
    var onSelect: ((UUID) -> Void)?
}

@MainActor
final class TaskDetailScreen: UIViewController {
    let taskID: UUID
    init(taskID: UUID) {
        self.taskID = taskID
        super.init(nibName: nil, bundle: nil)
        title = "Task details"
    }
    required init?(coder: NSCoder) {
        fatalError("Use init(taskID:).")
    }
}

@MainActor
final class TasksCoordinator {
    let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let list = TaskListScreen()
        list.title = "PocketTasks"
        list.onSelect = { [weak self] id in
            self?.navigationController.pushViewController(
                TaskDetailScreen(taskID: id), animated: true
            )
        }
        navigationController.setViewControllers([list], animated: false)
    }
}
```

The two screen classes are routing placeholders; connect onSelect to the actual list delegate and build the detail UI separately. Retain TasksCoordinator as a scene property, create it with the scene's navigation controller, and call start. The navigation controller retains its screens, so their callbacks should not strongly retain the coordinator that owns it.

</details>

## Knowledge check

### 1. What is the main value of dependency injection?

A. It requires every type to become a protocol

B. It makes dependencies explicit and replaceable

C. It guarantees no bugs

D. It removes the need for initializers

<details>
<summary>Answer and explanation</summary>

**B. It makes dependencies explicit and replaceable**

Injection reveals a type's requirements and lets a composition root or test supply suitable implementations.

</details>

### 2. Which operation best belongs in an API client?

A. Choosing a label's font

B. Building and validating an HTTP request

C. Pushing a detail controller

D. Deciding row spacing

<details>
<summary>Answer and explanation</summary>

**B. Building and validating an HTTP request**

An API client translates between the app and an HTTP contract. Rendering and navigation have different responsibilities.

</details>

### 3. Where should a task's authoritative completion value live?

A. Independently in every cell

B. In a shared domain store or repository with an explicit policy

C. Only in a navigation controller

D. In a screenshot of the row

<details>
<summary>Answer and explanation</summary>

**B. In a shared domain store or repository with an explicit policy**

Screens may render snapshots, but mutations need an authoritative owner so the inbox, board, and detail screen do not diverge.

</details>

### 4. Does moving all controller code into a view model automatically produce good MVVM?

A. Yes, class naming is the entire architecture

B. No, responsibilities and dependency direction still matter

C. Yes, if the file is longer

D. Only if it imports every framework

<details>
<summary>Answer and explanation</summary>

**B. No, responsibilities and dependency direction still matter**

A large view model can still mix networking, persistence, presentation, and routing. Separation should follow responsibilities rather than labels.

</details>

### 5. Who should usually choose concrete repository implementations?

A. Every reusable cell

B. The composition root near app or scene setup

C. The JSON decoder

D. A hidden global lookup in every method

<details>
<summary>Answer and explanation</summary>

**B. The composition root near app or scene setup**

A composition root assembles the dependency graph once and makes environment choices visible and reviewable.

</details>

## Common pitfalls

- Moving a massive controller unchanged into a massive view model.
- Keeping multiple independently writable copies of domain state.
- Using global singletons to conceal dependencies.
- Adding protocols and forwarding layers without a real change or test boundary.
- Letting a coordinator be released immediately after start.
- Creating strong cycles through coordinator-owned screens and callbacks.

## PocketTasks milestone: PocketTasks milestone: a maintainable feature boundary

1. Keep the inbox controller focused on UIKit construction, binding, and rendering.
2. Inject a task repository into the view model and provide memory and remote implementations.
3. Choose one task-data authority for inbox, board, and details.
4. Write a short dependency diagram and explain whether a coordinator is needed for your current flow.

## Before you move on

- Draw the dependency direction from UIKit to view model to repository.
- Replace the real repository with a deterministic fake.
- Explain who owns task data versus screen filter state.
- Show where request handles are owned and cancelled.
- Justify each architectural layer by a concrete responsibility or likely change.

## Official references

- [Swift protocols](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/protocols/)
- [UIViewController](https://developer.apple.com/documentation/uikit/uiviewcontroller)
- [UINavigationController](https://developer.apple.com/documentation/uikit/uinavigationcontroller)
- [Swift automatic reference counting](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/automaticreferencecounting/)

## Reflection

- What can I now explain without the example?
- What did I build and test in Xcode?
- Which bug or design tradeoff do I want to revisit?
