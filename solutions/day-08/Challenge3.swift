// Worked solution: Delete by identifier and render an empty state
// One state transition updates the model and asks the snapshot to represent it. Mixing manual row deletion with diffable updates introduces a second, potentially contradictory update mechanism. Also call updateEmptyState after the initial load and addTask so the message always follows the model.
// Read lessons/day-08.md for any surrounding types or setup.

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
