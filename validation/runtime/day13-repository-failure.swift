import Foundation

@main
enum ValidationMain {
    @MainActor
    static func main() async throws {
        let failedCorrectly = await verifyFailureState()
        precondition(failedCorrectly)
        let id = UUID()
        let repository = MemoryTaskRepository(tasks: [
            TaskRecord(id: id, title: "Test repository", isDone: false)
        ])
        let model = TasksViewModel(repository: repository)
        await model.reload()
        guard case .ready(let firstRows) = model.state else {
            preconditionFailure("A successful repository must publish rows")
        }
        precondition(firstRows.count == 1 && firstRows[0].subtitle == "To do")
        try await repository.toggleTask(id: id)
        await model.reload()
        guard case .ready(let updatedRows) = model.state else {
            preconditionFailure("Reload must publish updated rows")
        }
        precondition(updatedRows[0].id == id && updatedRows[0].subtitle == "Completed")
        do {
            try await repository.toggleTask(id: UUID())
            preconditionFailure("Unknown task ids must be rejected")
        } catch RepositoryError.missingTask {}
    }
}
