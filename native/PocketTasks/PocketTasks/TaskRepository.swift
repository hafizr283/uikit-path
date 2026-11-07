import Foundation

@MainActor
final class TaskRepository {
    private let persistence: any TaskPersistence
    private(set) var items: [TaskItem] = []
    private(set) var isBusy = false
    private(set) var hasLoaded = false
    var onChange: (() -> Void)?

    init(persistence: any TaskPersistence) {
        self.persistence = persistence
    }

    func item(id: UUID) -> TaskItem? {
        items.first { $0.id == id }
    }

    func load() async throws {
        guard !isBusy else { throw TaskError.busy }
        isBusy = true
        onChange?()
        defer {
            isBusy = false
            onChange?()
        }
        let loaded = try await persistence.load()
        try Task.checkCancellation()
        items = loaded
        hasLoaded = true
    }

    @discardableResult
    func add(title: String, notes: String) async throws -> TaskItem {
        guard hasLoaded else { throw TaskError.busy }
        let item = try TaskItem(title: title, notes: notes)
        try await persist([item] + items)
        return item
    }

    func update(id: UUID, title: String, notes: String) async throws {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            throw TaskError.missingTask
        }
        var next = items
        next[index].title = try TaskItem.validatedTitle(title)
        next[index].notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        next[index].updatedAt = Date()
        try await persist(next)
    }

    func toggle(id: UUID) async throws {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            throw TaskError.missingTask
        }
        var next = items
        next[index].isComplete.toggle()
        next[index].updatedAt = Date()
        try await persist(next)
    }

    func delete(id: UUID) async throws {
        guard items.contains(where: { $0.id == id }) else {
            throw TaskError.missingTask
        }
        try await persist(items.filter { $0.id != id })
    }

    private func persist(_ next: [TaskItem]) async throws {
        guard !isBusy else { throw TaskError.busy }
        isBusy = true
        onChange?()
        defer {
            isBusy = false
            onChange?()
        }
        // Publish only after persistence succeeds. A failed write leaves
        // the last known-good in-memory and visible state unchanged.
        try await persistence.save(next)
        items = next
    }
}
