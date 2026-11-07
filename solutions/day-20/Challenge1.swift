// Worked solution: Validate environment configuration
// Injecting a dictionary keeps parsing deterministic. Configuration validation is separate from a credential-origin allowlist: an app that attaches tokens must still enforce the trusted server boundary from Day 15. A configured URL is public client configuration, not a secret.
// Read lessons/day-20.md for any surrounding types or setup.

import Foundation

enum ConfigurationError: Error {
    case invalidBaseURL
}

struct AppConfiguration {
    let apiBaseURL: URL

    init(values: [String: String]) throws {
        guard let raw = values["API_BASE_URL"],
              let parts = URLComponents(string: raw),
              parts.scheme?.lowercased() == "https",
              let host = parts.host, !host.isEmpty,
              parts.user == nil, parts.password == nil,
              parts.query == nil, parts.fragment == nil,
              let url = parts.url else {
            throw ConfigurationError.invalidBaseURL
        }
        apiBaseURL = url
    }
}
