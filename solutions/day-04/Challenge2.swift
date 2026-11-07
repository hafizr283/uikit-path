// Worked solution: Protect a short status badge
// The badge has stronger preferences, so the title accepts extra width and gives up space first. The parent must still provide a feasible row width. At extreme text sizes, a vertical arrangement may be a better design than insisting on this row.
// Read lessons/day-04.md for any surrounding types or setup.

import UIKit

@MainActor
func makeStatusRow() -> UIStackView {
    let title = UILabel()
    title.text = "A task title that may wrap across several lines"
    title.font = .preferredFont(forTextStyle: .body)
    title.adjustsFontForContentSizeCategory = true
    title.numberOfLines = 0

    let badge = UILabel()
    badge.text = "Done"
    badge.font = .preferredFont(forTextStyle: .caption1)
    badge.adjustsFontForContentSizeCategory = true
    badge.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    badge.setContentCompressionResistancePriority(.required, for: .horizontal)

    let row = UIStackView(arrangedSubviews: [title, badge])
    row.axis = .horizontal
    row.alignment = .firstBaseline
    row.spacing = 12
    return row
}
