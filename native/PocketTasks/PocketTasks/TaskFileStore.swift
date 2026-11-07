import Foundation

protocol TaskPersistence: Sendable {
    func load() async throws -> [TaskItem]
    func save(_ items: [TaskItem]) async throws
}

actor TaskFileStore: TaskPersistence {
    private struct Document: Codable {
        let version: Int
        let tasks: [TaskItem]
    }

    private let fileURL: URL

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    func load() async throws -> [TaskItem] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        let data = try Data(contentsOf: fileURL)
        let document = try JSONDecoder().decode(Document.self, from: data)
        guard document.version == 1 else {
            throw TaskError.unsupportedFileVersion
        }
        guard Set(document.tasks.map(\.id)).count == document.tasks.count else {
            throw TaskError.invalidStoredData
        }
        for task in document.tasks {
            guard (try? TaskItem.validatedTitle(task.title)) == task.title else {
                throw TaskError.invalidStoredData
            }
        }
        return document.tasks
    }

    func save(_ items: [TaskItem]) async throws {
        let parent = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: parent, withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(Document(version: 1, tasks: items))
        try data.write(to: fileURL, options: .atomic)
    }
}
