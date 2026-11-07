import Foundation

@main
enum ValidationMain {
    static func main() throws {
        let id = UUID()
        let original = try TaskItem(id: id, title: "  Learn UIKit\n")
        precondition(original.title == "Learn UIKit")
        precondition(original.id == id)
        var draft = original
        try draft.rename(to: " Revised ")
        draft.toggleCompletion()
        precondition(original.title == "Learn UIKit" && !original.isComplete)
        precondition(draft.title == "Revised" && draft.isComplete)
        precondition(draft.id == original.id)
        do {
            try draft.rename(to: " \n\t")
            preconditionFailure("Blank rename must throw")
        } catch TaskValidationError.emptyTitle {
            precondition(draft.title == "Revised")
        }
        do {
            _ = try TaskItem(title: " ")
            preconditionFailure("Blank construction must throw")
        } catch TaskValidationError.emptyTitle {}
        let reader = MemoryTaskReader(items: [original, draft])
        precondition(pendingTitles(from: reader) == ["Learn UIKit"])
        precondition(firstMatch(in: [1, 2, 3], matching: { $0 > 1 }) == 2)
        precondition(firstMatch(in: [1, 2], matching: { $0 > 3 }) == nil)
    }
}
