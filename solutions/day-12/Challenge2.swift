// Worked solution: Deduplicate an accepted page
// Stable order and current content are separate responsibilities. This merge policy is appropriate only if later payloads are authoritative for the same task. If the API provides versions or updated timestamps, compare them instead of assuming arrival order equals freshness. Call this only after verifying that the page belongs to the current query and cursor.
// Read lessons/day-12.md for any surrounding types or setup.

func mergePage(existing: [RemoteTask], incoming: [RemoteTask]) -> [RemoteTask] {
    var order: [Int] = []
    var values: [Int: RemoteTask] = [:]
    for task in existing + incoming {
        if values[task.id] == nil { order.append(task.id) }
        values[task.id] = task
    }
    return order.compactMap { values[$0] }
}
