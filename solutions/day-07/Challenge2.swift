// Worked solution: Handle a long press once
// The component reports intent without deciding what the parent should do. Long press must not be the only way to access an essential action: add a visible button or accessibility custom action when integrating it into a real screen.
// Read lessons/day-07.md for any surrounding types or setup.

import UIKit

@MainActor
final class PressableTaskView: UIView {
    var onLongPress: (@MainActor () -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        installGesture()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        installGesture()
    }

    private func installGesture() {
        let gesture = UILongPressGestureRecognizer(
            target: self, action: #selector(handleLongPress(_:))
        )
        addGestureRecognizer(gesture)
    }

    @objc private func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
        guard recognizer.state == .began else { return }
        onLongPress?()
    }
}
