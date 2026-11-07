// Validate environment configuration
// Read an API_BASE_URL string from an injected configuration dictionary and reject missing or non-HTTPS values. Keep this separate from the live Bundle so tests can supply fixtures.
// See lessons/day-20.md for requirements, hints, and acceptance checks.
// Independent exercise; do not add all course files to one Xcode target.

import Foundation
enum ConfigurationError: Error { case invalidBaseURL }
struct AppConfiguration {
    let apiBaseURL: URL
    init(values: [String: String]) throws {
        // Validate API_BASE_URL.
        throw ConfigurationError.invalidBaseURL
    }
}
