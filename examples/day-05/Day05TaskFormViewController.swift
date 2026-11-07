// Day 05: Forms, controls, scrolling, and the keyboard
// Independent educational example. Read lessons/day-05.md for setup.
// Add this controller to the UIKit app and present it inside a navigation controller so its Done item is visible.
// The outer scroll view's viewport ends at the keyboard layout guide. Its content remains independently sized by the stack's complete edge constraints.
// The width equality prevents horizontal scrolling, while the stack's arranged content determines its height.
// Title edits update validity and helper text. Save validates again and reports that the draft is valid; it does not claim to persist data.
// Press Next in the title field to move to notes. Use Done or interactive scrolling to dismiss the keyboard, then repeat with large text and a short device.

import UIKit

@MainActor
final class TaskFormViewController: UIViewController, UITextFieldDelegate {
    private let titleField = UITextField()
    private let notesView = UITextView()
    private let helperLabel = UILabel()
    private let saveButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "New task"
        view.backgroundColor = .systemBackground

        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.keyboardDismissMode = .interactive
        scroll.contentInsetAdjustmentBehavior = .never
        view.addSubview(scroll)

        let titleLabel = UILabel()
        titleLabel.text = "Task title"
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true

        titleField.borderStyle = .roundedRect
        titleField.placeholder = "What needs to get done?"
        titleField.accessibilityLabel = "Task title"
        titleField.font = .preferredFont(forTextStyle: .body)
        titleField.adjustsFontForContentSizeCategory = true
        titleField.returnKeyType = .next
        titleField.delegate = self
        titleField.addTarget(self, action: #selector(titleChanged), for: .editingChanged)

        let notesLabel = UILabel()
        notesLabel.text = "Notes (optional)"
        notesLabel.font = .preferredFont(forTextStyle: .headline)
        notesLabel.adjustsFontForContentSizeCategory = true

        notesView.font = .preferredFont(forTextStyle: .body)
        notesView.adjustsFontForContentSizeCategory = true
        notesView.accessibilityLabel = "Task notes"
        notesView.backgroundColor = .secondarySystemBackground
        notesView.layer.cornerRadius = 10
        notesView.isScrollEnabled = false

        helperLabel.font = .preferredFont(forTextStyle: .footnote)
        helperLabel.adjustsFontForContentSizeCategory = true
        helperLabel.numberOfLines = 0

        var config = UIButton.Configuration.filled()
        config.title = "Save task"
        saveButton.configuration = config
        saveButton.addAction(UIAction { [weak self] _ in self?.save() },
                             for: .touchUpInside)

        let form = UIStackView(arrangedSubviews: [
            titleLabel, titleField, notesLabel, notesView, helperLabel, saveButton
        ])
        form.axis = .vertical
        form.spacing = 12
        form.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(form)

        let content = scroll.contentLayoutGuide
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
            form.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
            form.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            form.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            form.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -20),
            form.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -40),
            titleField.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            notesView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),
            saveButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Done", primaryAction: UIAction { [weak self] _ in
                self?.view.endEditing(true)
            }
        )
        titleChanged()
    }

    private var cleanTitle: String {
        (titleField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @objc private func titleChanged() {
        let count = cleanTitle.count
        let valid = count > 0 && count <= 80
        saveButton.isEnabled = valid
        helperLabel.text = count == 0
            ? "Enter a title to enable Save."
            : "\(count)/80 characters"
        helperLabel.textColor = count > 80 ? .systemRed : .secondaryLabel
    }

    private func save() {
        guard !cleanTitle.isEmpty, cleanTitle.count <= 80 else {
            titleChanged()
            return
        }
        view.endEditing(true)
        helperLabel.text = "Draft validated: \(cleanTitle)"
        helperLabel.textColor = .label
        // Add repository persistence in Day 14; this example only validates a draft.
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        notesView.becomeFirstResponder()
        return true
    }
}
