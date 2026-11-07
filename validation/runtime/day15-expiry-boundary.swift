import Foundation

@main
enum ValidationMain {
    static func main() {
        let now = Date(timeIntervalSince1970: 1_000)
        precondition(!AccessCredential(value: "fixture", expiresAt: now.addingTimeInterval(31)).needsRefresh(at: now))
        precondition(AccessCredential(value: "fixture", expiresAt: now.addingTimeInterval(30)).needsRefresh(at: now))
        precondition(AccessCredential(value: "fixture", expiresAt: now.addingTimeInterval(-1)).needsRefresh(at: now))
    }
}
