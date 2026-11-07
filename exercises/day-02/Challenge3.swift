// Capture a snapshot instead of a changing reference
// Create a function that returns a closure describing the current task title. The returned closure must preserve the title at creation time even if the source draft is edited afterward.
// See lessons/day-02.md for requirements, hints, and acceptance checks.
// Independent exercise; do not add all course files to one Xcode target.

final class Draft {
    var title: String
    init(title: String) { self.title = title }
}
func makeSummary(for draft: Draft) -> () -> String {
    // Capture the title now
}
