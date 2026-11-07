// Extract a navigation flow
// Create a small coordinator that owns a navigation controller and pushes a task detail controller when a list emits a task-selection closure.
// See lessons/day-13.md for requirements, hints, and acceptance checks.
// Independent exercise; do not add all course files to one Xcode target.

// UIKit routing exercise; use these small standalone placeholder controllers.
@MainActor
final class TaskListScreen: UIViewController {
    var onSelect: ((UUID) -> Void)?
}
