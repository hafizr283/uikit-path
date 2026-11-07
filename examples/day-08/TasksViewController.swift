// Day 08: Table views that stay correct
// Independent educational example. Read lessons/day-08.md for setup.
// In an iOS UIKit app, add this file and make UINavigationController(rootViewController: TasksViewController(style: .insetGrouped)) the window's root controller in your existing scene setup. This is an app view controller, not a command-line Swift script.
// The order array controls presentation order while the dictionary stores current model values. Each UUID is generated once when its model is created.
// The cell provider captures the controller weakly because the controller owns the data source, which retains the provider closure.
// Both accessory branches and both subtitle branches are assigned on every configuration, preventing recycled visual state.
// Tapping resolves the UUID through the data source, updates the model, and reconfigures that same stable identifier.

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
