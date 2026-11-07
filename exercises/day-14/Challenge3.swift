// Fetch a background snapshot safely
// Add a background fetch method inside LocalTaskStore. Perform all managed-object access on the background context and return only immutable value snapshots.
// See lessons/day-14.md for requirements, hints, and acceptance checks.
// Independent exercise; do not add all course files to one Xcode target.

// Add inside LocalTaskStore.
func fetchSnapshotInBackground() async throws -> [StoredTaskValue] {
    // Use a context-owned operation.
    return []
}
