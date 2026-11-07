// Worked solution: Reject stale search results
// The request handle reduces unnecessary work, while the generation check is the acceptance rule for results. Bind onResults from a controller using a weak controller capture, and call cancel when the owning screen no longer needs results. Keeping the entire model on MainActor also makes generation comparisons and delivery one uninterrupted state transition.
// Read lessons/day-10.md for any surrounding types or setup.

@MainActor
final class SearchModel {
    private let service = TaskSearchService()
    private var request: Task<Void, Never>?
    private var generation = 0
    var onResults: (([String]) -> Void)?
    var onError: ((String) -> Void)?

    func search(_ query: String) {
        generation += 1
        let current = generation
        request?.cancel()
        let service = service
        request = Task { [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(250))
                let results = try await service.search(query)
                try Task.checkCancellation()
                guard let self, current == self.generation else { return }
                self.onResults?(results)
            } catch is CancellationError {
            } catch {
                guard let self, current == self.generation else { return }
                self.onError?("Search failed. Please retry.")
            }
        }
    }

    func cancel() {
        generation += 1
        request?.cancel()
        request = nil
    }
}
