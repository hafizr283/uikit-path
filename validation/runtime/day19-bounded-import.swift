import Foundation

@main
enum ValidationMain {
    static func main() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("UIKitPath-Import-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("notes.txt")
        try Data("Hello UIKit".utf8).write(to: file)
        let greeting = try importNotes(from: file)
        precondition(greeting == "Hello UIKit")
        let boundary = Data(repeating: 65, count: 64 * 1024)
        try boundary.write(to: file)
        let atLimit = try importNotes(from: file)
        precondition(atLimit.utf8.count == boundary.count)
        try Data(repeating: 65, count: 64 * 1024 + 1).write(to: file)
        do {
            _ = try importNotes(from: file)
            preconditionFailure("An oversized file must be rejected")
        } catch ImportError.tooLarge {}
        try Data([0xFF, 0xFE, 0xFF]).write(to: file)
        do {
            _ = try importNotes(from: file)
            preconditionFailure("Invalid UTF-8 must be rejected")
        } catch ImportError.invalidText {}
    }
}
