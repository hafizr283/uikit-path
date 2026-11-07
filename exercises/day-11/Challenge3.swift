// Bound retries for a transient read failure
// Write a wrapper that retries fetchTasks at most twice after the initial attempt, but only for HTTP 503. Preserve all other failures and allow cancellation during the backoff.
// See lessons/day-11.md for requirements, hints, and acceptance checks.
// Independent exercise; do not add all course files to one Xcode target.

func fetchWithRetry(api: TaskAPI) async throws -> [RemoteTask] {
    // Three attempts maximum.
    return []
}
