// Day 02: ARC, ownership, and memory leaks
// Independent educational example. Read lessons/day-02.md for setup.
// Paste the complete code into a Swift playground and invoke runDay02Example(). It deliberately uses Foundation and ordinary classes so the ownership graph is visible without UIKit setup.
// The local callbacks variable owns the callback store. While editor is non-nil, the editor also owns that same store.
// The store owns its closure, but the closure only weakly references the editor. There is no strong path back to the editor.
// Setting editor to nil removes the editor's final strong owner. Its deinit message appears even though the callback store remains alive.
// Invoke the stored callback after release: the guard handles nil and does not access a destroyed object. For comparison, temporarily capture self strongly, observe the missing deinit before cleanup, then restore the weak version.

import Foundation

final class SaveCallbacks {
    var onSave: (() -> Void)?
}

final class TaskEditor {
    private let callbacks: SaveCallbacks
    private var title = "Review ARC"

    init(callbacks: SaveCallbacks) {
        self.callbacks = callbacks
    }

    func connect() {
        callbacks.onSave = { [weak self] in
            guard let self else {
                print("Editor is gone; ignore the callback")
                return
            }
            print("Saving:", self.title)
        }
    }

    deinit {
        print("TaskEditor released")
    }
}

func runDay02Example() {
    let callbacks = SaveCallbacks()
    var editor: TaskEditor? = TaskEditor(callbacks: callbacks)
    editor?.connect()
    callbacks.onSave?()
    editor = nil
    callbacks.onSave?()
    callbacks.onSave = nil
}
