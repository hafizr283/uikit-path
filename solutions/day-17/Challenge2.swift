// Worked solution: Prove that a stored callback does not leak
// The test watches the object without owning it. Returning an empty string is only this fixture's fallback; a real callback may be better modeled as an optional result or a no-op. Unowned would require a stronger lifetime guarantee than this stored callback provides.
// Read lessons/day-17.md for any surrounding types or setup.

import XCTest

private final class Editor {
    var title = "Draft"
    var onSave: (() -> String)?

    init() {
        onSave = { [weak self] in
            self?.title ?? ""
        }
    }
}

final class EditorLifetimeTests: XCTestCase {
    func testEditorIsReleased() {
        var editor: Editor? = Editor()
        weak var observed = editor
        XCTAssertEqual(editor?.onSave?(), "Draft")
        editor = nil
        XCTAssertNil(observed)
    }
}
