// Day 07: Reusable UIKit components and interaction
// Independent educational example. Read lessons/day-07.md for setup.
// Add the file to the UIKit app and use CardDemoViewController as a navigation root. TaskCardView is a view component, not another view controller.
// The configuration contains all data needed to render the card. configure explicitly sets both empty and nonempty notes behavior and both completion states.
// The card emits onToggle but never edits a model, saves a database record, or performs navigation. The controller changes its state and asks the card to render again.
// Both initializers call one setup method. This supports programmatic creation and basic storyboard/XIB unarchiving, provided Interface Builder is not also duplicating the component's internally created content.
// Toggle several times, increase text size, and configure the same card with different notes. Its view hierarchy stays the same while the content changes.

import UIKit

struct TaskCardContent {
    let title: String
    let notes: String
    let isComplete: Bool
}

@MainActor
final class TaskCardView: UIView {
    var onToggle: (@MainActor () -> Void)?
    private let titleLabel = UILabel()
    private let notesLabel = UILabel()
    private let toggleButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    private func setUp() {
        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = 18
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0
        titleLabel.accessibilityTraits.insert(.header)
        notesLabel.font = .preferredFont(forTextStyle: .body)
        notesLabel.adjustsFontForContentSizeCategory = true
        notesLabel.textColor = .secondaryLabel
        notesLabel.numberOfLines = 0
        toggleButton.addAction(UIAction { [weak self] _ in
            self?.onToggle?()
        }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [
            titleLabel, notesLabel, toggleButton
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            toggleButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }

    func configure(with content: TaskCardContent) {
        titleLabel.text = content.title
        notesLabel.text = content.notes
        notesLabel.isHidden = content.notes.isEmpty
        var config = UIButton.Configuration.tinted()
        config.title = content.isComplete ? "Mark unfinished" : "Mark complete"
        config.image = UIImage(systemName:
            content.isComplete ? "checkmark.circle.fill" : "circle"
        )
        config.imagePadding = 8
        toggleButton.configuration = config
        toggleButton.accessibilityLabel = "Toggle task completion"
        toggleButton.accessibilityValue = content.isComplete ? "Complete" : "Unfinished"
    }
}

@MainActor
final class CardDemoViewController: UIViewController {
    private let card = TaskCardView(frame: .zero)
    private var isComplete = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Reusable task card"
        view.backgroundColor = .systemGroupedBackground
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            card.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            card.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20)
        ])
        card.onToggle = { [weak self] in
            guard let self else { return }
            self.isComplete.toggle()
            self.render()
        }
        render()
    }

    private func render() {
        card.configure(with: TaskCardContent(
            title: "Build one reusable component",
            notes: "The controller owns the state; the card renders it.",
            isComplete: isComplete
        ))
    }
}
