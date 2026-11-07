// Worked solution: Repair a text label for Dynamic Type
// A scalable font alone is insufficient if a fixed-height constraint clips it. Self-sizing needs a complete set of vertical relationships and no contradictory fixed height.
// Read lessons/day-18.md for any surrounding types or setup.

import UIKit
@MainActor
func makeTitleLabel() -> UILabel {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .body)
    label.adjustsFontForContentSizeCategory = true
    label.numberOfLines = 0
    label.textColor = .label
    label.textAlignment = .natural
    return label
}
// Remove the fixed height == 20 constraint.
// Pin the label's edges so the cell has a complete vertical chain.
