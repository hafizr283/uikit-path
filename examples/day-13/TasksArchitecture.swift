// Day 13: Architecture that makes changes easier
// Independent educational example. Read lessons/day-13.md for setup.
// This Foundation-only file demonstrates the architecture boundary; it deliberately contains no UIKit widgets. Add it to an app or suitable Swift target and await demonstrateArchitecture() from an async context.
// TaskRepository is Sendable so its implementation can cross from the main-actor view model to an actor-backed store safely. The actor serializes mutations to its task array.
// TaskRecord represents domain data. TaskRow represents one screen's display values. They need not remain separate in every tiny app, but the distinction becomes useful when formatting and server contracts evolve.
// The view model exposes an async reload method. In a controller, store the Task handle that calls it and cancel according to the screen's lifecycle; do not create an untracked load on every appearance.
// The composition root decides the concrete repository. Replacing MemoryTaskRepository with a tested remote/local implementation does not require rewriting the renderer.
// Cancellation can surface as CancellationError or as a transport error from URLSession. The generic catch checks the owning task's cancellation flag and the current generation before publishing a genuine failure.

import Foundation

struct TaskRecord: Identifiable, Sendable {
    let id: UUID
    var title: String
    var isDone: Bool
}

protocol TaskRepository: Sendable {
    func fetchTasks() async throws -> [TaskRecord]
    func toggleTask(id: UUID) async throws
}

enum RepositoryError: Error { case missingTask }

actor MemoryTaskRepository: TaskRepository {
    private var tasks: [TaskRecord]

    init(tasks: [TaskRecord]) { self.tasks = tasks }

    func fetchTasks() async throws -> [TaskRecord] { tasks }

    func toggleTask(id: UUID) async throws {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else {
            throw RepositoryError.missingTask
        }
        tasks[index].isDone.toggle()
    }
}

struct TaskRow: Identifiable, Equatable, Sendable {
    let id: UUID
    let title: String
    let subtitle: String

    init(task: TaskRecord) {
        id = task.id
        title = task.title
        subtitle = task.isDone ? "Completed" : "To do"
    }
}

enum TasksPresentation {
    case idle
    case loading
    case ready([TaskRow])
    case failed(String)
}

@MainActor
final class TasksViewModel {
    private let repository: any TaskRepository
    private var generation = 0
    private(set) var state: TasksPresentation = .idle {
        didSet { onChange?(state) }
    }
    var onChange: ((TasksPresentation) -> Void)?

    init(repository: any TaskRepository) {
        self.repository = repository
    }

    func reload() async {
        generation += 1
        let current = generation
        state = .loading
        do {
            let records = try await repository.fetchTasks()
            try Task.checkCancellation()
            guard current == generation else { return }
            state = .ready(records.map(TaskRow.init))
        } catch is CancellationError {
            // The owner cancelled this presentation request.
        } catch {
            // URLSession may report cancellation as URLError.cancelled.
            guard !Task.isCancelled, current == generation else { return }
            state = .failed("Unable to load tasks. Please retry.")
        }
    }
}

// A small composition root for an example or test.
// A UIKit controller can observe onChange and render rows with a diffable source.
@MainActor
func makeDemoViewModel() -> TasksViewModel {
    let repository = MemoryTaskRepository(tasks: [
        TaskRecord(id: UUID(), title: "Separate rendering from data access", isDone: false),
        TaskRecord(id: UUID(), title: "Inject a repository", isDone: true)
    ])
    return TasksViewModel(repository: repository)
}

@MainActor
func demonstrateArchitecture() async {
    let model = makeDemoViewModel()
    model.onChange = { state in
        if case .ready(let rows) = state {
            print(rows.map(\.subtitle))
        }
    }
    await model.reload()
}
