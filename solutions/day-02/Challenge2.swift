// Worked solution: Use a weak editor delegate
// The parent strongly owns the child. The child points back through a weak delegate, so there is no ownership loop. In real UIKit code, mark UI-facing protocols and classes @MainActor so callback isolation is also explicit.
// Read lessons/day-02.md for any surrounding types or setup.

protocol TitleEditorDelegate: AnyObject {
    func editorDidSave(title: String)
}

final class TitleEditor {
    weak var delegate: (any TitleEditorDelegate)?

    func save(title: String) {
        delegate?.editorDidSave(title: title)
    }
}

final class ParentScreen: TitleEditorDelegate {
    let editor = TitleEditor()

    init() { editor.delegate = self }

    func editorDidSave(title: String) {
        print("Parent received:", title)
    }
}
