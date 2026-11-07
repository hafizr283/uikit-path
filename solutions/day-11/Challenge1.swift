// Worked solution: Map snake_case JSON without optionalizing everything
// The type documents which fields are guaranteed and which may be absent. For a backend with fractional timestamps or multiple date representations, implement and test that specific format instead of assuming every ISO-like string is accepted by one strategy.
// Read lessons/day-11.md for any surrounding types or setup.

struct TaskDTO: Decodable, Sendable {
    let id: Int
    let title: String
    let dueDate: Date?

    enum CodingKeys: String, CodingKey {
        case id = "task_id"
        case title = "task_title"
        case dueDate = "due_date"
    }
}

func decodeFixture() throws -> TaskDTO {
    let data = Data(#"{"task_id":7,"task_title":"Read the API contract"}"#.utf8)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try decoder.decode(TaskDTO.self, from: data)
}
