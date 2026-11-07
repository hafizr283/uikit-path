// Day 14: Persistence and offline data
// Independent educational example. Read lessons/day-14.md for setup.
// In Xcode, add a Data Model file named PocketTasks.xcdatamodeld to the app target. Add an entity named StoredTask, set its Codegen to Manual/None, and use the base NSManagedObject class. Add required attributes id: UUID, title: String, and isDone: Boolean with default NO. This model setup is required; the Swift file alone does not create the schema.
// From a main-actor async setup path, call let store = try await LocalTaskStore.open(). Keep the store in your app's dependency graph rather than creating one per cell.
// Call try store.create(title: "Persist my first task"), then try store.fetchTasks(). Toggle or delete using the returned stable UUID.
// The sample returns Sendable value snapshots rather than exposing managed objects to controllers or other concurrency domains.
// The store owns its context's edits, so rollback on a failed save discards only this store's pending transaction. Do not share this context with unrelated unsaved form edits without redesigning that policy.
// Use open(inMemory: true) for fast isolated CRUD tests. Use an actual temporary on-disk store when testing relaunch persistence and migrations.

import Foundation
import CoreData

struct StoredTaskValue: Identifiable, Sendable {
    let id: UUID
    let title: String
    let isDone: Bool
}

enum LocalStoreError: Error {
    case blankTitle
    case missingTask
    case invalidRecord
}

@MainActor
final class LocalTaskStore {
    private let container: NSPersistentContainer
    private var context: NSManagedObjectContext { container.viewContext }

    private init(container: NSPersistentContainer) {
        self.container = container
    }

    static func open(inMemory: Bool = false) async throws -> LocalTaskStore {
        // Requires PocketTasks.xcdatamodeld with the schema in the walkthrough.
        let container = NSPersistentContainer(name: "PocketTasks")
        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }
        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, Error>) in
            // This example configures exactly one persistent store.
            container.loadPersistentStores { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return LocalTaskStore(container: container)
    }

    func create(title: String) throws -> UUID {
        let cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { throw LocalStoreError.blankTitle }
        let object = NSEntityDescription.insertNewObject(
            forEntityName: "StoredTask", into: context
        )
        let id = UUID()
        object.setValue(id, forKey: "id")
        object.setValue(cleaned, forKey: "title")
        object.setValue(false, forKey: "isDone")
        try saveOrRollback()
        return id
    }

    func fetchTasks() throws -> [StoredTaskValue] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "StoredTask")
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        return try context.fetch(request).map { object in
            guard let id = object.value(forKey: "id") as? UUID,
                  let title = object.value(forKey: "title") as? String,
                  let isDone = object.value(forKey: "isDone") as? Bool else {
                throw LocalStoreError.invalidRecord
            }
            return StoredTaskValue(id: id, title: title, isDone: isDone)
        }
    }

    func toggle(id: UUID) throws {
        let object = try find(id: id)
        let current = object.value(forKey: "isDone") as? Bool ?? false
        object.setValue(!current, forKey: "isDone")
        try saveOrRollback()
    }

    func delete(id: UUID) throws {
        context.delete(try find(id: id))
        try saveOrRollback()
    }

    private func find(id: UUID) throws -> NSManagedObject {
        let request = NSFetchRequest<NSManagedObject>(entityName: "StoredTask")
        request.predicate = NSPredicate(format: "id == %@", id as NSUUID)
        request.fetchLimit = 1
        guard let object = try context.fetch(request).first else {
            throw LocalStoreError.missingTask
        }
        return object
    }

    private func saveOrRollback() throws {
        do { try context.save() }
        catch {
            context.rollback()
            throw error
        }
    }
}
