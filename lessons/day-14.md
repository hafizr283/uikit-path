# Day 14: Persistence and offline data

Choose the right storage tool, build Core Data CRUD, and define what offline truth means.

**Time:** 3–4 hours · **Target:** Swift 6 / iOS 17+

[Interactive lesson](http://hafizr283.me/uikit-path/#/day/14/lesson) · [Course overview](../README.md)

## Outcomes

- Choose between UserDefaults, files, Keychain, and Core Data based on data meaning.
- Perform Core Data create, read, update, and delete operations through an owned context.
- Explain managed-object identity, relationships, save propagation, and context confinement.
- Plan schema changes and verify migrations with existing stores.
- Design a basic offline repository policy without silently overwriting user changes.

## Before you begin

- Day 13: repository boundaries and a single data authority.
- Codable, error handling, UUID, actor isolation, and asynchronous setup.

## 1. Match storage to the data

UserDefaults stores small preferences such as the selected sort mode or whether an introduction was shown. It is not a secret vault or a convenient replacement for a database. Files work well for documents, exports, and modest Codable snapshots. Keychain is the appropriate system facility for small secrets such as session credentials. Core Data manages an object graph with querying, relationships, change tracking, and persistent stores.

Choose the directory intentionally. Application Support is appropriate for internal durable app data; Caches contains recreatable data the system may purge; Documents is for user documents as appropriate to the app's file-sharing behavior. Do not assume an app bundle is writable. Do not put large response caches in UserDefaults, and do not present a cache as a guaranteed durable source of user-created work.

## 2. Core Data has a model, a store, and contexts

The managed-object model defines entities, attributes, relationships, constraints, and model versions. NSPersistentContainer coordinates the persistent stack. An NSManagedObjectContext is an editing workspace that tracks inserted, changed, and deleted objects. Fetching or editing a managed object does not automatically write it to disk; save the appropriate context and handle errors.

Managed objects belong to their context and its queue. The viewContext is intended for main-queue use. A background context must be accessed through its perform API. Do not hand a live NSManagedObject to another actor or queue. Pass a permanent NSManagedObjectID and refetch in the destination context, or return an immutable Sendable value snapshot containing the fields the caller needs.

## 3. Model relationships and deletion deliberately

A Task entity may have a relationship to a Project, with the inverse Project.tasks relationship describing the other direction. Inverse relationships help Core Data maintain graph consistency. Choose delete rules from domain meaning: nullify can detach tasks when a project is removed, cascade can remove owned child records, and deny can prohibit deletion while related records exist.

Add uniqueness constraints only when you understand identity and conflict handling. A stable task UUID is useful for matching remote and local records, but importing two objects with that UUID still needs an explicit merge policy or fetch-and-update strategy. Fetch predicates and sort descriptors should express what the screen needs; avoid loading every large record and filtering it repeatedly on the main actor.

## 4. Background changes and schema evolution need a plan

A new background context does not share live object instances with viewContext. Save the background context, then merge accepted changes into the UI context, for example through automaticallyMergesChangesFromParent when appropriate to your stack. Batch updates and deletes have additional merging requirements because they can bypass in-memory objects. Test what existing screens observe after an import.

For schema evolution, create a new model version instead of editing a shipped model in place without a migration plan. Lightweight migration can infer certain compatible changes, including some additive changes and renames when configured with renaming identifiers. More complex transformations may require a custom migration. Always test a copy of an old populated store, including relationship behavior and required new values; a fresh simulator install proves very little about upgrades.

## 5. Offline support is a consistency policy

An offline-capable repository must define which local data is authoritative, how pending writes are recorded, and how remote acknowledgments change their state. A simple policy reads local tasks immediately, marks edits pending, retries synchronization when connectivity permits, and records failures visibly. Do not discard a user's offline edit merely because an older server response arrives later.

Conflicts need a product decision. Last-write-wins requires trustworthy version or time semantics; server versions can reject stale edits; field-level merging may preserve independent changes. A successful network response does not automatically mean the local database commit succeeded. Keep enough operation identity and error information to recover. Start with a small, documented policy and controlled failure tests before promising complete offline synchronization.

## Worked example: Core Data CRUD behind an owned store

**File:** LocalTaskStore.swift

```swift
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
```

### Walkthrough and setup

1. In Xcode, add a Data Model file named PocketTasks.xcdatamodeld to the app target. Add an entity named StoredTask, set its Codegen to Manual/None, and use the base NSManagedObject class. Add required attributes id: UUID, title: String, and isDone: Boolean with default NO. This model setup is required; the Swift file alone does not create the schema.
2. From a main-actor async setup path, call let store = try await LocalTaskStore.open(). Keep the store in your app's dependency graph rather than creating one per cell.
3. Call try store.create(title: "Persist my first task"), then try store.fetchTasks(). Toggle or delete using the returned stable UUID.
4. The sample returns Sendable value snapshots rather than exposing managed objects to controllers or other concurrency domains.
5. The store owns its context's edits, so rollback on a failed save discards only this store's pending transaction. Do not share this context with unrelated unsaved form edits without redesigning that policy.
6. Use open(inMemory: true) for fast isolated CRUD tests. Use an actual temporary on-disk store when testing relaunch persistence and migrations.

**Expected behavior:** After creating a task, fetchTasks returns its stable UUID, title, and completion value. A normal persistent store keeps saved records across app relaunches; the in-memory option intentionally does not.

## Challenge 1: Store a preference with a safe default

**Level:** Warm-up

Create a small UserDefaults wrapper for the inbox sort mode. Unknown or absent stored values must fall back to title sorting.

### Requirements

- Use a typed enum rather than scattered string comparisons.
- Inject UserDefaults so tests can use an isolated suite.
- Store only the small preference, not the task list.

### Starter

```swift
enum TaskSort: String { case title, createdAt }
struct TaskPreferences {
    // Inject defaults and expose sort.
}
```

<details>
<summary>Hints</summary>

- An enum raw-value initializer can fail for obsolete stored values.
- Use a namespaced key to avoid collisions.

</details>

### Acceptance checks

- With no stored value, sort is title.
- Set createdAt and read it back from another wrapper using the same suite.
- Store an unknown raw string and confirm the wrapper returns title.

<details>
<summary>Worked solution</summary>

```swift
enum TaskSort: String { case title, createdAt }

struct TaskPreferences {
    private let defaults: UserDefaults
    private let key = "pocketTasks.inbox.sort"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var sort: TaskSort {
        get {
            guard let raw = defaults.string(forKey: key),
                  let value = TaskSort(rawValue: raw) else { return .title }
            return value
        }
        set { defaults.set(newValue.rawValue, forKey: key) }
    }
}
```

The wrapper centralizes the storage key and fallback policy. Keep its use on the intended owner context rather than treating it as a freely shared mutable model. A test can construct UserDefaults(suiteName:) with a unique suite, inject it, and clear that suite afterward without modifying the user's real preferences.

</details>

## Challenge 2: Export and restore a Codable snapshot

**Level:** Core

Implement an actor that writes a small task snapshot as JSON to an injected file URL. Missing files should mean no saved snapshot; malformed files must surface an error.

### Requirements

- Use Codable and Sendable task values.
- Create the parent directory when needed.
- Write atomically.
- Do not swallow decoding or permission errors.

### Starter

```swift
struct SavedTask: Codable, Sendable {
    let id: UUID
    var title: String
    var isDone: Bool
}
// Implement TaskFileStore.
```

<details>
<summary>Hints</summary>

- Data.write(to:options: .atomic) replaces the destination using an intermediate write.
- A missing file and a corrupted existing file should have different outcomes.

</details>

### Acceptance checks

- Save two tasks, load them, and compare IDs and values.
- Load a missing file and get an empty array.
- Replace the file with malformed JSON and verify decoding throws.
- Write to a deliberately unwritable test location and verify the error remains visible.

<details>
<summary>Worked solution</summary>

```swift
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
```

The actor serializes operations through this instance, and atomic replacement reduces partial-write exposure. It does not coordinate unrelated processes or multiple independently created stores writing the same file. Inject a URL under Application Support for durable internal data, or a temporary directory for tests. This snapshot approach suits modest datasets; it is not a substitute for database queries or multi-writer transactions.

</details>

## Challenge 3: Fetch a background snapshot safely

**Level:** Stretch

Add a background fetch method inside LocalTaskStore. Perform all managed-object access on the background context and return only immutable value snapshots.

### Requirements

- Create a background context from the existing container.
- Use context.perform for fetch and property access.
- Return StoredTaskValue values, not NSManagedObject instances.
- Keep this example read-only so no merge is required.

### Starter

```swift
// Add inside LocalTaskStore.
func fetchSnapshotInBackground() async throws -> [StoredTaskValue] {
    // Use a context-owned operation.
    return []
}
```

<details>
<summary>Hints</summary>

- The closure passed to perform is the correct place to touch the fetched objects.
- A Sendable value snapshot can cross back to MainActor.

</details>

### Acceptance checks

- Save tasks first, then verify the background result contains their IDs.
- Confirm the return type exposes no NSManagedObject.
- Explain why unsaved view-context edits are not guaranteed to appear here.
- Describe how a background write would require save and merge behavior.

<details>
<summary>Worked solution</summary>

```swift
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
```

All managed-object reads occur inside the context's perform closure, and only plain values return to the main actor. This fetch sees saved store content, not arbitrary unsaved edits in another context. If adapting it to an import, save on that background context and define how the UI context merges changes. Keep SDK concurrency diagnostics enabled; do not bypass them by marking managed objects unchecked Sendable.

</details>

## Knowledge check

### 1. Which storage is appropriate for a small authentication refresh token?

A. A plaintext UserDefaults string

B. Keychain with an appropriate accessibility policy

C. The app's README

D. A public JSON fixture

<details>
<summary>Answer and explanation</summary>

**B. Keychain with an appropriate accessibility policy**

Keychain is designed for small secrets. Its accessibility and device-migration policies should match the session's requirements.

</details>

### 2. What does modifying an NSManagedObject immediately do?

A. Always commits it to disk

B. Changes tracked state in its context; saving is a separate operation

C. Automatically syncs it to a server

D. Makes it safe to send to any actor

<details>
<summary>Answer and explanation</summary>

**B. Changes tracked state in its context; saving is a separate operation**

A managed-object context tracks changes. Persistence requires a successful save through the configured stack, and remote synchronization is a separate concern.

</details>

### 3. What should cross from a background Core Data context to UI code?

A. An arbitrary live managed object

B. A value snapshot or an object ID that is refetched in the destination context

C. The background context's private queue

D. A pointer to an unsaved property

<details>
<summary>Answer and explanation</summary>

**B. A value snapshot or an object ID that is refetched in the destination context**

Managed objects are context-confined. Pass an appropriate identity or immutable values and access objects only through their owning context.

</details>

### 4. What is a meaningful migration test?

A. Launch only with an empty new store

B. Upgrade a copy of an old populated store and verify its data and relationships

C. Delete all user data first

D. Change model names until compilation succeeds

<details>
<summary>Answer and explanation</summary>

**B. Upgrade a copy of an old populated store and verify its data and relationships**

Migration correctness concerns existing data. Fresh installs do not exercise transformations from older schemas.

</details>

### 5. Why is a cache not automatically an offline source of truth?

A. Caches can only contain images

B. Cached data may be purgeable, incomplete, or older than local edits

C. Caches are always encrypted

D. A cache prevents all network requests

<details>
<summary>Answer and explanation</summary>

**B. Cached data may be purgeable, incomplete, or older than local edits**

Offline guarantees require explicit durability and conflict policies. A disposable response cache alone cannot protect user-created work.

</details>

## Common pitfalls

- Using UserDefaults for large datasets or credentials.
- Forgetting to save a context or ignoring save failures.
- Passing live managed objects across actors or context queues.
- Deleting a shipped store to conceal a migration problem.
- Assuming background writes automatically refresh every in-memory object.
- Overwriting pending local edits with an older remote response.

## PocketTasks milestone: PocketTasks milestone: durable local tasks

1. Add a local task store behind the repository so saved edits survive relaunch.
2. Keep settings in UserDefaults and reserve Keychain for session secrets.
3. Return domain values across the persistence boundary rather than managed objects.
4. Test failure and upgrade scenarios, then document a small offline-sync policy before implementing it.

## Before you move on

- Justify the storage choice for preferences, credentials, cached images, and tasks.
- Create, fetch, toggle, delete, and relaunch using an on-disk store.
- Explain the difference between a context change and a successful persistent save.
- Return values or object IDs across context boundaries.
- Write a short conflict policy for an offline edit and a later server response.
- Describe how you would test the next model version against an old store.

## Official references

- [Core Data](https://developer.apple.com/documentation/coredata)
- [NSPersistentContainer](https://developer.apple.com/documentation/coredata/nspersistentcontainer)
- [NSManagedObjectContext](https://developer.apple.com/documentation/coredata/nsmanagedobjectcontext)
- [UserDefaults](https://developer.apple.com/documentation/foundation/userdefaults)

## Reflection

- What can I now explain without the example?
- What did I build and test in Xcode?
- Which bug or design tradeoff do I want to revisit?
