// Worked solution: Capture a snapshot instead of a changing reference
// The closure captures the title's value at creation time. It does not retain Draft, and later edits do not change the summary. Capturing a value is useful when the behavior explicitly needs a snapshot rather than live state.
// Read lessons/day-02.md for any surrounding types or setup.

final class Draft {
    var title: String
    init(title: String) { self.title = title }
}

func makeSummary(for draft: Draft) -> () -> String {
    { [title = draft.title] in "Draft: \(title)" }
}

func demonstrateSnapshot() {
    let draft = Draft(title: "Original")
    let summary = makeSummary(for: draft)
    draft.title = "Edited"
    print(summary()) // Draft: Original
}
