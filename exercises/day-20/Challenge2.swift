// Create diagnostics that cannot accept a raw token
// Define a tiny network logging API that accepts a known operation, status code, and duration. Its public interface should have no parameter for an Authorization header, request body, or arbitrary URL.
// See lessons/day-20.md for requirements, hints, and acceptance checks.
// Independent exercise; do not add all course files to one Xcode target.

import Foundation
import os

enum NetworkOperation: String {
    case fetchTasks, saveTask
}
// Add a logger that accepts only safe operational fields.
