// Worked solution: Bound retries for a transient read failure
// This intentionally small policy is easy to audit: only 503 is retried, there are at most three attempts, and waiting cooperates with cancellation. A production policy may also honor Retry-After and add jitter, but should retain explicit bounds and distinguish safe reads from writes.
// Read lessons/day-11.md for any surrounding types or setup.

func fetchWithRetry(api: TaskAPI) async throws -> [RemoteTask] {
    var failures = 0
    while true {
        try Task.checkCancellation()
        do {
            return try await api.fetchTasks()
        } catch APIError.httpStatus(503) {
            failures += 1
            guard failures < 3 else { throw APIError.httpStatus(503) }
            try await Task.sleep(for: .milliseconds(250 * failures))
        } catch {
            throw error
        }
    }
}
