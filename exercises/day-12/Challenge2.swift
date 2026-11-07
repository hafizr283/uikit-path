// Deduplicate an accepted page
// Implement a pure function that merges a page of tasks into existing ordered content. Keep the first-seen position for each ID while allowing the newest payload to replace its content.
// See lessons/day-12.md for requirements, hints, and acceptance checks.
// Independent exercise; do not add all course files to one Xcode target.

func mergePage(existing: [RemoteTask], incoming: [RemoteTask]) -> [RemoteTask] {
    return existing + incoming
}
