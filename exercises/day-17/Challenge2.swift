// Prove that a stored callback does not leak
// A tiny editor owns an onSave closure that reads its title. Fix its ownership and add a test that the editor becomes nil after its last external strong reference is removed.
// See lessons/day-17.md for requirements, hints, and acceptance checks.
// Independent exercise; do not add all course files to one Xcode target.

final class Editor {
    var title = "Draft"
    var onSave: (() -> String)?
    init() {
        onSave = { self.title }
    }
}
