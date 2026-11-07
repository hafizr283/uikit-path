// Repair a reused checkmark
// A teammate's cell configuration only adds a checkmark for completed tasks. Rewrite it so unfinished tasks can never inherit old content, and explain why scrolling reveals the bug.
// See lessons/day-08.md for requirements, hints, and acceptance checks.
// Independent exercise; do not add all course files to one Xcode target.

func configure(_ cell: UITableViewCell, task: TaskItem) {
    if task.isDone { cell.accessoryType = .checkmark }
}
