import Foundation

@main
enum ValidationMain {
    static func main() {
        let parser = DeepLinkParser(universalLinkHost: "pockettasks.example")
        let id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        precondition(parser.parse(URL(string: "pockettasks://task/" + id.uuidString)!) == .task(id))
        precondition(parser.parse(URL(string: "https://pockettasks.example/tasks/" + id.uuidString)!) == .task(id))
        for value in [
            "http://pockettasks.example/tasks/" + id.uuidString,
            "https://evil.example/tasks/" + id.uuidString,
            "https://pockettasks.example:444/tasks/" + id.uuidString,
            "https://user@pockettasks.example/tasks/" + id.uuidString,
            "https://pockettasks.example/tasks/" + id.uuidString + "?token=fixture",
            "https://pockettasks.example/tasks/" + id.uuidString + "#fragment",
            "pockettasks://task/not-a-uuid",
            "pockettasks://task/" + id.uuidString + "/extra"
        ] {
            precondition(parser.parse(URL(string: value)!) == nil, "Invalid route accepted: " + value)
        }
    }
}
