// Day 01: Swift that holds up in a real app
// Independent educational example. Read lessons/day-01.md for setup.
// Paste the whole example into a Swift playground and add runDay01Example() at the bottom. In an app source file, keep the function declaration and call it from temporary debug code rather than adding a top-level expression.
// The initializer trims input and either produces a valid model or throws. Outside callers cannot directly assign title or isComplete.
// Assigning original to draft creates an independent value but preserves its id: this is an edited draft of the same logical task, not a newly created task.
// pendingTitles only needs TaskReading. Replace the in-memory reader with a real service later without changing the consumer.
// firstMatch is an additional generic helper. It preserves the concrete array element type and communicates absence with an optional.

import Foundation

enum TaskValidationError: Error { case emptyTitle }
enum Priority: String, Codable { case low, normal, high }

struct TaskItem: Identifiable, Equatable {
    let id: UUID
    private(set) var title: String
    var priority: Priority
    private(set) var isComplete: Bool

    init(id: UUID = UUID(), title: String,
         priority: Priority = .normal) throws {
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { throw TaskValidationError.emptyTitle }
        self.id = id
        self.title = clean
        self.priority = priority
        self.isComplete = false
    }

    mutating func rename(to proposedTitle: String) throws {
        let clean = proposedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { throw TaskValidationError.emptyTitle }
        title = clean
    }

    mutating func toggleCompletion() { isComplete.toggle() }
}

protocol TaskReading { func allTasks() -> [TaskItem] }

struct MemoryTaskReader: TaskReading {
    let items: [TaskItem]
    func allTasks() -> [TaskItem] { items }
}

func pendingTitles(from reader: any TaskReading) -> [String] {
    reader.allTasks().filter { !$0.isComplete }.map { $0.title }
}

func firstMatch<T>(in values: [T], matching predicate: (T) -> Bool) -> T? {
    values.first(where: predicate)
}

func runDay01Example() {
    do {
        let original = try TaskItem(title: "  Learn Auto Layout  ")
        var draft = original
        try draft.rename(to: "Practice constraints")
        draft.toggleCompletion()
        let reader = MemoryTaskReader(items: [original, draft])
        print(original.title)
        print(draft.title, draft.isComplete)
        print(pendingTitles(from: reader))
    } catch {
        print("Validation failed:", error)
    }
}
