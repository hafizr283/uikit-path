// Worked solution: Create diagnostics that cannot accept a raw token
// This helper accepts only a known operation and numeric diagnostics. It reduces opportunities for accidentally dumping a request, though the team still needs a broader logging policy. Public operation names are intentionally non-sensitive; real user identifiers should not be added casually.
// Read lessons/day-20.md for any surrounding types or setup.

import Foundation
import os

enum NetworkOperation: String {
    case fetchTasks
    case saveTask
}

struct NetworkDiagnostics {
    private let logger = Logger(
        subsystem: "com.example.PocketTasks",
        category: "network"
    )

    func completed(
        operation: NetworkOperation,
        status: Int,
        elapsedSeconds: Double
    ) {
        let duration = elapsedSeconds.isFinite
            ? max(0, elapsedSeconds) : 0
        logger.info(
            "operation=\(operation.rawValue, privacy: .public) status=\(status) seconds=\(duration)"
        )
    }
}
