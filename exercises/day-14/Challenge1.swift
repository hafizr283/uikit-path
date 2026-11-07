// Store a preference with a safe default
// Create a small UserDefaults wrapper for the inbox sort mode. Unknown or absent stored values must fall back to title sorting.
// See lessons/day-14.md for requirements, hints, and acceptance checks.
// Independent exercise; do not add all course files to one Xcode target.

enum TaskSort: String { case title, createdAt }
struct TaskPreferences {
    // Inject defaults and expose sort.
}
