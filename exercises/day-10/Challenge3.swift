// Reject stale search results
// Implement a MainActor search model with debounce, cancellation, and a generation check. The latest query must win even when earlier work finishes later.
// See lessons/day-10.md for requirements, hints, and acceptance checks.
// Independent exercise; do not add all course files to one Xcode target.

actor TaskSearchService {
    func search(_ query: String) async throws -> [String] {
        try await Task.sleep(for: .milliseconds(300))
        return ["Result for \(query)"]
    }
}
// Implement SearchModel.
