// Remove repeated membership scans without changing behavior
// A list filters 20,000 tasks by thousands of selected IDs. Its implementation calls selectedIDs.contains inside every filter iteration. Replace repeated linear scans, preserve source order, and benchmark a fixed fixture.
// See lessons/day-17.md for requirements, hints, and acceptance checks.
// Independent exercise; do not add all course files to one Xcode target.

struct Item: Equatable {
    let id: Int
}
func selectedItems(_ items: [Item], ids: [Int]) -> [Item] {
    items.filter { ids.contains($0.id) }
}
