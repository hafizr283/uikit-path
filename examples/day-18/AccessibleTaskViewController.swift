// Day 18: Accessibility & polished user experience
// Independent educational example. Read lessons/day-18.md for setup.
// Add this controller to the app target and present or push it. Xcode can extract the String(localized:) values into a String Catalog when localization is configured.
// Turn on VoiceOver and swipe: the summary is one element and the completion button is another. Activate the button and check its new action and state.
// Increase Dynamic Type, switch Dark Mode, and inspect a right-to-left localization. The semantic colors and directional anchors adapt without manual appearance branching.
// The static summary is intentionally grouped. The separate completion button remains reachable; making the outer stack a single accessibility element would hide that interaction.
// This short screen fits typical sizes, but a longer production detail view should use a scroll view. Test the actual smallest device and largest supported type size instead of assuming the sample's content length.

import UIKit

@MainActor
final class AccessibleTaskViewController: UIViewController {
    private let completionButton = UIButton(type: .system)
    private var isComplete = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "Task details")
        view.backgroundColor = .systemBackground

        let heading = UILabel()
        heading.text = String(localized: "Practice accessible UIKit")
        heading.font = .preferredFont(forTextStyle: .title2)
        heading.adjustsFontForContentSizeCategory = true
        heading.numberOfLines = 0

        let detail = UILabel()
        detail.text = String(localized: "Read the task, then mark it complete.")
        detail.font = .preferredFont(forTextStyle: .body)
        detail.adjustsFontForContentSizeCategory = true
        detail.textColor = .secondaryLabel
        detail.numberOfLines = 0

        let summary = UIStackView(arrangedSubviews: [heading, detail])
        summary.axis = .vertical
        summary.spacing = 8
        summary.isAccessibilityElement = true
        summary.accessibilityTraits = .staticText
        summary.accessibilityLabel = [
            heading.text, detail.text
        ].compactMap { $0 }.joined(separator: ". ")

        completionButton.accessibilityIdentifier = "task.completeButton"
        completionButton.addAction(UIAction { [weak self] _ in
            self?.toggleCompletion()
        }, for: .touchUpInside)
        updateButton()

        let stack = UIStackView(arrangedSubviews: [
            summary, completionButton
        ])
        stack.axis = .vertical
        stack.spacing = 24
        stack.directionalLayoutMargins = .init(
            top: 24, leading: 24, bottom: 24, trailing: 24
        )
        stack.isLayoutMarginsRelativeArrangement = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor
            ),
            stack.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor
            ),
            stack.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor
            ),
            completionButton.heightAnchor.constraint(
                greaterThanOrEqualToConstant: 44
            )
        ])
    }

    private func toggleCompletion() {
        isComplete.toggle()
        updateButton()
        UIAccessibility.post(
            notification: .announcement,
            argument: isComplete
                ? String(localized: "Task completed")
                : String(localized: "Task marked incomplete")
        )
    }

    private func updateButton() {
        var configuration = UIButton.Configuration.filled()
        configuration.title = isComplete
            ? String(localized: "Mark incomplete")
            : String(localized: "Mark complete")
        configuration.image = UIImage(
            systemName: isComplete ? "checkmark.circle.fill" : "circle"
        )
        configuration.imagePadding = 8
        completionButton.configuration = configuration
        completionButton.accessibilityValue = isComplete
            ? String(localized: "Completed")
            : String(localized: "Not completed")
    }
}
