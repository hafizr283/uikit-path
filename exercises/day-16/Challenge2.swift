// Prove recovery after an initial failure
// Using the teaching types from the example, provide an actor-based loader that fails once, then succeeds. Test that calling load again replaces the error with loaded content.
// See lessons/day-16.md for requirements, hints, and acceptance checks.
// Independent exercise; do not add all course files to one Xcode target.

// Add this exercise to TaskListViewModelTests.swift.
private actor RetryLoader: TaskLoading {
    func fetchTasks() async throws -> [TaskItem] {
        // Fail once, then return a fixture.
        []
    }
}
