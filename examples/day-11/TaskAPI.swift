// Day 11: Networking and API contracts
// Independent educational example. Read lessons/day-11.md for setup.
// Add TaskAPI.swift to an iOS app or a Foundation-capable Swift target. The public JSONPlaceholder endpoint is a third-party demonstration service; network availability and its data are outside this course's control.
// Call try await loadDemoTasks() from the Task started by your UIKit screen. Keep rendering on MainActor and handle cancellation separately from actionable failures.
// RemoteTask includes only the fields the interface uses. JSONPlaceholder's additional userId field can be ignored by Decodable.
// The client builds the query using URLComponents, checks HTTP status, then decodes a success payload. URLError and DecodingError are intentionally preserved rather than collapsed into one unknown error.
// The initializer accepts URLSession and baseURL so later tests can inject a controlled configuration. A production app should point to its authorized backend and implement that backend's exact contract.

import Foundation

struct RemoteTask: Decodable, Sendable, Identifiable {
    let id: Int
    let title: String
    let completed: Bool
}

enum APIError: Error {
    case invalidURL
    case nonHTTPResponse
    case httpStatus(Int)
}

actor TaskAPI {
    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func fetchTasks(limit: Int = 20) async throws -> [RemoteTask] {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent("todos"),
            resolvingAgainstBaseURL: false
        ) else { throw APIError.invalidURL }
        components.queryItems = [
            URLQueryItem(name: "_limit", value: String(max(1, min(limit, 100))))
        ]
        guard let url = components.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        try Task.checkCancellation()
        guard let response = response as? HTTPURLResponse else {
            throw APIError.nonHTTPResponse
        }
        guard (200..<300).contains(response.statusCode) else {
            throw APIError.httpStatus(response.statusCode)
        }
        return try JSONDecoder().decode([RemoteTask].self, from: data)
    }
}

// Call from an async context. This public demo API contains sample data.
// Do not send personal data or production credentials to it.
func loadDemoTasks() async throws -> [RemoteTask] {
    guard let url = URL(string: "https://jsonplaceholder.typicode.com") else {
        throw APIError.invalidURL
    }
    let api = TaskAPI(baseURL: url)
    return try await api.fetchTasks(limit: 5)
}
