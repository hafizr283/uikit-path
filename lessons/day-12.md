# Day 12: Reliable API-powered screens

Handle loading, empty content, refresh, search, pagination, and reused images as explicit state.

**Time:** 3–4 hours · **Target:** Swift 6 / iOS 17+

[Interactive lesson](http://hafizr283.me/uikit-path/#/day/12/lesson) · [Course overview](../README.md)

## Outcomes

- Represent a screen's asynchronous states without contradictory booleans.
- Connect a service to UIKit through one rendering path.
- Protect search and pagination against duplicated or stale work.
- Keep refreshing and loading-more behavior distinct from initial loading.
- Prevent asynchronous images from appearing in the wrong reused cell.

## Before you begin

- Days 8–9: diffable data sources and reuse.
- Days 10–11: cancellation, request identity, URLSession, and typed API results.

## 1. A screen is a state machine

Several booleans such as isLoading, hasError, and isEmpty permit contradictory combinations. A single state enum expresses valid alternatives: idle, loading, loaded items, or failure. Rendering becomes a function of that state rather than a collection of unrelated label mutations scattered across callbacks. The example starts with this small model so you can trace every transition.

Real screens often need richer states. Refresh can retain existing content while showing a small indicator; loading the next page should not replace the entire list with a spinner. A failure after existing content was shown may deserve an inline banner rather than a blank screen. Represent those distinctions explicitly once the product needs them instead of forcing them into a first-load-only enum.

## 2. Keep one path from result to presentation

The service returns models or throws. The screen model accepts only the current request's result and publishes a state. The controller renders that state into its list, message, and controls. Keeping these responsibilities separate makes failure cases testable without displaying a window. It also avoids a success callback updating one label while an older failure callback changes another.

The controller should end refresh indicators on every terminal outcome. A zero-item success is an empty state, not a network failure. An error message should explain a recovery action such as retry, while diagnostic details stay in development logs. Retry should initiate a fresh state transition through the same load method instead of duplicating request code inside an alert action.

## 3. Search has both timing and identity

Debouncing waits briefly after typing stops before starting a request. It reduces load but does not guarantee correct ordering. Cancel the old task and assign each search a generation or request ID; accept a response only if it still matches the current query state. Capture the query value at request creation so later text-field changes cannot silently alter its interpretation.

Decide what an empty query means: all tasks, recent tasks, or no search results. Reset pagination when the search query or filters change because an old cursor belongs to an old result set. Do not append results for query A to a list currently showing query B. Request identity should include the dimensions that determine the dataset, not only a timestamp.

## 4. Pagination needs a guarded transition

A next-page request needs at least the next cursor, a loading-more flag or state, and a rule for whether more results exist. Multiple willDisplay or prefetch callbacks may arrive before the first request finishes. Guard the transition before awaiting so only one request uses the current cursor. Advance the cursor only after accepting the successful response.

Append by stable identifier, preserving order and handling duplicate records according to the API contract. Retrying a failed page should retry the same cursor rather than skipping ahead. Initial refresh or a filter change invalidates any in-flight page. Cursor pagination is often more stable than numeric offsets under server-side insertions, but the server's documented contract determines the client implementation.

## 5. Images are asynchronous model content

A reused image cell must clear its old image immediately and associate the request with the new item's identity or URL. Cancel old work when the cell is reconfigured or reused. Before assigning a completed image, check that the cell still represents the same URL. Cancellation alone cannot prevent every race between completion and reuse.

Cache by a meaningful image key that includes transformations when necessary, and distinguish HTTP response caching from decoded-image caching. Large image decoding and resizing can affect scrolling even when downloading is asynchronous. The exercise focuses on identity correctness; production image pipelines also need bounded caches, prepared thumbnail sizes, request coalescing, memory-pressure handling, and measured performance.

## Worked example: A UIKit screen with explicit load states

**File:** APITasksViewController.swift

```swift
import UIKit

// This file uses TaskAPI, RemoteTask, and APIError from Day 11.
enum TaskListState {
    case idle
    case loading
    case loaded([RemoteTask])
    case failed(String)
}

@MainActor
final class TaskListModel {
    private let api: TaskAPI
    private var request: Task<Void, Never>?
    private var generation = 0
    var onChange: ((TaskListState) -> Void)?
    private(set) var state: TaskListState = .idle {
        didSet { onChange?(state) }
    }

    init(api: TaskAPI) { self.api = api }

    func load() {
        generation += 1
        let current = generation
        request?.cancel()
        state = .loading
        let api = api
        request = Task { [weak self] in
            do {
                let items = try await api.fetchTasks()
                try Task.checkCancellation()
                guard let self, current == self.generation else { return }
                self.state = .loaded(items)
            } catch is CancellationError {
            } catch {
                guard let self, current == self.generation else { return }
                self.state = .failed("Could not load tasks. Tap Reload to try again.")
            }
        }
    }

    func cancel() {
        generation += 1
        request?.cancel()
        request = nil
    }
}

@MainActor
final class APITasksViewController: UITableViewController {
    private let model: TaskListModel
    private var items: [Int: RemoteTask] = [:]
    private var source: UITableViewDiffableDataSource<Int, Int>!

    init(api: TaskAPI) {
        model = TaskListModel(api: api)
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("Create this controller with init(api:).")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Remote tasks"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Reload", style: .plain,
            target: self, action: #selector(reload)
        )
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "task")
        source = UITableViewDiffableDataSource(tableView: tableView) {
            [weak self] table, path, id in
            guard let task = self?.items[id] else { return nil }
            let cell = table.dequeueReusableCell(withIdentifier: "task", for: path)
            var content = cell.defaultContentConfiguration()
            content.text = task.title
            content.textProperties.numberOfLines = 0
            cell.contentConfiguration = content
            cell.accessoryType = task.completed ? .checkmark : .none
            return cell
        }
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(reload), for: .valueChanged)
        model.onChange = { [weak self] state in self?.render(state) }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        model.load()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        model.cancel()
    }

    @objc private func reload() { model.load() }

    private func render(_ state: TaskListState) {
        var rows: [RemoteTask] = []
        let message: String?
        switch state {
        case .idle:
            message = "Ready to load."
        case .loading:
            message = "Loading tasks…"
        case .loaded(let loaded):
            rows = loaded
            message = loaded.isEmpty ? "No tasks yet." : nil
            refreshControl?.endRefreshing()
        case .failed(let text):
            message = text
            refreshControl?.endRefreshing()
        }
        items = Dictionary(rows.map { ($0.id, $0) }, uniquingKeysWith: { _, latest in latest })
        var snapshot = NSDiffableDataSourceSnapshot<Int, Int>()
        snapshot.appendSections([0])
        var seen = Set<Int>()
        snapshot.appendItems(rows.compactMap { seen.insert($0.id).inserted ? $0.id : nil })
        source.apply(snapshot, animatingDifferences: false)

        if let message {
            let label = UILabel()
            label.text = message
            label.numberOfLines = 0
            label.textAlignment = .center
            tableView.backgroundView = label
        } else {
            tableView.backgroundView = nil
        }
    }
}
```

### Walkthrough and setup

1. Include Day 11's TaskAPI.swift. Construct APITasksViewController(api: TaskAPI(baseURL: yourURL)) and place it in a navigation controller so Reload is visible.
2. The model's callback is bound before viewWillAppear starts loading. Reappearing deliberately starts a fresh load; a production screen may use freshness rules instead.
3. The request generation ensures cancelled or superseded requests cannot publish success or failure into a newer screen state.
4. render handles all visual states and deduplicates remote IDs before building the snapshot. Its example policy keeps the latest content for a duplicate ID.
5. This introductory state model clears existing rows during refresh. The Warm-up exercise designs a richer state model that preserves content while refresh is in progress.

**Expected behavior:** The screen shows loading, then task rows or a distinct empty/error message. Pull-to-refresh and Reload follow the same request path. A superseded result cannot replace a newer one.

## Challenge 1: Define valid screen states

**Level:** Warm-up

A screen has independent isLoading, errorText, and rows variables. Replace those with a state that explicitly supports refreshing existing content.

### Requirements

- Represent initial loading separately from refreshing.
- Keep a success with zero rows distinct from failure.
- Preserve previous rows in a recoverable failure if available.

### Starter

```swift
enum InboxState {
    // Model valid presentation alternatives.
}
```

<details>
<summary>Hints</summary>

- Associated values can carry existing rows.
- A separate refreshing case makes its behavior visible to the renderer.

</details>

### Acceptance checks

- Explain how a zero-row content state differs from failed.
- Draw the transitions for initial success, refresh success, and refresh failure.
- Identify which cases show a full-screen loader versus a small refresh indicator.

<details>
<summary>Worked solution</summary>

```swift
enum InboxState {
    case idle
    case loading
    case content([RemoteTask])
    case refreshing([RemoteTask])
    case failed(message: String, previous: [RemoteTask])
}
```

This enum prevents an impossible combination such as initial loading plus a final error flag. It also describes the product decision that a refresh failure may retain previous content. Your renderer should show an inline message when previous is nonempty and a full error state when it is empty.

</details>

## Challenge 2: Deduplicate an accepted page

**Level:** Core

Implement a pure function that merges a page of tasks into existing ordered content. Keep the first-seen position for each ID while allowing the newest payload to replace its content.

### Requirements

- Preserve existing order.
- Append only genuinely new IDs.
- Handle duplicates both across pages and within one page.
- Keep the function independent of UIKit.

### Starter

```swift
func mergePage(existing: [RemoteTask], incoming: [RemoteTask]) -> [RemoteTask] {
    return existing + incoming
}
```

<details>
<summary>Hints</summary>

- Track order separately from the dictionary of newest values.
- Process existing and incoming through the same loop.

</details>

### Acceptance checks

- Existing IDs [1, 2] plus incoming [2, 3] produces [1, 2, 3].
- The incoming content for ID 2 replaces the old content.
- Incoming [3, 3] adds one ID and keeps the latest payload.
- An empty page leaves existing rows unchanged.

<details>
<summary>Worked solution</summary>

```swift
func mergePage(existing: [RemoteTask], incoming: [RemoteTask]) -> [RemoteTask] {
    var order: [Int] = []
    var values: [Int: RemoteTask] = [:]
    for task in existing + incoming {
        if values[task.id] == nil { order.append(task.id) }
        values[task.id] = task
    }
    return order.compactMap { values[$0] }
}
```

Stable order and current content are separate responsibilities. This merge policy is appropriate only if later payloads are authoritative for the same task. If the API provides versions or updated timestamps, compare them instead of assuming arrival order equals freshness. Call this only after verifying that the page belongs to the current query and cursor.

</details>

## Challenge 3: Protect a reusable image view

**Level:** Stretch

Write a small MainActor image loader that clears old content, cancels an earlier request, and checks the requested URL before assigning an image.

### Requirements

- Use a weak UIImageView reference.
- Validate the HTTP response.
- Do not retain the image view across the network await.
- Provide cancel() for prepareForReuse.
- Document that this exercise is not a complete image cache.

### Starter

```swift
@MainActor
final class CellImageLoader {
    // Own one image request for one cell.
}
```

<details>
<summary>Hints</summary>

- Capture the URL as a value and compare it with the current URL.
- Fetch Data asynchronously, then create and assign the image only for the accepted request.

</details>

### Acceptance checks

- Load image A, immediately reconfigure for B, and ensure A never replaces B.
- Reuse the cell before completion and verify the placeholder remains.
- Navigate away and verify no request owns the image view strongly.
- Explain where a cache key and thumbnail-size policy would be added.

<details>
<summary>Worked solution</summary>

```swift
@MainActor
final class CellImageLoader {
    private weak var imageView: UIImageView?
    private var currentURL: URL?
    private var request: Task<Void, Never>?

    init(imageView: UIImageView) { self.imageView = imageView }

    func load(_ url: URL) {
        cancel()
        currentURL = url
        imageView?.image = UIImage(systemName: "photo")
        request = Task { [weak self] in
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                try Task.checkCancellation()
                guard let http = response as? HTTPURLResponse,
                      (200..<300).contains(http.statusCode),
                      let self, self.currentURL == url else { return }
                self.imageView?.image = UIImage(data: data)
            } catch {
                // Keep the placeholder; cancellation is expected on reuse.
            }
        }
    }

    func cancel() {
        currentURL = nil
        request?.cancel()
        request = nil
        imageView?.image = UIImage(systemName: "photo")
    }
}
```

Create one loader for the cell's image view and call cancel from prepareForReuse. The weak capture and post-await URL check prevent assigning an old request to a new model. For production, add bounded caching and prepare appropriately sized images off the main actor; this small example intentionally teaches lifecycle correctness rather than image-pipeline performance.

</details>

## Knowledge check

### 1. What does a successful response containing zero items represent?

A. Always an authentication failure

B. An empty content state

C. A reason to retry forever

D. A decoding error

<details>
<summary>Answer and explanation</summary>

**B. An empty content state**

A valid empty collection is a meaningful success. Give it an explanation or creation action instead of presenting a network error.

</details>

### 2. Why is debounce alone insufficient for search correctness?

A. It prevents all requests

B. Requests may still finish out of order

C. It changes every response ID

D. It disables cancellation

<details>
<summary>Answer and explanation</summary>

**B. Requests may still finish out of order**

Debounce controls when requests start. A current-query or generation check controls which completed request is still allowed to update the screen.

</details>

### 3. When should a pagination cursor advance?

A. Before making the request

B. After any failure

C. After accepting the successful page for the current dataset

D. Every time willDisplay is called

<details>
<summary>Answer and explanation</summary>

**C. After accepting the successful page for the current dataset**

Advancing on failure can skip a page. Accept the response only if it still belongs to the active query, then commit its next cursor.

</details>

### 4. Why clear an image before beginning a new cell request?

A. To remove stale content from the previously represented item

B. To guarantee the server responds faster

C. To avoid using stable identifiers

D. To force a new UUID

<details>
<summary>Answer and explanation</summary>

**A. To remove stale content from the previously represented item**

Reuse preserves the old image until you replace it. A placeholder immediately reflects that the newly represented item's image is not ready yet.

</details>

### 5. Which component should decide how an error state changes labels and list content?

A. The URLSession delegate and every button separately

B. One screen rendering path driven by state

C. The JSON model's decoder

D. A random global notification

<details>
<summary>Answer and explanation</summary>

**B. One screen rendering path driven by state**

A single render path makes visual outcomes consistent and lets the state model be tested separately from UIKit.

</details>

## Common pitfalls

- Using multiple independent booleans that permit contradictory screen states.
- Treating empty success as an error.
- Appending a page from an obsolete search query.
- Starting duplicate next-page requests before setting the loading guard.
- Assigning a downloaded image without validating current cell identity.
- Stopping the refresh indicator only on success.

## PocketTasks milestone: PocketTasks milestone: resilient content screens

1. Drive the inbox from explicit state and render all terminal outcomes.
2. Add debounced search and invalidate pagination when its query changes.
3. Implement guarded next-page loading with stable-ID merging.
4. Use delayed mock responses to test refresh, cancellation, and stale-result behavior.

## Before you move on

- Show initial loading, success, empty, and failure deliberately using a mock.
- Explain what users see during refresh with existing content.
- Prove an old query cannot append or replace newer results.
- Merge overlapping pages without duplicate snapshot IDs.
- Scroll rapidly while delayed images load and verify identity remains correct.

## Official references

- [UIRefreshControl](https://developer.apple.com/documentation/uikit/uirefreshcontrol)
- [UISearchController](https://developer.apple.com/documentation/uikit/uisearchcontroller)
- [UITableViewDataSourcePrefetching](https://developer.apple.com/documentation/uikit/uitableviewdatasourceprefetching)
- [URLCache](https://developer.apple.com/documentation/foundation/urlcache)

## Reflection

- What can I now explain without the example?
- What did I build and test in Xcode?
- Which bug or design tradeoff do I want to revisit?
