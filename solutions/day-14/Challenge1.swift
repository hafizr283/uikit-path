// Worked solution: Store a preference with a safe default
// The wrapper centralizes the storage key and fallback policy. Keep its use on the intended owner context rather than treating it as a freely shared mutable model. A test can construct UserDefaults(suiteName:) with a unique suite, inject it, and clear that suite afterward without modifying the user's real preferences.
// Read lessons/day-14.md for any surrounding types or setup.

enum TaskSort: String { case title, createdAt }

struct TaskPreferences {
    private let defaults: UserDefaults
    private let key = "pocketTasks.inbox.sort"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var sort: TaskSort {
        get {
            guard let raw = defaults.string(forKey: key),
                  let value = TaskSort(rawValue: raw) else { return .title }
            return value
        }
        set { defaults.set(newValue.rawValue, forKey: key) }
    }
}
