import UIKit

@MainActor
final class TaskListViewController: UITableViewController {
    private let repository: TaskRepository
    private var loadTask: Task<Void, Never>?
    private let emptyLabel = UILabel()

    private lazy var source = UITableViewDiffableDataSource<Int, UUID>(
        tableView: tableView
    ) { [weak self] tableView, indexPath, id in
        guard let self, let item = self.repository.item(id: id) else {
            return nil
        }
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "TaskCell", for: indexPath
        )
        var content = cell.defaultContentConfiguration()
        content.text = item.title
        content.secondaryText = item.isComplete ? "Completed" : "Open"
        content.image = UIImage(
            systemName: item.isComplete ? "checkmark.circle.fill" : "circle"
        )
        content.imageProperties.tintColor = item.isComplete
            ? .systemGreen : .secondaryLabel
        content.textProperties.numberOfLines = 0
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        cell.accessibilityIdentifier = "task.row." + id.uuidString
        cell.accessibilityLabel = item.title
        cell.accessibilityValue = item.isComplete ? "Completed" : "Open"
        return cell
    }

    init(repository: TaskRepository) {
        self.repository = repository
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("Use init(repository:)")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "PocketTasks"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add, target: self, action: #selector(addTask)
        )
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = "task.add"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TaskCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 70

        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.font = .preferredFont(forTextStyle: .body)
        emptyLabel.adjustsFontForContentSizeCategory = true
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.accessibilityIdentifier = "task.emptyState"

        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(refreshTasks), for: .valueChanged)
        refreshControl = refresh

        repository.onChange = { [weak self] in self?.render() }
        render()
        beginLoad()
    }

    private func render() {
        navigationItem.rightBarButtonItem?.isEnabled =
            repository.hasLoaded && !repository.isBusy
        var snapshot = NSDiffableDataSourceSnapshot<Int, UUID>()
        snapshot.appendSections([0])
        snapshot.appendItems(repository.items.map(\.id))
        // Stable IDs require explicit reconfiguration when content changes.
        let currentIDs = Set(source.snapshot().itemIdentifiers)
        snapshot.reconfigureItems(
            snapshot.itemIdentifiers.filter { currentIDs.contains($0) }
        )
        source.apply(snapshot, animatingDifferences: repository.hasLoaded)

        if repository.items.isEmpty {
            emptyLabel.text = repository.isBusy
                ? "Loading tasks…"
                : (repository.hasLoaded
                    ? "No tasks yet.\nTap + to add your first task."
                    : "Tasks have not loaded.\nPull down to retry.")
            tableView.backgroundView = emptyLabel
        } else {
            tableView.backgroundView = nil
        }
        if !repository.isBusy { refreshControl?.endRefreshing() }
    }

    private func beginLoad() {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await repository.load()
            } catch is CancellationError {
                return
            } catch {
                showError(error, retry: true)
            }
        }
    }

    @objc private func refreshTasks() {
        guard !repository.isBusy else {
            refreshControl?.endRefreshing()
            return
        }
        beginLoad()
    }

    @objc private func addTask() {
        let editor = TaskEditorViewController(repository: repository)
        let navigation = UINavigationController(rootViewController: editor)
        present(navigation, animated: true)
    }

    override func tableView(
        _ tableView: UITableView, didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let id = source.itemIdentifier(for: indexPath) else { return }
        navigationController?.pushViewController(
            TaskDetailViewController(repository: repository, taskID: id),
            animated: true
        )
    }

    private func showError(_ error: Error, retry: Bool) {
        let alert = UIAlertController(
            title: "Could not load tasks",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        if retry {
            alert.addAction(UIAlertAction(title: "Retry", style: .default) {
                [weak self] _ in self?.beginLoad()
            })
        }
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }
}
