// Worked solution: Add tasks without changing existing identities
// Stable identifiers allow the diffable data source to recognize existing rows. Recreating every model with a fresh UUID would describe a replacement of the entire list and could lose selection or associated state. Call the method from a button or a temporary line after the initial snapshot.
// Read lessons/day-08.md for any surrounding types or setup.

private func addTask(title: String) {
    let cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !cleaned.isEmpty else { return }
    let task = TaskItem(id: UUID(), title: cleaned, isDone: false)
    tasks[task.id] = task
    order.insert(task.id, at: 0)
    applySnapshot()
}
