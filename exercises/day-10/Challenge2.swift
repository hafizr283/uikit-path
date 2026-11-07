// Load independent counts concurrently
// Write a summary loader that fetches open and completed counts concurrently from an actor service, then returns a Sendable value.
// See lessons/day-10.md for requirements, hints, and acceptance checks.
// Independent exercise; do not add all course files to one Xcode target.

struct TaskSummary: Sendable {
    let open: Int
    let completed: Int
}
// Implement a service and summary loader.
