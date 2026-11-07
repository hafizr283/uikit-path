import UIKit

@MainActor
final class TaskEditorViewController: UIViewController {
    private let repository: TaskRepository
    private let taskID: UUID?
    private let titleField = UITextField()
    private let notesField = UITextView()
    var onSave: (() -> Void)?

    init(repository: TaskRepository, taskID: UUID? = nil) {
        self.repository = repository
        self.taskID = taskID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Use init(repository:taskID:)")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = taskID == nil ? "New task" : "Edit task"
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel, target: self, action: #selector(cancel)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save, target: self, action: #selector(save)
        )
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = "task.save"

        titleField.borderStyle = .roundedRect
        titleField.font = .preferredFont(forTextStyle: .body)
        titleField.adjustsFontForContentSizeCategory = true
        titleField.placeholder = "What needs doing?"
        titleField.accessibilityLabel = "Task title"
        titleField.accessibilityIdentifier = "task.titleField"
        titleField.autocapitalizationType = .sentences

        notesField.font = .preferredFont(forTextStyle: .body)
        notesField.adjustsFontForContentSizeCategory = true
        notesField.backgroundColor = .secondarySystemBackground
        notesField.layer.cornerRadius = 12
        notesField.textContainerInset = .init(top: 12, left: 8, bottom: 12, right: 8)
        notesField.accessibilityLabel = "Task notes"
        notesField.accessibilityIdentifier = "task.notesField"

        if let taskID, let item = repository.item(id: taskID) {
            titleField.text = item.title
            notesField.text = item.notes
        }

        let scroll = UIScrollView()
        scroll.keyboardDismissMode = .interactive
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        let stack = UIStackView(arrangedSubviews: [
            label("Title · up to 80 characters"), titleField,
            label("Notes · optional"), notesField
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
            stack.topAnchor.constraint(
                equalTo: scroll.contentLayoutGuide.topAnchor, constant: 24
            ),
            stack.leadingAnchor.constraint(
                equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 24
            ),
            stack.trailingAnchor.constraint(
                equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -24
            ),
            stack.bottomAnchor.constraint(
                equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24
            ),
            stack.widthAnchor.constraint(
                equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -48
            ),
            titleField.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            notesField.heightAnchor.constraint(equalToConstant: 200)
        ])
    }

    private func label(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }

    @objc private func cancel() {
        dismiss(animated: true)
    }

    @objc private func save() {
        let title = titleField.text ?? ""
        let notes = notesField.text ?? ""
        setSaving(true)
        Task { [weak self] in
            guard let self else { return }
            do {
                if let taskID {
                    try await repository.update(id: taskID, title: title, notes: notes)
                } else {
                    try await repository.add(title: title, notes: notes)
                }
                onSave?()
                dismiss(animated: true)
            } catch {
                setSaving(false)
                let alert = UIAlertController(
                    title: "Could not save",
                    message: error.localizedDescription,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
            }
        }
    }

    private func setSaving(_ saving: Bool) {
        navigationItem.leftBarButtonItem?.isEnabled = !saving
        navigationItem.rightBarButtonItem?.isEnabled = !saving
        isModalInPresentation = saving
        titleField.isEnabled = !saving
        notesField.isEditable = !saving
    }
}
