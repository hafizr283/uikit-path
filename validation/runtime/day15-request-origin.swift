import Foundation

@main
enum ValidationMain {
    static func main() throws {
        let accepted = try authorizedGET(
            url: URL(string: "https://api.example.com/tasks")!, token: "fixture-only"
        )
        precondition(accepted.httpMethod == "GET")
        precondition(accepted.value(forHTTPHeaderField: "Authorization") == "Bearer fixture-only")
        for value in [
            "http://api.example.com/tasks",
            "https://evil.example/tasks",
            "https://api.example.com.evil.example/tasks",
            "https://user:password@api.example.com/tasks",
            "https://api.example.com:8443/tasks"
        ] {
            do {
                _ = try authorizedGET(url: URL(string: value)!, token: "fixture-only")
                preconditionFailure("Rejected origin was accepted: " + value)
            } catch RequestError.untrustedURL {}
        }
        _ = try authorizedGET(url: URL(string: "https://api.example.com:443/tasks")!, token: "fixture-only")
    }
}
