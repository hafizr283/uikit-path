# Day 08: Table views that stay correct

Build a task list with stable identity, reusable cells, and predictable updates.

**Time:** 3–4 hours · **Target:** Swift 6 / iOS 17+

[Interactive lesson](http://hafizr283.me/uikit-path/#/day/8/lesson) · [Course overview](../README.md)

## Outcomes

- Explain the separate responsibilities of a table view, its data source, and its delegate.
- Build self-sizing cells whose content is fully reset on every configuration.
- Apply diffable snapshots using stable model identifiers.
- Implement selection, refresh, deletion, and empty states without desynchronizing the model.

## Before you begin

- Days 3–7: UIKit lifecycle, Auto Layout, navigation, and reusable views.
- Swift structs, UUID, dictionaries, and closures.

## 1. A table is a viewport over your model

UITableView is useful when people need to scan a vertical sequence: inbox messages, settings, search results, or PocketTasks items. The table creates only the cells needed for the visible region, with a small reuse buffer. Your model therefore cannot live in cells. Scrolling a row offscreen may recycle its cell for an entirely different task.

A data source answers which sections and rows exist and how each row should look. A delegate handles interactions and presentation decisions such as selection, swipe actions, and row sizing. With a diffable data source, you still use a delegate. Do not also implement the classic numberOfRowsInSection and cellForRowAt methods as a second competing source of truth.

## 2. Identity is different from position and content

An index path is the current location of a row, not the identity of a task. Inserting a new task at the top moves every later index path. Give each model a stable UUID and put those identifiers in the snapshot. Keep the actual models in a dictionary or repository keyed by UUID. Resolve the selected identifier through the data source when a user taps a row.

The snapshot describes ordered section and item identifiers at one moment. Applying it lets UIKit calculate insertions, moves, and removals. Changing a title in your dictionary does not automatically update an existing cell because the identifier has not changed. Use snapshot.reconfigureItems for content changes to existing identifiers. Create a new snapshot for membership or ordering changes.

## 3. Reuse requires complete configuration

Every cell configuration must set every visible state that varies: title, subtitle, image, accessory, color, and loading placeholder. A common bug sets a checkmark only when a task is complete; an incomplete task then inherits the checkmark from the previous occupant of the cell. Assign both branches explicitly. UIListContentConfiguration is a convenient starting point for standard cells.

Custom cells should create their subviews once in init and constrain them to contentView. Make a complete vertical constraint chain from the content view's top to bottom. Set a multiline label's numberOfLines to zero, use automaticDimension, and supply a reasonable estimatedRowHeight. prepareForReuse is useful for cancelling work and resetting transient state; it does not replace correct model configuration.

## 4. Mutation should flow through the model

For a swipe-to-delete action, resolve the item's current identifier, remove that identifier from your model, and then apply a snapshot representing the new model. Do not merely remove a row visually while leaving the record in storage: it will reappear on the next refresh. If deletion is remote, decide whether to wait for success or perform an optimistic deletion with a visible recovery path.

Selection should also resolve an identifier before navigating to details. Refresh controls should finish in both success and failure paths. An empty list deserves an explanatory background view and a useful action, while a failed request deserves a retry state. Those are distinct meanings even though both may currently display zero rows.

## 5. Keep scrolling work small and observable

Cell configuration runs frequently on the main actor. It should apply already-prepared presentation values, not perform networking, synchronously decode large images, or calculate expensive attributed strings. Prefetching can start upcoming work, but it is a performance hint rather than a guarantee. A row must still behave correctly when it appears without a prefetch callback.

When diagnosing a list bug, first inspect model identity and snapshot contents. Duplicate identifiers are invalid. For disappearing accessories, inspect complete configuration. For height problems, inspect constraints inside contentView. For stutter, profile on a device using Time Profiler rather than assuming the number of Swift lines determines performance.

## Worked example: A complete diffable task list

**File:** TasksViewController.swift

```swift
import UIKit

struct TaskItem: Identifiable {
    let id: UUID
    var title: String
    var isDone: Bool
}

@MainActor
final class TasksViewController: UITableViewController {
    private enum Section: Hashable { case main }
    private var order: [UUID] = []
    private var tasks: [UUID: TaskItem] = [:]
    private var source: UITableViewDiffableDataSource<Section, UUID>!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "PocketTasks"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "task")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 64

        source = UITableViewDiffableDataSource(
            tableView: tableView
        ) { [weak self] table, indexPath, id in
            guard let task = self?.tasks[id] else { return nil }
            let cell = table.dequeueReusableCell(
                withIdentifier: "task", for: indexPath
            )
            var content = cell.defaultContentConfiguration()
            content.text = task.title
            content.textProperties.numberOfLines = 0
            content.secondaryText = task.isDone ? "Completed" : "To do"
            cell.contentConfiguration = content
            cell.accessoryType = task.isDone ? .checkmark : .none
            return cell
        }

        let examples = [
            TaskItem(id: UUID(), title: "Build a reusable task row", isDone: false),
            TaskItem(id: UUID(), title: "Read the table view documentation", isDone: true),
            TaskItem(id: UUID(), title: "Test this long task title with a larger text size", isDone: false)
        ]
        order = examples.map(\.id)
        tasks = Dictionary(uniqueKeysWithValues: examples.map { ($0.id, $0) })
        applySnapshot()
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, UUID>()
        snapshot.appendSections([.main])
        snapshot.appendItems(order)
        source.apply(snapshot, animatingDifferences: false)
    }

    override func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let id = source.itemIdentifier(for: indexPath),
              var task = tasks[id] else { return }
        task.isDone.toggle()
        tasks[id] = task
        var snapshot = source.snapshot()
        snapshot.reconfigureItems([id])
        source.apply(snapshot, animatingDifferences: true)
    }
}
```

### Walkthrough and setup

1. In an iOS UIKit app, add this file and make UINavigationController(rootViewController: TasksViewController(style: .insetGrouped)) the window's root controller in your existing scene setup. This is an app view controller, not a command-line Swift script.
2. The order array controls presentation order while the dictionary stores current model values. Each UUID is generated once when its model is created.
3. The cell provider captures the controller weakly because the controller owns the data source, which retains the provider closure.
4. Both accessory branches and both subtitle branches are assigned on every configuration, preventing recycled visual state.
5. Tapping resolves the UUID through the data source, updates the model, and reconfigures that same stable identifier.

**Expected behavior:** Three task rows appear. Long titles wrap and grow the row. Tapping any row toggles its subtitle and checkmark without creating a new task.

## Challenge 1: Repair a reused checkmark

**Level:** Warm-up

A teammate's cell configuration only adds a checkmark for completed tasks. Rewrite it so unfinished tasks can never inherit old content, and explain why scrolling reveals the bug.

### Requirements

- Set the title for both complete and incomplete tasks.
- Always set the accessory type.
- Use the TaskItem model from the example.

### Starter

```swift
func configure(_ cell: UITableViewCell, task: TaskItem) {
    if task.isDone { cell.accessoryType = .checkmark }
}
```

<details>
<summary>Hints</summary>

- The same cell object can represent several different models.
- Each varying property needs a value for every model state.

</details>

### Acceptance checks

- Configure one cell with a completed task, then an incomplete task; the checkmark disappears.
- Repeat in the opposite order and verify both titles and subtitles.

<details>
<summary>Worked solution</summary>

```swift
@MainActor
func configure(_ cell: UITableViewCell, task: TaskItem) {
    var content = cell.defaultContentConfiguration()
    content.text = task.title
    content.secondaryText = task.isDone ? "Completed" : "To do"
    cell.contentConfiguration = content
    cell.accessoryType = task.isDone ? .checkmark : .none
}
```

Reuse preserves object properties. A one-sided conditional leaves the previous task's accessory untouched when the new task is incomplete. Full configuration makes the cell a rendering of the current model rather than a memory of past models.

</details>

## Challenge 2: Add tasks without changing existing identities

**Level:** Core

Extend TasksViewController with an addTask(title:) method. Insert the new task at the top and update the list without rebuilding UUIDs for existing tasks.

### Requirements

- Trim leading and trailing whitespace and reject blank input.
- Create exactly one new identifier.
- Keep existing tasks and their completion state.

### Starter

```swift
// Add inside TasksViewController.
private func addTask(title: String) {
    // Validate, insert, and render.
}
```

<details>
<summary>Hints</summary>

- Use trimmingCharacters(in: .whitespacesAndNewlines).
- Both order and tasks need updates before applying a snapshot.

</details>

### Acceptance checks

- Add two tasks and confirm that they appear newest first.
- Complete an existing task, add another, and verify that completion remains.
- Pass only spaces and verify that the row count does not change.

<details>
<summary>Worked solution</summary>

```swift
private func addTask(title: String) {
    let cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !cleaned.isEmpty else { return }
    let task = TaskItem(id: UUID(), title: cleaned, isDone: false)
    tasks[task.id] = task
    order.insert(task.id, at: 0)
    applySnapshot()
}
```

Stable identifiers allow the diffable data source to recognize existing rows. Recreating every model with a fresh UUID would describe a replacement of the entire list and could lose selection or associated state. Call the method from a button or a temporary line after the initial snapshot.

</details>

## Challenge 3: Delete by identifier and render an empty state

**Level:** Stretch

Add a model-driven delete method and an empty-list message. Call the method from a temporary button or debug action before connecting a trailing swipe action.

### Requirements

- Remove the identifier from both model containers.
- Use a background view for the empty state.
- Do not call deleteRows alongside a diffable snapshot.

### Starter

```swift
// Add inside TasksViewController.
private func deleteTask(id: UUID) { }
private func updateEmptyState() { }
```

<details>
<summary>Hints</summary>

- A background view belongs to the table rather than to a reusable cell.
- Call updateEmptyState after every membership change.

</details>

### Acceptance checks

- Delete the first, middle, and last remaining task without an invalid-update crash.
- After deleting all tasks, verify the message is visible.
- Add a task and verify the message disappears.

<details>
<summary>Worked solution</summary>

```swift
private func deleteTask(id: UUID) {
    tasks.removeValue(forKey: id)
    order.removeAll { $0 == id }
    applySnapshot()
    updateEmptyState()
}

private func updateEmptyState() {
    guard order.isEmpty else {
        tableView.backgroundView = nil
        return
    }
    let label = UILabel()
    label.text = "No tasks yet. Add your first task."
    label.textAlignment = .center
    label.numberOfLines = 0
    label.font = .preferredFont(forTextStyle: .body)
    label.adjustsFontForContentSizeCategory = true
    tableView.backgroundView = label
}
```

One state transition updates the model and asks the snapshot to represent it. Mixing manual row deletion with diffable updates introduces a second, potentially contradictory update mechanism. Also call updateEmptyState after the initial load and addTask so the message always follows the model.

</details>

## Knowledge check

### 1. What is the safest identity to store in a diffable snapshot for editable tasks?

A. The task's current row number

B. A stable UUID created with the task

C. The title, because it is visible

D. A new UUID every time the screen renders

<details>
<summary>Answer and explanation</summary>

**B. A stable UUID created with the task**

Position and title can change. A stable identifier lets UIKit distinguish an existing item's changed content from an insertion or removal.

</details>

### 2. A task title changes, but its UUID stays the same. What should update the visible row?

A. Only change the dictionary and do nothing else

B. Remove the table from its superview

C. Update the model and reconfigure the existing identifier

D. Change every UUID

<details>
<summary>Answer and explanation</summary>

**C. Update the model and reconfigure the existing identifier**

The snapshot's identifiers have not changed. Reconfiguration tells the cell provider to render current content for that existing item.

</details>

### 3. Why should custom cell constraints reference contentView?

A. It makes every cell the same height

B. UITableView ignores subviews outside it

C. It is the intended container and participates in cell layout and self-sizing

D. It prevents networking requests

<details>
<summary>Answer and explanation</summary>

**C. It is the intended container and participates in cell layout and self-sizing**

The content view is UIKit's supported container for a cell's primary custom content. Correct edge-to-edge vertical constraints enable fitting-size calculation.

</details>

### 4. Where should a completed task's persistent state live?

A. Only in the cell's accessoryType

B. In the model or repository

C. Only in prepareForReuse

D. In the current index path

<details>
<summary>Answer and explanation</summary>

**B. In the model or repository**

A cell is a temporary presentation object. Model state must survive scrolling, navigation, reordering, and reconstruction of views.

</details>

### 5. What does prefetching guarantee?

A. Every row is prefetched before display

B. A fixed number of requests

C. Nothing about correctness; it is an opportunity to prepare data early

D. That no cancellation logic is needed

<details>
<summary>Answer and explanation</summary>

**C. Nothing about correctness; it is an opportunity to prepare data early**

Prefetch callbacks are hints. Display logic must still handle missing data, repeated requests, and work that becomes unnecessary.

</details>

## Common pitfalls

- Generating new item IDs whenever you apply a snapshot.
- Capturing the controller strongly in a retained cell-provider closure.
- Configuring only one branch of accessories, colors, or placeholders.
- Combining manual insertRows/deleteRows with a diffable data source.
- Performing synchronous network or image-decoding work during cell configuration.

## PocketTasks milestone: PocketTasks milestone: the task inbox

1. Replace static labels with the diffable task list.
2. Support creating, toggling, and removing tasks through stable identifiers.
3. Add an empty state and document which class owns the task models.
4. Manually test a long list, large text, and repeated add/delete operations.

## Before you move on

- Explain why an index path is not a stable model identifier.
- Toggle and add tasks while preserving old UUIDs.
- Show a long title without clipping at a larger text size.
- Trace one reused cell through two different model configurations.
- Describe how remote deletion would recover if the server rejects it.

## Official references

- [UITableView](https://developer.apple.com/documentation/uikit/uitableview)
- [UITableViewDiffableDataSource](https://developer.apple.com/documentation/uikit/uitableviewdiffabledatasource)
- [NSDiffableDataSourceSnapshot](https://developer.apple.com/documentation/uikit/nsdiffabledatasourcesnapshot)

## Reflection

- What can I now explain without the example?
- What did I build and test in Xcode?
- Which bug or design tradeoff do I want to revisit?
