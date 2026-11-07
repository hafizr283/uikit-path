# Day 17: Debugging, performance & reliability

Turn symptoms into evidence, then verify the fix.

**Time:** 3–4 hours · **Target:** Swift 6 / iOS 17+

[Interactive lesson](http://hafizr283.me/uikit-path/#/day/17/lesson) · [Course overview](../README.md)

## Outcomes

- Reproduce a defect and inspect the relevant stack, state, and ownership.
- Use breakpoints, LLDB, View Debugger, and Memory Graph deliberately.
- Profile CPU, allocations, leaks, and main-thread stalls on representative workloads.
- Distinguish a correctness fix from an unmeasured performance guess.

## Before you begin

- Day 2: ARC, capture lists, and retain cycles.
- Day 4: Auto Layout constraints and priorities.
- Day 10: MainActor and asynchronous work.
- Day 16: regression tests and deterministic fixtures.

## 1. Make a reproducible debugging story

Start with a concrete report: expected behavior, observed behavior, exact steps, build, device, OS, and relevant fixture data. 'Sometimes slow' is difficult to investigate; 'opening the 2,000-task list after a cold launch freezes scrolling for one second' gives you a workload. Reduce the steps while preserving the failure, and write down what you know separately from your theory.

Read the first useful error and the complete stack rather than changing code until the symptom disappears. A crash at an array access may originate in a stale response that replaced the backing data earlier. Symbolicated stacks connect addresses to your source; preserve the matching archive and dSYM files for release investigations. A successful fix should explain the cause, prevent the defect, and survive the original reproduction steps.

## 2. Ask focused questions with debugger tools

Use a breakpoint where a wrong value first becomes observable. In LLDB, po inspects an object's description, p evaluates an expression, and bt shows the current thread's backtrace. Be careful: expressions can execute code and descriptions can contain sensitive data. Prefer narrow inspection over dumping an entire authenticated request. Conditional breakpoints and breakpoint actions help isolate one item without repeatedly stopping for every cell.

Enable an exception breakpoint when diagnosing Objective-C exceptions such as invalid UIKit operations. Swift runtime traps and thrown Swift errors are different events; use the appropriate runtime or Swift error breakpoint as needed. The View Debugger reveals hidden, misplaced, clipped, and unexpectedly overlapping views. For an Auto Layout warning, identify the conflicting constraints and missing relationship instead of randomly lowering priorities until the log becomes quiet.

## 3. Follow ownership with Memory Graph

If a controller remains alive after you pop it, inspect the object graph. Look for an ownership path from a long-lived object or a cycle within the supposedly released group. Common paths include stored closures, timers, observers, delegates that should be weak, and tasks that remain active. A closure capture list is a decision about ownership, not a decoration to paste onto every closure.

The example below has a controller-owned callback that captures the controller weakly. Removing weak creates controller → callback → controller. The button's UIAction is another retained closure and needs the same ownership consideration. Memory Graph helps explain who retains the controller; Instruments Allocations helps determine whether repeated navigation makes memory grow. A high memory reading alone is not proof of a leak because caches and allocator behavior also retain memory intentionally.

## 4. Measure main-thread work and scrolling

UIKit rendering belongs on the main thread, but that does not mean JSON parsing, large sorts, database scans, and image decompression belong there. Use Time Profiler to identify expensive stacks, then use Instruments' responsiveness tools to investigate hangs. An async function does not inherently move CPU-heavy work off MainActor. A task created from an actor-isolated context can inherit that actor's isolation.

For list performance, inspect repeated work: formatting the same date for every layout pass, decoding full-resolution photos for tiny cells, rebuilding all models after one change, or doing synchronous disk access during cell configuration. Cache with an explicit identity, bound memory usage, downsample images to the display need, and cancel obsolete work. First establish that your data and reuse behavior are correct; a fast cell that shows another task's image is still defective.

## 5. Verify improvements under realistic conditions

Debug builds and the debugger change timing, so measure performance using an appropriate optimized build and representative device when possible. The simulator is valuable for iteration but does not reproduce every device constraint. Repeat the same workload and compare distributions rather than celebrating one unusually fast run. Keep correctness checks alongside a performance change so an optimization cannot silently alter ordering or drop data.

Use structured logging with a subsystem and category, and mark private values appropriately. Do not collect tokens, passwords, complete user documents, or unnecessary personal content. For production crashes, connect the issue to a release, symbolize it, reproduce if possible, and track the fix. Document what you measured, what changed, and which conditions remain untested. 'No longer crashes in my one attempt' is a weaker conclusion than a regression test plus the original device reproduction.

## Worked example: Inspect a controller's lifetime

**File:** LifetimeViewController.swift

```swift
import UIKit

@MainActor
final class LifetimeViewController: UIViewController {
    private let statusLabel = UILabel()
    private var refresh: (() -> Void)?
    private var refreshCount = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Lifetime lab"
        view.backgroundColor = .systemBackground

        statusLabel.text = "Refresh count: 0"
        statusLabel.font = .preferredFont(forTextStyle: .body)
        statusLabel.adjustsFontForContentSizeCategory = true

        refresh = { [weak self] in
            guard let self else { return }
            self.refreshCount += 1
            self.statusLabel.text =
                "Refresh count: \(self.refreshCount)"
        }

        var configuration = UIButton.Configuration.filled()
        configuration.title = "Refresh"
        let button = UIButton(configuration: configuration)
        button.addAction(UIAction { [weak self] _ in
            self?.refresh?()
        }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [
            statusLabel, button
        ])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: 24
            ),
            stack.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -24
            ),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    deinit {
        print("LifetimeViewController released")
    }
}
```

### Walkthrough and setup

1. Add this file to the iOS app target. From an existing controller inside a UINavigationController, push LifetimeViewController(). It needs no storyboard.
2. Tap Refresh and confirm that the visible count increases. Pop the controller and look for the deinit message, which contains no user data.
3. Place a breakpoint in viewDidLoad and inspect the view hierarchy after layout using Xcode's View Debugger.
4. For a deliberate local leak experiment, temporarily make the refresh closure capture self strongly. Push and pop again, then find the retained controller and closure in Memory Graph. Revert the change after observing it.
5. The weak capture breaks this particular cycle. A missing deinit message alone does not identify a cause; transitions, navigation stacks, caches, or other owners may still legitimately retain a controller.

**Expected behavior:** The count increases when tapped. Once the controller is popped and its transition completes, it is released if no other owner retains it.

## Challenge 1: Replace an unsafe index assumption

**Level:** Warm-up

A detail screen crashes when a saved index becomes invalid after a refreshed list shrinks. Write a safe accessor and explain why production navigation should prefer a stable task identifier.

### Requirements

- Handle negative and out-of-range indices.
- Return an optional instead of substituting an unrelated item.
- Test empty and nonempty arrays.

### Starter

```swift
func element<T>(at index: Int, in values: [T]) -> T? {
    // Validate membership in the array's valid indices.
    nil
}
```

<details>
<summary>Hints</summary>

- An Array's indices range supports contains(_:).
- Do not use values.count - 1 when the array can be empty.

</details>

### Acceptance checks

- Negative, empty, and past-the-end accesses return nil.
- A valid index returns its element.
- Explain a case where a valid old index selects the wrong task.

<details>
<summary>Worked solution</summary>

```swift
func element<T>(at index: Int, in values: [T]) -> T? {
    guard values.indices.contains(index) else { return nil }
    return values[index]
}

// Expected results:
// element(at: -1, in: [10, 20]) == nil
// element(at: 1, in: [10, 20]) == 20
// element(at: 2, in: [10, 20]) == nil
// element(at: 0, in: [Int]()) == nil
```

Bounds validation stops the trap, but an index can remain valid while pointing to a different item after sorting or deletion. Store and look up a stable task ID when preserving navigation across list changes.

</details>

## Challenge 2: Prove that a stored callback does not leak

**Level:** Core

A tiny editor owns an onSave closure that reads its title. Fix its ownership and add a test that the editor becomes nil after its last external strong reference is removed.

### Requirements

- Use a weak reference for the test observation.
- Retain the callback on the editor to model the ownership risk.
- Avoid involving UIKit so the ownership rule is clear.

### Starter

```swift
final class Editor {
    var title = "Draft"
    var onSave: (() -> String)?
    init() {
        onSave = { self.title }
    }
}
```

<details>
<summary>Hints</summary>

- The cycle is Editor → closure → Editor.
- Capture self weakly and decide what the callback returns if the editor is gone.

</details>

### Acceptance checks

- The weak observation becomes nil.
- Reintroducing a strong capture makes the test fail.
- You can draw the retaining edges before and after the fix.

<details>
<summary>Worked solution</summary>

```swift
import XCTest

private final class Editor {
    var title = "Draft"
    var onSave: (() -> String)?

    init() {
        onSave = { [weak self] in
            self?.title ?? ""
        }
    }
}

final class EditorLifetimeTests: XCTestCase {
    func testEditorIsReleased() {
        var editor: Editor? = Editor()
        weak var observed = editor
        XCTAssertEqual(editor?.onSave?(), "Draft")
        editor = nil
        XCTAssertNil(observed)
    }
}
```

The test watches the object without owning it. Returning an empty string is only this fixture's fallback; a real callback may be better modeled as an optional result or a no-op. Unowned would require a stronger lifetime guarantee than this stored callback provides.

</details>

## Challenge 3: Remove repeated membership scans without changing behavior

**Level:** Stretch

A list filters 20,000 tasks by thousands of selected IDs. Its implementation calls selectedIDs.contains inside every filter iteration. Replace repeated linear scans, preserve source order, and benchmark a fixed fixture.

### Requirements

- Return exactly the same items in the same order.
- Build the membership structure once per operation.
- Use XCTest measure for a repeatable local comparison; do not assert a universal millisecond limit.

### Starter

```swift
struct Item: Equatable {
    let id: Int
}
func selectedItems(_ items: [Item], ids: [Int]) -> [Item] {
    items.filter { ids.contains($0.id) }
}
```

<details>
<summary>Hints</summary>

- A Set provides average constant-time membership checks.
- Filtering the original array preserves its order; iterating the Set does not.

</details>

### Acceptance checks

- Duplicate selected IDs do not duplicate output items.
- Output preserves the source array's order.
- Record the workload, build configuration, and measured before/after values.

<details>
<summary>Worked solution</summary>

```swift
import XCTest

private struct Item: Equatable {
    let id: Int
}

private func selectedItems(
    _ items: [Item], ids: [Int]
) -> [Item] {
    let membership = Set(ids)
    return items.filter { membership.contains($0.id) }
}

final class SelectionPerformanceTests: XCTestCase {
    func testPreservesSourceOrderAndMembership() {
        let items = [Item(id: 3), Item(id: 1), Item(id: 2)]
        XCTAssertEqual(
            selectedItems(items, ids: [2, 3, 3]),
            [Item(id: 3), Item(id: 2)]
        )
    }

    func testSelectionPerformance() {
        let items = (0..<20_000).map { Item(id: $0) }
        let ids = Array(stride(from: 0, to: 20_000, by: 2))
        measure {
            let result = selectedItems(items, ids: ids)
            XCTAssertEqual(result.count, 10_000)
        }
    }
}
```

The original work is roughly proportional to items multiplied by selected IDs. Building a Set then filtering is roughly proportional to their sum on average, with extra memory for the Set. Measure both versions under the same optimized configuration and workload rather than promising a device-independent speedup.

</details>

## Knowledge check

### 1. A controller remains alive after being popped. Which tool best reveals retaining relationships?

A. Asset Catalog

B. Memory Graph

C. App Store Connect pricing

D. Localization export

<details>
<summary>Answer and explanation</summary>

**B. Memory Graph**

Memory Graph shows object references and helps locate ownership paths or cycles.

</details>

### 2. Does making a function async guarantee its CPU-heavy work runs off MainActor?

A. Yes, always

B. Only on Wi-Fi

C. No; isolation and execution context still matter

D. Only if the function returns Void

<details>
<summary>Answer and explanation</summary>

**C. No; isolation and execution context still matter**

Async permits suspension. It is not a guarantee that synchronous work inside the function runs away from the UI actor.

</details>

### 3. What makes a performance comparison credible?

A. Different workloads on different devices

B. One fast debug run

C. Matching workloads and build conditions with repeated measurements

D. Removing assertions until timing improves

<details>
<summary>Answer and explanation</summary>

**C. Matching workloads and build conditions with repeated measurements**

Control the conditions and retain correctness checks so the result is meaningful.

</details>

### 4. Why can a valid saved array index still be wrong after refresh?

A. Swift arrays cannot change

B. The same index may now refer to a different item

C. Only negative indices work after refresh

D. Auto Layout changes array order

<details>
<summary>Answer and explanation</summary>

**B. The same index may now refer to a different item**

Indices represent positions. Stable model IDs represent identity across insertions, deletions, and sorting.

</details>

### 5. Which log entry is most appropriate for a failed authenticated request?

A. The full bearer token

B. The user's password

C. A safe operation name, status code, and correlation identifier

D. The entire private document body

<details>
<summary>Answer and explanation</summary>

**C. A safe operation name, status code, and correlation identifier**

Record the minimum operational evidence needed to investigate without leaking credentials or unnecessary personal data.

</details>

## Common pitfalls

- An arbitrary weak capture may hide a missing owner rather than fix the intended lifetime.
- A high memory footprint is not automatically a leak.
- Profiling only in Debug can misrepresent release performance.
- Moving UI mutations to a background queue creates new correctness defects.
- A crash fix that merely suppresses the error can silently show wrong data.

## PocketTasks milestone: Audit PocketTasks under a larger workload

1. Load a fixture of at least 2,000 tasks and repeat scrolling, opening details, and returning.
2. Verify that popped controllers are released and images do not grow memory without a bound.
3. Profile the slowest observed interaction and change only the measured bottleneck.
4. Keep a regression test and record the comparison conditions in a performance note.

## Before you move on

- Capture reproducible steps and a useful stack for one deliberate defect.
- Find a retained controller and identify the actual ownership path.
- Use View Debugger to explain a layout issue.
- Measure one optimization while preserving a correctness test.
- Write a short before/after investigation note with remaining limits.

## Official references

- [Apple: Diagnosing memory, thread, and crash issues early](https://developer.apple.com/documentation/xcode/diagnosing-memory-thread-and-crash-issues-early)
- [Apple: Improving your app's performance](https://developer.apple.com/documentation/xcode/improving-your-app-s-performance)
- [Apple: Logging](https://developer.apple.com/documentation/os/logging)

## Reflection

- What can I now explain without the example?
- What did I build and test in Xcode?
- Which bug or design tradeoff do I want to revisit?
