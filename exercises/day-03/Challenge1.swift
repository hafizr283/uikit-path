// Separate setup from repeated refresh
// Build a controller that creates its label once but updates an appearance count every time the screen is about to appear.
// See lessons/day-03.md for requirements, hints, and acceptance checks.
// Independent exercise; do not add all course files to one Xcode target.

import UIKit
@MainActor
final class VisitViewController: UIViewController {
    private let label = UILabel()
    private var visits = 0
    // Lifecycle overrides
}
