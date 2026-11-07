// Worked solution: Move presentation logic out of a cell
// The cell now applies values instead of deciding domain meaning. These strings are English for the exercise; production localization should use localized resources and appropriate formatting. Do not set an accessibility label blindly if it would duplicate text already read from accessible subviews.
// Read lessons/day-13.md for any surrounding types or setup.

struct AccessibleTaskRow: Identifiable, Equatable, Sendable {
    let id: UUID
    let title: String
    let status: String
    let accessibilitySummary: String

    init(task: TaskRecord) {
        id = task.id
        title = task.title
        status = task.isDone ? "Completed" : "To do"
        accessibilitySummary = "\(task.title), \(status)"
    }
}
