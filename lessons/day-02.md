# Day 02: ARC, ownership, and memory leaks

Understand who keeps an object alive and make screen lifetimes predictable.

**Time:** 3–4 hours · **Target:** Swift 6 / iOS 17+

[Interactive lesson](http://hafizr283.me/uikit-path/#/day/2/lesson) · [Course overview](../README.md)

## Outcomes

- Draw strong-reference graphs and identify retain cycles.
- Choose strong, weak, or unowned with a lifetime argument.
- Capture self safely in stored closures and delegate relationships.
- Distinguish an ownership leak from work that is still legitimately running.

## Before you begin

- Day 1 value/reference semantics and closures.
- A Swift playground for the main example; Xcode Memory Graph for the optional UIKit inspection.

## ARC answers a precise ownership question

Automatic Reference Counting tracks strong references to class instances. An object can be released when no strong owners remain. Structs and enums are values, although they may contain references to class instances. Draw boxes for objects and arrows for strong references whenever a lifetime feels mysterious; variable names alone do not tell you whether two properties point to the same object.

UIKit has its own expected ownership graph. A navigation controller keeps its stack of child controllers alive, a view controller normally owns its view, and views own their subviews. Removing a screen from the navigation stack removes one owner, but a singleton, closure, timer, or active operation may still retain it. deinit logging is a useful observation tool, but absence of a log is only the start of diagnosis, not proof of a specific retain cycle.

## Strong, weak, and unowned are different promises

A strong reference keeps an instance alive. A weak reference does not, and automatically becomes nil after the referenced object is destroyed; weak stored properties must be mutable optionals. A class-bound protocol declared with AnyObject can be used by a weak delegate property. Weak is appropriate when the referenced object may legitimately disappear before you use it.

An unowned reference also does not keep an object alive but normally assumes the object still exists when accessed. If that lifetime guarantee is wrong, access traps. Do not select unowned merely to avoid optional syntax. UIKit screens can be dismissed, services can complete later, and navigation can change unexpectedly; weak is usually the more robust callback choice unless the ownership relationship proves otherwise.

## A stored closure can complete a cycle

Suppose a screen owns a view model, the view model stores onChange, and onChange captures the screen strongly. The graph is screen → view model → closure → screen. Releasing the external screen reference cannot break that loop. [weak self] breaks the closure's ownership of the screen; after the screen disappears, self is nil and the callback can return safely.

Weak capture is not a universal decoration. A short nonescaping array transformation usually has no long-lived cycle. A closure that must finish an operation may intentionally retain a worker. When you write guard let self inside a weak-capturing closure, that local binding keeps the object alive for the remainder of that invocation. If it spans an await, the lifetime extends across the suspension too; the weak capture does not mean the object can disappear in the middle of that scope.

## Delegates communicate without owning the parent

A child editor can notify its parent with a delegate protocol or callback. Usually the parent owns or presents the child, so the child should not strongly own the parent through its delegate. Declare the protocol class-bound and the delegate weak. The delegate can be nil because there may be no observer, or because the observer has already been released.

Do not confuse delegates with data ownership. A service or repository that the screen needs to function is often a strong dependency. Making every dependency weak causes unexpected nil values and lost work. Ask which object should own which responsibility: the screen strongly owns its model; a feedback callback points weakly back to the screen; the application composition root may own a shared service for the session.

## Stopping work is separate from releasing memory

Timers, notification observers, subscriptions, and unstructured tasks can keep work alive independently of a visible screen. A weak callback can prevent a cycle while the timer still fires forever. Cancellation, invalidation, or observer removal is an explicit lifecycle decision. Tie it to the lifetime that the work serves: a particular appearance, a screen instance, or an application session.

Use Memory Graph to inspect paths retaining a dismissed controller, and use Instruments when you need allocation trends over repeated navigation. Repeat an enter/leave flow several times; a continually growing number of old controllers is stronger evidence than one delayed release. Also inspect caches and image sizes: high memory use can be intentional retained data rather than a retain cycle. A correct fix should explain both the ownership graph and how ongoing work ends.

## Worked example: A callback that does not retain its editor

**File:** Day02Ownership.swift

```swift
import Foundation

final class SaveCallbacks {
    var onSave: (() -> Void)?
}

final class TaskEditor {
    private let callbacks: SaveCallbacks
    private var title = "Review ARC"

    init(callbacks: SaveCallbacks) {
        self.callbacks = callbacks
    }

    func connect() {
        callbacks.onSave = { [weak self] in
            guard let self else {
                print("Editor is gone; ignore the callback")
                return
            }
            print("Saving:", self.title)
        }
    }

    deinit {
        print("TaskEditor released")
    }
}

func runDay02Example() {
    let callbacks = SaveCallbacks()
    var editor: TaskEditor? = TaskEditor(callbacks: callbacks)
    editor?.connect()
    callbacks.onSave?()
    editor = nil
    callbacks.onSave?()
    callbacks.onSave = nil
}
```

### Walkthrough and setup

1. Paste the complete code into a Swift playground and invoke runDay02Example(). It deliberately uses Foundation and ordinary classes so the ownership graph is visible without UIKit setup.
2. The local callbacks variable owns the callback store. While editor is non-nil, the editor also owns that same store.
3. The store owns its closure, but the closure only weakly references the editor. There is no strong path back to the editor.
4. Setting editor to nil removes the editor's final strong owner. Its deinit message appears even though the callback store remains alive.
5. Invoke the stored callback after release: the guard handles nil and does not access a destroyed object. For comparison, temporarily capture self strongly, observe the missing deinit before cleanup, then restore the weak version.

**Expected behavior:** Saving: Review ARC
TaskEditor released
Editor is gone; ignore the callback

## Challenge 1: Explain and repair the cycle

**Level:** Warm-up

A Loader stores a completion closure and a Screen owns its Loader. Repair the callback so the screen can be released while the loader is retained elsewhere.

### Requirements

- Keep the loader as a strong dependency.
- Use a weak capture for the reference back to the screen.
- Do not use unowned or force unwrap.

### Starter

```swift
final class Loader { var completion: (() -> Void)? }
final class Screen {
    let loader: Loader
    init(loader: Loader) { self.loader = loader }
    func start() {
        loader.completion = { self.showResult() }
    }
    func showResult() { print("Ready") }
}
```

<details>
<summary>Hints</summary>

- Draw Screen → Loader → closure → Screen.
- Only the backward edge needs to stop owning the screen.

</details>

### Acceptance checks

- The screen can be released while another variable owns loader.
- Calling completion after release does not crash.
- The dependency does not disappear while the screen needs it.

<details>
<summary>Worked solution</summary>

```swift
final class Loader { var completion: (() -> Void)? }
final class Screen {
    let loader: Loader
    init(loader: Loader) { self.loader = loader }
    func start() {
        loader.completion = { [weak self] in
            self?.showResult()
        }
    }
    func showResult() { print("Ready") }
}
```

The screen still owns a loader it depends on, but the callback no longer owns the screen. This is memory-safe if the callback arrives after dismissal. A real loader may also need cancellation so irrelevant work stops.

</details>

## Challenge 2: Use a weak editor delegate

**Level:** Core

Implement a child editor that reports a saved title to a parent without owning the parent. Keep the example independent of UIKit so you can inspect its lifetime in a playground.

### Requirements

- Use a class-bound protocol.
- Make delegate a weak optional.
- Notify through a method and handle no delegate safely.

### Starter

```swift
protocol TitleEditorDelegate: AnyObject {
    func editorDidSave(title: String)
}
final class TitleEditor {
    // Delegate and save method
}
```

<details>
<summary>Hints</summary>

- weak var delegate: (any TitleEditorDelegate)?
- Optional chaining makes absence a normal case.

</details>

### Acceptance checks

- Saving without a delegate is safe.
- A live parent receives the title.
- Releasing the parent does not leave it retained solely by delegate.

<details>
<summary>Worked solution</summary>

```swift
protocol TitleEditorDelegate: AnyObject {
    func editorDidSave(title: String)
}

final class TitleEditor {
    weak var delegate: (any TitleEditorDelegate)?

    func save(title: String) {
        delegate?.editorDidSave(title: title)
    }
}

final class ParentScreen: TitleEditorDelegate {
    let editor = TitleEditor()

    init() { editor.delegate = self }

    func editorDidSave(title: String) {
        print("Parent received:", title)
    }
}
```

The parent strongly owns the child. The child points back through a weak delegate, so there is no ownership loop. In real UIKit code, mark UI-facing protocols and classes @MainActor so callback isolation is also explicit.

</details>

## Challenge 3: Capture a snapshot instead of a changing reference

**Level:** Stretch

Create a function that returns a closure describing the current task title. The returned closure must preserve the title at creation time even if the source draft is edited afterward.

### Requirements

- Use a class source to make reference semantics visible.
- Capture only the String value needed by the closure.
- Explain why retaining the whole draft is unnecessary.

### Starter

```swift
final class Draft {
    var title: String
    init(title: String) { self.title = title }
}
func makeSummary(for draft: Draft) -> () -> String {
    // Capture the title now
}
```

<details>
<summary>Hints</summary>

- A capture list can bind an expression to a local name.
- String is a value type.

</details>

### Acceptance checks

- The output remains Original after editing the draft.
- The closure has no need to retain Draft.
- A newly created summary reflects the newly edited title.

<details>
<summary>Worked solution</summary>

```swift
final class Draft {
    var title: String
    init(title: String) { self.title = title }
}

func makeSummary(for draft: Draft) -> () -> String {
    { [title = draft.title] in "Draft: \(title)" }
}

func demonstrateSnapshot() {
    let draft = Draft(title: "Original")
    let summary = makeSummary(for: draft)
    draft.title = "Edited"
    print(summary()) // Draft: Original
}
```

The closure captures the title's value at creation time. It does not retain Draft, and later edits do not change the summary. Capturing a value is useful when the behavior explicitly needs a snapshot rather than live state.

</details>

## Knowledge check

### 1. Which graph contains a strong-reference cycle?

A. Screen strongly owns Loader; Loader's callback weakly references Screen.

B. Parent strongly owns Child; Child has a weak parent delegate.

C. Screen strongly owns Loader; Loader strongly owns a closure that strongly captures Screen.

D. Two independent struct values have the same identifier.

<details>
<summary>Answer and explanation</summary>

**C. Screen strongly owns Loader; Loader strongly owns a closure that strongly captures Screen.**

Every edge in that loop owns the next object, so external reference removal cannot make the counts reach zero.

</details>

### 2. What happens to a weak reference after its target is destroyed?

A. It becomes nil.

B. It becomes an unowned reference.

C. It retains a hidden backup object.

D. It must be manually cleared before access.

<details>
<summary>Answer and explanation</summary>

**A. It becomes nil.**

Weak references are automatically zeroed and therefore stored as mutable optionals.

</details>

### 3. When is unowned appropriate?

A. Whenever optional chaining looks verbose.

B. When a valid lifetime guarantee ensures the referenced object exists on every access.

C. For every network callback.

D. When the delegate can disappear independently.

<details>
<summary>Answer and explanation</summary>

**B. When a valid lifetime guarantee ensures the referenced object exists on every access.**

Unowned is a lifetime promise. Accessing an ordinary unowned reference after destruction traps.

</details>

### 4. Does a weak capture automatically cancel a repeating timer?

A. Yes, immediately.

B. Only if the timer runs on the main thread.

C. No; ownership and ongoing work need separate handling.

D. Only for UIViewController.

<details>
<summary>Answer and explanation</summary>

**C. No; ownership and ongoing work need separate handling.**

Weak capture can avoid retaining the observer while the timer continues running. Invalidate or cancel work explicitly.

</details>

### 5. What does guard let self inside a weak-capturing closure do?

A. Permanently makes the original capture strong.

B. Creates a strong local reference for the remaining scope if self is alive.

C. Guarantees deinit before the closure finishes.

D. Makes the closure nonescaping.

<details>
<summary>Answer and explanation</summary>

**B. Creates a strong local reference for the remaining scope if self is alive.**

The local strong binding keeps the object alive for its scope, potentially including suspension points in an async closure.

</details>

## Common pitfalls

- Using weak for every dependency can cause required services to vanish.
- Using unowned for a callback with an uncertain lifetime can crash.
- A weak callback may fix ownership while leaving timers or network work active.
- A closure may retain only part of a graph, so inspect the actual path rather than guessing.
- deinit not printing immediately does not by itself identify which object retains the screen.

## PocketTasks milestone: Define PocketTasks' ownership rules

1. Document which object owns the task repository and which owns each screen.
2. Add a weak callback or delegate contract for saving an edited task.
3. Add temporary deinit logging when implementing the editor controller later.
4. Record when task-list work should stop on navigation; do not rely solely on deinit cleanup.

## Before you move on

- Draw and repair a three-node retain cycle.
- Explain why weak delegates require class-bound protocols.
- Predict the main example's complete output.
- Distinguish a memory leak from intentionally retained cache data.
- Name an explicit cancellation point for screen-specific asynchronous work.

## Official references

- [Swift — Automatic Reference Counting](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/automaticreferencecounting/)
- [Swift — Closures and Capture Lists](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/closures/)
- [Apple — Gathering information about memory use](https://developer.apple.com/documentation/xcode/gathering-information-about-memory-use)
- [Apple — Timer](https://developer.apple.com/documentation/foundation/timer)

## Reflection

- What can I now explain without the example?
- What did I build and test in Xcode?
- Which bug or design tradeoff do I want to revisit?
