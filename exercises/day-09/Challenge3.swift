// Show one task in two distinct placements
// Design identifiers for a task that appears in both Pinned and All sections. Build a snapshot without using the same item identifier twice.
// See lessons/day-09.md for requirements, hints, and acceptance checks.
// Independent exercise; do not add all course files to one Xcode target.

enum BoardSection: Hashable { case pinned, all }
struct Placement: Hashable {
    // Add identity components.
}
