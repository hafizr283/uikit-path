// Use a weak editor delegate
// Implement a child editor that reports a saved title to a parent without owning the parent. Keep the example independent of UIKit so you can inspect its lifetime in a playground.
// See lessons/day-02.md for requirements, hints, and acceptance checks.
// Independent exercise; do not add all course files to one Xcode target.

protocol TitleEditorDelegate: AnyObject {
    func editorDidSave(title: String)
}
final class TitleEditor {
    // Delegate and save method
}
