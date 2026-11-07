// Handle a long press once
// Add a long-press recognizer to a task view. Emit one callback when the press begins, rather than repeatedly during changed and ended states.
// See lessons/day-07.md for requirements, hints, and acceptance checks.
// Independent exercise; do not add all course files to one Xcode target.

import UIKit
@MainActor
final class PressableTaskView: UIView {
    var onLongPress: (@MainActor () -> Void)?
    // Install recognizer and handle its state
}
