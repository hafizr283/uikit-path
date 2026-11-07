# Day 01: Swift that holds up in a real app

Model data, make invalid states explicit, and choose useful boundaries.

**Time:** 3–4 hours · **Target:** Swift 6 / iOS 17+

[Interactive lesson](http://hafizr283.me/uikit-path/#/day/1/lesson) · [Course overview](../README.md)

## Outcomes

- Choose value or reference semantics based on ownership and identity.
- Model optional data and mutually exclusive screen states safely.
- Use closures, protocols, generics, and access control to keep code understandable.
- Build PocketTasks models with validation and stable identity.

## Before you begin

- Basic Swift variables, functions, loops, and types.
- Xcode on a Mac for native work; today's Foundation example can also run in a compatible Swift environment.

## Value and reference semantics

A struct is a value: assignment creates an independent logical value. A class is a reference: two variables can refer to the same instance, so mutations through one reference are visible through the other. Use structs for task data, filters, and API responses. Use classes when shared identity or a lifecycle matters, such as view controllers and services owning an ongoing connection.

Copy-on-write optimizes storage for standard collections without changing their value semantics. A struct containing a class instance can nevertheless share that referenced object. Also, let prevents replacing a class reference but does not freeze its mutable properties. When editing a task, a draft value makes the save boundary explicit; sharing one mutable object requires you to coordinate immediate changes between screens.

## Types should explain absence and alternatives

An optional means something can be absent, but you must define why. A nil due date may mean no deadline; a missing server identifier may mean the response is invalid. Use if let for conditional work and guard let when the rest of the operation requires the value. Replacing every missing value with an empty string can hide a broken contract.

An enum with associated values represents alternatives that cannot coexist: idle, loading, loaded([TaskItem]), or failed(String). Independent flags can accidentally claim that the screen is loading and failed simultaneously. Name your model TaskItem instead of Task so it does not compete with Swift's concurrency type. Prefer distinct validation errors over a Boolean when the UI must explain the failure.

## Closures carry behavior and capture context

A closure is behavior that can be passed to another function, stored, and called later. A sorting predicate is usually consumed immediately; a completion handler may outlive the function that receives it. Mark a closure parameter @escaping when the function stores it or passes it to escaping work. This says nothing about which thread executes it.

Closures capture surrounding values and references. That makes button callbacks convenient but also creates ownership relationships, which Day 2 explores. map transforms elements, filter selects them, and compactMap transforms while discarding nil results. Use these operations to clarify intent. If shorthand parameters make a multi-step expression difficult to read, name the parameters or write a normal loop.

## Protocols and generics make dependencies explicit

A protocol describes capabilities. A TaskReading dependency can provide tasks without exposing whether they came from a file, API, or fixture array. Supplying that dependency from outside is dependency injection. A consumer can then be tested with a controlled implementation instead of reaching into shared global state.

Generics preserve type relationships: a function receiving [T] can return T? without converting the element to Any and casting it back. An existential such as any TaskReading stores any conforming value; a generic parameter T: TaskReading preserves its specific type. Both have uses. Do not create a protocol for every type automatically; introduce one when a real boundary or alternative implementation benefits from it.

## Protect model invariants

An invariant is something that must remain true, such as a task title containing meaningful text. Validate at creation and mutation boundaries instead of asking every screen to remember the rule. private(set) permits public reading but limits writes to the declaring type, where a method such as rename(to:) can enforce the invariant.

Use throws when the caller needs to distinguish reasons for failure. A failable initializer returning nil can be appropriate when the reason is irrelevant. Keep models independent of UILabel and UIAlertController: models describe data and failures, while UIKit presents them. Access control, useful errors, and small explicit types prevent more bugs than adding layers before the app needs them.

## Worked example: Validated tasks with an interchangeable reader

**File:** Day01Models.swift

```swift
import Foundation

enum TaskValidationError: Error { case emptyTitle }
enum Priority: String, Codable { case low, normal, high }

struct TaskItem: Identifiable, Equatable {
    let id: UUID
    private(set) var title: String
    var priority: Priority
    private(set) var isComplete: Bool

    init(id: UUID = UUID(), title: String,
         priority: Priority = .normal) throws {
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { throw TaskValidationError.emptyTitle }
        self.id = id
        self.title = clean
        self.priority = priority
        self.isComplete = false
    }

    mutating func rename(to proposedTitle: String) throws {
        let clean = proposedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { throw TaskValidationError.emptyTitle }
        title = clean
    }

    mutating func toggleCompletion() { isComplete.toggle() }
}

protocol TaskReading { func allTasks() -> [TaskItem] }

struct MemoryTaskReader: TaskReading {
    let items: [TaskItem]
    func allTasks() -> [TaskItem] { items }
}

func pendingTitles(from reader: any TaskReading) -> [String] {
    reader.allTasks().filter { !$0.isComplete }.map { $0.title }
}

func firstMatch<T>(in values: [T], matching predicate: (T) -> Bool) -> T? {
    values.first(where: predicate)
}

func runDay01Example() {
    do {
        let original = try TaskItem(title: "  Learn Auto Layout  ")
        var draft = original
        try draft.rename(to: "Practice constraints")
        draft.toggleCompletion()
        let reader = MemoryTaskReader(items: [original, draft])
        print(original.title)
        print(draft.title, draft.isComplete)
        print(pendingTitles(from: reader))
    } catch {
        print("Validation failed:", error)
    }
}
```

### Walkthrough and setup

1. Paste the whole example into a Swift playground and add runDay01Example() at the bottom. In an app source file, keep the function declaration and call it from temporary debug code rather than adding a top-level expression.
2. The initializer trims input and either produces a valid model or throws. Outside callers cannot directly assign title or isComplete.
3. Assigning original to draft creates an independent value but preserves its id: this is an edited draft of the same logical task, not a newly created task.
4. pendingTitles only needs TaskReading. Replace the in-memory reader with a real service later without changing the consumer.
5. firstMatch is an additional generic helper. It preserves the concrete array element type and communicates absence with an optional.

**Expected behavior:** Learn Auto Layout
Practice constraints true
["Learn Auto Layout"]

## Challenge 1: Find the urgent unfinished task

**Level:** Warm-up

Using the example models, return the first high-priority task that is unfinished. Do not invent a placeholder when there is no match.

### Requirements

- Preserve array order.
- Do not force unwrap or mutate input.
- Return an optional.

### Starter

```swift
func firstUrgent(in tasks: [TaskItem]) -> TaskItem? {
    // Implement
}
```

<details>
<summary>Hints</summary>

- Combine conditions with &&.
- Use first(where:).

</details>

### Acceptance checks

- An empty array returns nil.
- Completed urgent tasks are skipped.
- Two matches return the earlier one.

<details>
<summary>Worked solution</summary>

```swift
func firstUrgent(in tasks: [TaskItem]) -> TaskItem? {
    tasks.first { $0.priority == .high && !$0.isComplete }
}
```

first(where:) communicates that you want one existing element. The optional lets the caller display a useful empty state rather than accidentally treating fabricated data as real.

</details>

## Challenge 2: Create a validated title value

**Level:** Core

Create an independent ValidatedTitle that trims input and rejects blank input or more than 80 Swift Characters. Return distinct errors so the form can give precise feedback.

### Requirements

- Use a throwing initializer.
- Expose a read-only value.
- Measure the cleaned string and keep UIKit out of the type.

### Starter

```swift
import Foundation
struct ValidatedTitle {
    let value: String
    init(_ raw: String) throws {
        // Validate
    }
}
```

<details>
<summary>Hints</summary>

- String.count counts extended grapheme clusters.
- Use an error enum with separate cases.

</details>

### Acceptance checks

- Whitespace-only input throws blank.
- 80 characters succeed and 81 throw tooLong.
- Successful values have surrounding whitespace removed.

<details>
<summary>Worked solution</summary>

```swift
import Foundation

enum TitleError: Error {
    case blank
    case tooLong(maximum: Int)
}

struct ValidatedTitle {
    let value: String

    init(_ raw: String) throws {
        let clean = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { throw TitleError.blank }
        guard clean.count <= 80 else { throw TitleError.tooLong(maximum: 80) }
        value = clean
    }
}
```

Every successfully created instance satisfies the same rule. A production client and server must agree on length measurement: a backend may count bytes rather than user-perceived characters.

</details>

## Challenge 3: Replace conflicting state flags

**Level:** Stretch

Represent a task-list screen with an enum and write a status message function. Include ready, loading, loaded tasks, and failure.

### Requirements

- Use associated values.
- Distinguish empty success from failure.
- Use an exhaustive switch without default.

### Starter

```swift
enum TaskListState {
    // Cases
}
func statusMessage(for state: TaskListState) -> String {
    // Switch
}
```

<details>
<summary>Hints</summary>

- An empty array is a valid loaded result.
- Bind associated values with let.

</details>

### Acceptance checks

- loaded([]) displays an empty message.
- loading carries no stale failure text.
- A new enum case requires updating the switch.

<details>
<summary>Worked solution</summary>

```swift
enum TaskListState {
    case idle
    case loading
    case loaded([TaskItem])
    case failed(String)
}

func statusMessage(for state: TaskListState) -> String {
    switch state {
    case .idle: return "Ready to load"
    case .loading: return "Loading tasks…"
    case .loaded(let tasks):
        return tasks.isEmpty ? "No tasks yet" : "\(tasks.count) tasks"
    case .failed(let message): return "Could not load: \(message)"
    }
}
```

The state cannot be loading and failed at once. Adding a new enum case makes the compiler identify consumers that need updating. Localize presentation strings when the app reaches production UI work.

</details>

## Knowledge check

### 1. What does assigning a struct containing only value-type fields produce?

A. A shared mutable object.

B. An independent logical value.

C. An invalid original variable.

D. An automatic class conversion.

<details>
<summary>Answer and explanation</summary>

**B. An independent logical value.**

Structs have value semantics, regardless of copy-on-write storage optimizations.

</details>

### 2. Which design is a good use of associated-value enums?

A. A screen that is loading, loaded with tasks, or failed with an error.

B. Three unrelated counters.

C. A mutable global singleton.

D. Replacing all nil values with empty text.

<details>
<summary>Answer and explanation</summary>

**A. A screen that is loading, loaded with tasks, or failed with an error.**

Mutually exclusive alternatives with different associated data are naturally expressed by an enum.

</details>

### 3. What does @escaping describe?

A. Background execution.

B. A guaranteed delayed invocation.

C. A closure that may outlive the receiving function call.

D. Automatic weak capture.

<details>
<summary>Answer and explanation</summary>

**C. A closure that may outlive the receiving function call.**

Escaping describes lifetime. Scheduling and ownership are independent concerns.

</details>

### 4. Why use private(set) for a validated title?

A. It freezes the property everywhere.

B. It permits reading while funneling writes through controlled operations.

C. It persists the value.

D. It validates every string automatically.

<details>
<summary>Answer and explanation</summary>

**B. It permits reading while funneling writes through controlled operations.**

The declaring type can mutate the value while protecting its invariants from external writes.

</details>

### 5. What does returning T? preserve compared with Any?

A. The original element-type relationship.

B. A guarantee that nil is impossible.

C. Thread safety.

D. JSON decoding.

<details>
<summary>Answer and explanation</summary>

**A. The original element-type relationship.**

Generics preserve static type information so callers do not need casts.

</details>

## Common pitfalls

- Force unwrapping user input turns recoverable absence into a crash.
- A let class reference does not freeze the instance's properties.
- Unrestricted property writes can bypass model validation.
- Speculative protocols can make a tiny feature harder to understand.
- Synthesized Decodable can bypass a custom validating initializer; revisit this before decoding network models.

## PocketTasks milestone: Define PocketTasks' domain

1. Create a Models folder with TaskItem, Priority, and validation errors.
2. Write down the meaning of an optional due date before adding it.
3. Create fixture tasks and an unfinished-task filter.
4. Keep the domain independent of UIKit and document the title-length rule.

## Before you move on

- Explain struct and class assignment using an editing example.
- Create and rename a task without force unwrapping.
- Supply a protocol consumer with an in-memory dependency.
- Describe all legal task-list states.
- Predict the example's output before running it.

## Official references

- [Swift — Structures and Classes](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/classesandstructures/)
- [Swift — Closures](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/closures/)
- [Swift — Protocols](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/protocols/)
- [Swift — Error Handling](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/errorhandling/)

## Reflection

- What can I now explain without the example?
- What did I build and test in Xcode?
- Which bug or design tradeoff do I want to revisit?
