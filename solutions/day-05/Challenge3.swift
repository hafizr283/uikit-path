// Worked solution: Convert a segmented control into a domain value
// The UI index is an implementation detail; the rest of the app receives a meaningful domain value. If priority is mandatory with no default in your product, return an optional or validation error instead of using this fallback.
// Read lessons/day-05.md for any surrounding types or setup.

import UIKit

enum FormPriority: Int { case low = 0, normal, high }

@MainActor
func makePriorityControl() -> UISegmentedControl {
    let control = UISegmentedControl(items: ["Low", "Normal", "High"])
    control.selectedSegmentIndex = FormPriority.normal.rawValue
    control.accessibilityLabel = "Task priority"
    return control
}

@MainActor
func selectedPriority(in control: UISegmentedControl) -> FormPriority {
    FormPriority(rawValue: control.selectedSegmentIndex) ?? .normal
}
