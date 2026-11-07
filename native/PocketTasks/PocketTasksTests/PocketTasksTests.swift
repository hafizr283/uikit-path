import Foundation
import XCTest
@testable import PocketTasks

private enum FixtureError: Error { case writeFailed }

private actor MemoryStore: TaskPersistence {
    private var items: [TaskItem]
    private let failsSaving: Bool

    init(items: [TaskItem] = [], failsSaving: Bool = false) {
        self.items = items
        self.failsSaving = failsSaving
    }

    func load() async throws -> [TaskItem] { items }

    func save(_ items: [TaskItem]) async throws {
        if failsSaving { throw FixtureError.writeFailed }
        self.items = items
    }
}

final class PocketTasksTests: XCTestCase {
    func testTitleValidationTrimsAndRejectsInvalidValues() throws {
        XCTAssertEqual(try TaskItem.validatedTitle("  Read docs\n"), "Read docs")
        XCTAssertThrowsError(try TaskItem.validatedTitle("  \n"))
        XCTAssertNoThrow(try TaskItem.validatedTitle(String(repeating: "a", count: 80)))
        XCTAssertThrowsError(try TaskItem.validatedTitle(String(repeating: "a", count: 81)))
    }

    @MainActor
    func testAddUpdateToggleDeletePublishesPersistedState() async throws {
        let store = MemoryStore()
        let repository = TaskRepository(persistence: store)
        try await repository.load()
        let task = try await repository.add(title: "  Learn UIKit ", notes: " Start ")
        XCTAssertEqual(task.title, "Learn UIKit")
        try await repository.update(id: task.id, title: "Practice UIKit", notes: "More")
        try await repository.toggle(id: task.id)
        let updated = repository.item(id: task.id)
        XCTAssertEqual(updated?.title, "Practice UIKit")
        XCTAssertEqual(updated?.isComplete, true)
        let persisted = try await store.load()
        XCTAssertEqual(persisted, repository.items)
        try await repository.delete(id: task.id)
        XCTAssertTrue(repository.items.isEmpty)
        let afterDelete = try await store.load()
        XCTAssertTrue(afterDelete.isEmpty)
    }

    @MainActor
    func testFailedWriteLeavesLastGoodStateUnchanged() async throws {
        let existing = try TaskItem(title: "Keep me")
        let repository = TaskRepository(
            persistence: MemoryStore(items: [existing], failsSaving: true)
        )
        try await repository.load()
        do {
            try await repository.add(title: "Will fail", notes: "")
            XCTFail("Expected the persistence error")
        } catch FixtureError.writeFailed {
            // Expected.
        }
        XCTAssertEqual(repository.items, [existing])
        XCTAssertFalse(repository.isBusy)
    }

    func testFileStoreRoundTripAndEmptyFirstLaunch() async throws {
        let folder = FileManager.default.temporaryDirectory
            .appending(path: "PocketTasksTests-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = TaskFileStore(fileURL: folder.appending(path: "tasks.json"))
        let initial = try await store.load()
        XCTAssertTrue(initial.isEmpty)
        let task = try TaskItem(title: "Persist this", notes: "Fixture")
        try await store.save([task])
        let reloaded = try await TaskFileStore(
            fileURL: folder.appending(path: "tasks.json")
        ).load()
        XCTAssertEqual(reloaded, [task])
    }

    func testCorruptFileIsReportedInsteadOfOverwritten() async throws {
        let folder = FileManager.default.temporaryDirectory
            .appending(path: "PocketTasksTests-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        try FileManager.default.createDirectory(
            at: folder, withIntermediateDirectories: true
        )
        let url = folder.appending(path: "tasks.json")
        let original = Data("not valid JSON".utf8)
        try original.write(to: url)
        do {
            _ = try await TaskFileStore(fileURL: url).load()
            XCTFail("Expected a decoding error")
        } catch is DecodingError {
            // Expected.
        }
        XCTAssertEqual(try Data(contentsOf: url), original)
    }

    func testDuplicateStoredIDsAreRejectedBeforeRendering() async throws {
        let folder = FileManager.default.temporaryDirectory
            .appending(path: "PocketTasksTests-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = TaskFileStore(fileURL: folder.appending(path: "tasks.json"))
        let item = try TaskItem(title: "Duplicate fixture")
        try await store.save([item, item])
        do {
            _ = try await store.load()
            XCTFail("Duplicate IDs must not reach a diffable snapshot")
        } catch TaskError.invalidStoredData {
            // Expected.
        }
    }
}
