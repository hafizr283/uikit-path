import Foundation

struct TaskItem: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var title: String
    var notes: String
    var isComplete: Bool
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        isComplete: Bool = false,
        now: Date = Date()
    ) throws {
        self.id = id
        self.title = try Self.validatedTitle(title)
        self.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        self.isComplete = isComplete
        self.createdAt = now
        self.updatedAt = now
    }

    static func validatedTitle(_ title: String) throws -> String {
        let result = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !result.isEmpty else { throw TaskError.emptyTitle }
        guard result.count <= 80 else { throw TaskError.titleTooLong }
        return result
    }
}

enum TaskError: LocalizedError {
    case emptyTitle
    case titleTooLong
    case missingTask
    case busy
    case unsupportedFileVersion
    case invalidStoredData

    var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return "Enter a task title."
        case .titleTooLong:
            return "Keep the title to 80 characters or fewer."
        case .missingTask:
            return "This task is no longer available."
        case .busy:
            return "Another change is being saved. Please try again."
        case .unsupportedFileVersion:
            return "This task file was created by an unsupported app version."
        case .invalidStoredData:
            return "The saved task file contains invalid or duplicate tasks."
        }
    }
}
