// Worked solution: Replace conflicting state flags
// The state cannot be loading and failed at once. Adding a new enum case makes the compiler identify consumers that need updating. Localize presentation strings when the app reaches production UI work.
// Read lessons/day-01.md for any surrounding types or setup.

enum TaskListState {
    case idle
    case loading
    case loaded([TaskItem])
    case failed(String)
}

func statusMessage(for state: TaskListState) -> String {
    switch state {
    case .idle: return "Ready to load"
    case .loading: return "Loading tasks…"
    case .loaded(let tasks):
        return tasks.isEmpty ? "No tasks yet" : "\(tasks.count) tasks"
    case .failed(let message): return "Could not load: \(message)"
    }
}
