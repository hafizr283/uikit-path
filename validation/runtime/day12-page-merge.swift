import Foundation

@main
enum ValidationMain {
    static func main() {
        let existing = [
            RemoteTask(id: 1, title: "One", completed: false),
            RemoteTask(id: 2, title: "Old two", completed: false)
        ]
        let incoming = [
            RemoteTask(id: 2, title: "New two", completed: true),
            RemoteTask(id: 3, title: "Old three", completed: false),
            RemoteTask(id: 3, title: "New three", completed: true)
        ]
        let result = mergePage(existing: existing, incoming: incoming)
        precondition(result.map(\.id) == [1, 2, 3])
        precondition(result[1].title == "New two" && result[1].completed)
        precondition(result[2].title == "New three" && result[2].completed)
        precondition(mergePage(existing: existing, incoming: []).map(\.id) == [1, 2])
        precondition(mergePage(existing: [], incoming: []).isEmpty)
    }
}
