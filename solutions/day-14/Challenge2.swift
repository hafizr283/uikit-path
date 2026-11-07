// Worked solution: Export and restore a Codable snapshot
// The actor serializes operations through this instance, and atomic replacement reduces partial-write exposure. It does not coordinate unrelated processes or multiple independently created stores writing the same file. Inject a URL under Application Support for durable internal data, or a temporary directory for tests. This snapshot approach suits modest datasets; it is not a substitute for database queries or multi-writer transactions.
// Read lessons/day-14.md for any surrounding types or setup.

actor TaskFileStore {
    private let fileURL: URL
    init(fileURL: URL) { self.fileURL = fileURL }

    func save(_ tasks: [SavedTask]) throws {
        let data = try JSONEncoder().encode(tasks)
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: fileURL, options: .atomic)
    }

    func load() throws -> [SavedTask] {
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([SavedTask].self, from: data)
        } catch let error as NSError
            where error.domain == NSCocoaErrorDomain
                && error.code == NSFileReadNoSuchFileError {
            return []
        }
    }
}
