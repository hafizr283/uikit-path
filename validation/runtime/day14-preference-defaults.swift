import Foundation

@main
enum ValidationMain {
    static func main() {
        let suite = "UIKitPath.Validation." + UUID().uuidString
        guard let defaults = UserDefaults(suiteName: suite) else {
            preconditionFailure("Cannot create isolated preferences suite")
        }
        defer { defaults.removePersistentDomain(forName: suite) }
        var preferences = TaskPreferences(defaults: defaults)
        precondition(preferences.sort == .title)
        preferences.sort = .createdAt
        let reopened = TaskPreferences(defaults: defaults)
        precondition(reopened.sort == .createdAt)
        defaults.set("obsolete-sort", forKey: "pocketTasks.inbox.sort")
        precondition(preferences.sort == .title)
    }
}
