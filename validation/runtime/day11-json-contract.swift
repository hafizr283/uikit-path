import Foundation

@main
enum ValidationMain {
    static func main() throws {
        let task = try decodeFixture()
        precondition(task.id == 7 && task.title == "Read the API contract")
        precondition(task.dueDate == nil)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let dated = Data(#"{"task_id":8,"task_title":"A","due_date":"2026-01-01T00:00:00Z"}"#.utf8)
        let decoded = try decoder.decode(TaskDTO.self, from: dated)
        precondition(decoded.dueDate != nil)
        do {
            _ = try decoder.decode(TaskDTO.self, from: Data(#"{"task_id":7}"#.utf8))
            preconditionFailure("Missing required title must not be accepted")
        } catch DecodingError.keyNotFound {}
        do {
            _ = try decoder.decode(TaskDTO.self, from: Data(#"{"task_id":"seven","task_title":"A"}"#.utf8))
            preconditionFailure("A string id must not be silently coerced")
        } catch DecodingError.typeMismatch {}
    }
}
