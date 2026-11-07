// Worked solution: Inject a repository that fails predictably
// This fake represents a specific boundary outcome and makes the test repeatable. It verifies behavior that matters to the user: the view model offers a recoverable failure state. Day 16 converts this kind of check into XCTest assertions and adds success, empty, and cancellation coverage.
// Read lessons/day-13.md for any surrounding types or setup.

enum DemoFailure: Error { case unavailable }

struct FailingRepository: TaskRepository {
    func fetchTasks() async throws -> [TaskRecord] {
        throw DemoFailure.unavailable
    }

    func toggleTask(id: UUID) async throws {
        throw DemoFailure.unavailable
    }
}

@MainActor
func verifyFailureState() async -> Bool {
    let model = TasksViewModel(repository: FailingRepository())
    await model.reload()
    if case .failed(let message) = model.state {
        return message.contains("retry")
    }
    return false
}
