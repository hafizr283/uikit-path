// Day 04: Auto Layout without guesswork
// Independent educational example. Read lessons/day-04.md for setup.
// Add this file to the UIKit target, then use TaskSummaryViewController() as the root of your navigation controller.
// The stack's width comes from its leading and trailing constraints. That width allows both multiline labels to derive their heights.
// The stack's vertical size comes from its arranged subviews, spacing, and margins. There is no fixed card height to fight larger text.
// The filled button has a minimum touch height, not a forced text-label height. Its action changes only its state; the layout handles the new title.
// Test large text sizes. This single-card example does not scroll; if the entire card becomes taller than the screen, the next day's scroll-container pattern is the correct extension rather than shrinking accessible text.

import UIKit

@MainActor
final class TaskSummaryViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Task summary"
        view.backgroundColor = .systemGroupedBackground

        let heading = UILabel()
        heading.text = "Practice layouts that adapt"
        heading.font = .preferredFont(forTextStyle: .title2)
        heading.adjustsFontForContentSizeCategory = true
        heading.numberOfLines = 0

        let detail = UILabel()
        detail.text = "Try a longer title, rotate the simulator, and increase text size."
        detail.font = .preferredFont(forTextStyle: .body)
        detail.adjustsFontForContentSizeCategory = true
        detail.textColor = .secondaryLabel
        detail.numberOfLines = 0

        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Mark complete"
        button.configuration = configuration
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        button.addAction(UIAction { [weak button] _ in
            button?.configuration?.title = "Completed"
            button?.isEnabled = false
        }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [heading, detail, button])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 20, leading: 20, bottom: 20, trailing: 20
        )
        stack.backgroundColor = .secondarySystemGroupedBackground
        stack.layer.cornerRadius = 18
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: safe.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -20)
        ])
    }
}
