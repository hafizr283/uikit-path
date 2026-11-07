// Export and restore a Codable snapshot
// Implement an actor that writes a small task snapshot as JSON to an injected file URL. Missing files should mean no saved snapshot; malformed files must surface an error.
// See lessons/day-14.md for requirements, hints, and acceptance checks.
// Independent exercise; do not add all course files to one Xcode target.

struct SavedTask: Codable, Sendable {
    let id: UUID
    var title: String
    var isDone: Bool
}
// Implement TaskFileStore.
