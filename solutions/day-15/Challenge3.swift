// Worked solution: Share one refresh task and invalidate it on logout
// Actor serialization does not extend across an await. The generation prevents the old session from surviving logout, while the attempt guard prevents an older waiter from clearing a later task. The shared task is cancelled by logout, not automatically by one waiting caller. Production token rotation must also guard its persistence step against an old generation.
// Read lessons/day-15.md for any surrounding types or setup.

import Foundation

actor RefreshCoordinator {
    private var inFlight: Task<String, Error>?
    private var generation = 0
    private var attempt = 0
    private let refresh: @Sendable () async throws -> String

    init(refresh: @escaping @Sendable () async throws -> String) {
        self.refresh = refresh
    }

    func token() async throws -> String {
        let startedGeneration = generation
        if inFlight == nil {
            attempt += 1
            let operation = refresh
            inFlight = Task { try await operation() }
        }
        let startedAttempt = attempt
        guard let task = inFlight else {
            throw CancellationError()
        }

        do {
            let result = try await task.value
            guard generation == startedGeneration else {
                throw CancellationError()
            }
            if attempt == startedAttempt { inFlight = nil }
            return result
        } catch {
            if generation == startedGeneration &&
                attempt == startedAttempt {
                inFlight = nil
            }
            throw error
        }
    }

    func logout() {
        generation += 1
        inFlight?.cancel()
        inFlight = nil
    }
}
