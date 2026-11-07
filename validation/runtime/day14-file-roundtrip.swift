import Foundation

@main
enum ValidationMain {
    static func main() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("UIKitPath-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("nested/tasks.json")
        let store = TaskFileStore(fileURL: file)
        let missing = try await store.load()
        precondition(missing.isEmpty)
        let id = UUID()
        let values = [SavedTask(id: id, title: "Persist", isDone: true)]
        try await store.save(values)
        let loaded = try await TaskFileStore(fileURL: file).load()
        precondition(loaded.count == 1 && loaded[0].id == id)
        precondition(loaded[0].title == "Persist" && loaded[0].isDone)
        try Data("not json".utf8).write(to: file, options: .atomic)
        do {
            _ = try await store.load()
            preconditionFailure("A corrupt file must not become a silent empty list")
        } catch is DecodingError {}
    }
}
