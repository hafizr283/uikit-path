// Worked solution: Load independent counts concurrently
// The service actor can accept the second call while the first is suspended in Task.sleep. The two waits overlap even though actor-isolated synchronous work never runs simultaneously on the actor. If an operation throws and the scope exits, remaining structured children are cancelled and awaited.
// Read lessons/day-10.md for any surrounding types or setup.

struct TaskSummary: Sendable {
    let open: Int
    let completed: Int
}

actor SummaryService {
    func openCount() async throws -> Int {
        try await Task.sleep(for: .milliseconds(400))
        return 8
    }
    func completedCount() async throws -> Int {
        try await Task.sleep(for: .milliseconds(600))
        return 3
    }
}

func loadSummary(from service: SummaryService) async throws -> TaskSummary {
    async let open = service.openCount()
    async let completed = service.completedCount()
    let values = try await (open, completed)
    return TaskSummary(open: values.0, completed: values.1)
}
