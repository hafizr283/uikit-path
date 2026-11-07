import Foundation

@main
enum ValidationMain {
    static func main() async throws {
        let summary = try await loadSummary(from: SummaryService())
        precondition(summary.open == 8 && summary.completed == 3)
        let work = Task { try await loadSummary(from: SummaryService()) }
        work.cancel()
        do {
            _ = try await work.value
            preconditionFailure("Cancelled structured children must propagate cancellation")
        } catch is CancellationError {}
    }
}
