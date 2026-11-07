// Day 12: Reliable API-powered screens
// Independent educational example. Read lessons/day-12.md for setup.
// Include Day 11's TaskAPI.swift. Construct APITasksViewController(api: TaskAPI(baseURL: yourURL)) and place it in a navigation controller so Reload is visible.
// The model's callback is bound before viewWillAppear starts loading. Reappearing deliberately starts a fresh load; a production screen may use freshness rules instead.
// The request generation ensures cancelled or superseded requests cannot publish success or failure into a newer screen state.
// render handles all visual states and deduplicates remote IDs before building the snapshot. Its example policy keeps the latest content for a duplicate ID.
// This introductory state model clears existing rows during refresh. The Warm-up exercise designs a richer state model that preserves content while refresh is in progress.

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
