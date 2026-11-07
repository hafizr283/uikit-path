import Foundation

@main
enum ValidationMain {
    static func main() {
        let callbacks = SaveCallbacks()
        var editor: TaskEditor? = TaskEditor(callbacks: callbacks)
        weak var observer = editor
        editor?.connect()
        precondition(observer != nil)
        callbacks.onSave?()
        editor = nil
        precondition(observer == nil, "The callback must not keep the editor alive")
        callbacks.onSave?()
        callbacks.onSave = nil
    }
}
