// Worked solution: Repair a reused checkmark
// Reuse preserves object properties. A one-sided conditional leaves the previous task's accessory untouched when the new task is incomplete. Full configuration makes the cell a rendering of the current model rather than a memory of past models.
// Read lessons/day-08.md for any surrounding types or setup.

@MainActor
func configure(_ cell: UITableViewCell, task: TaskItem) {
    var content = cell.defaultContentConfiguration()
    content.text = task.title
    content.secondaryText = task.isDone ? "Completed" : "To do"
    cell.contentConfiguration = content
    cell.accessoryType = task.isDone ? .checkmark : .none
}
