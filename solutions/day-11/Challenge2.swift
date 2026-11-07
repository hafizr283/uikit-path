// Worked solution: Encode a POST body
// Content-Type describes the body being sent; Accept describes the desired response format. JSONPlaceholder acknowledges sample writes but does not persist them as your real backend would. Do not conclude that a later GET must contain this task. Test production persistence only against the intended server contract.
// Read lessons/day-11.md for any surrounding types or setup.

// Add alongside the other request models.
struct NewTask: Encodable, Sendable {
    let title: String
    let completed: Bool
    let userId: Int
}

enum TaskInputError: Error { case blankTitle }

// Add this method inside TaskAPI.
func createTask(title: String) async throws -> RemoteTask {
    let cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !cleaned.isEmpty else { throw TaskInputError.blankTitle }
    var request = URLRequest(url: baseURL.appendingPathComponent("todos"))
    request.httpMethod = "POST"
    request.timeoutInterval = 15
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.httpBody = try JSONEncoder().encode(
        NewTask(title: cleaned, completed: false, userId: 1)
    )
    let (data, response) = try await session.data(for: request)
    try Task.checkCancellation()
    guard let response = response as? HTTPURLResponse else {
        throw APIError.nonHTTPResponse
    }
    guard (200..<300).contains(response.statusCode) else {
        throw APIError.httpStatus(response.statusCode)
    }
    return try JSONDecoder().decode(RemoteTask.self, from: data)
}
