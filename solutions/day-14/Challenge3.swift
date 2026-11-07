// Worked solution: Fetch a background snapshot safely
// All managed-object reads occur inside the context's perform closure, and only plain values return to the main actor. This fetch sees saved store content, not arbitrary unsaved edits in another context. If adapting it to an import, save on that background context and define how the UI context merges changes. Keep SDK concurrency diagnostics enabled; do not bypass them by marking managed objects unchecked Sendable.
// Read lessons/day-14.md for any surrounding types or setup.

func fetchSnapshotInBackground() async throws -> [StoredTaskValue] {
    let background = container.newBackgroundContext()
    return try await background.perform {
        let request = NSFetchRequest<NSManagedObject>(entityName: "StoredTask")
        request.sortDescriptors = [
            NSSortDescriptor(key: "title", ascending: true)
        ]
        return try background.fetch(request).map { object in
            guard let id = object.value(forKey: "id") as? UUID,
                  let title = object.value(forKey: "title") as? String,
                  let done = object.value(forKey: "isDone") as? Bool else {
                throw LocalStoreError.invalidRecord
            }
            return StoredTaskValue(id: id, title: title, isDone: done)
        }
    }
}
