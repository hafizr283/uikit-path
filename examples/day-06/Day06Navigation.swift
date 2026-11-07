// Day 06: Navigation and communication between screens
// Independent educational example. Read lessons/day-06.md for setup.
// Add both classes to the UIKit target and set the scene root to UINavigationController(rootViewController: TaskHomeViewController()). The initializer is programmatic; this editor is not designed for storyboard decoding.
// Tap Edit. The current title is passed by value through the editor's initializer, so the original screen has valid data before editing begins.
// Change the text and tap Back. Nothing calls onSave, so the original title remains unchanged.
// Edit again and tap Save. Validation succeeds, the callback updates the parent, and the editor pops itself.
// The callback captures the parent weakly. This example updates in-memory screen state only; saving to a repository and handling failure will be added later.

import UIKit

@MainActor
final class TaskHomeViewController: UIViewController {
    private var taskTitle = "Practice navigation"
    private let titleLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "PocketTasks"
        view.backgroundColor = .systemBackground
        titleLabel.text = taskTitle
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            titleLabel.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Edit", primaryAction: UIAction { [weak self] _ in
                self?.showEditor()
            }
        )
    }

    private func showEditor() {
        let editor = TaskTitleEditorViewController(initialTitle: taskTitle)
        editor.onSave = { [weak self] newTitle in
            self?.taskTitle = newTitle
            self?.titleLabel.text = newTitle
        }
        navigationController?.pushViewController(editor, animated: true)
    }
}

@MainActor
final class TaskTitleEditorViewController: UIViewController {
    var onSave: (@MainActor (String) -> Void)?
    private let initialTitle: String
    private let field = UITextField()
    private let errorLabel = UILabel()

    init(initialTitle: String) {
        self.initialTitle = initialTitle
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Use init(initialTitle:) for this programmatic example")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Edit title"
        view.backgroundColor = .systemBackground
        field.text = initialTitle
        field.borderStyle = .roundedRect
        field.accessibilityLabel = "Task title"
        field.font = .preferredFont(forTextStyle: .body)
        field.adjustsFontForContentSizeCategory = true
        errorLabel.textColor = .systemRed
        errorLabel.numberOfLines = 0
        let stack = UIStackView(arrangedSubviews: [field, errorLabel])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            field.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Save", primaryAction: UIAction { [weak self] _ in
                self?.save()
            }
        )
    }

    private func save() {
        let clean = (field.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, clean.count <= 80 else {
            errorLabel.text = "Enter a title between 1 and 80 characters."
            return
        }
        onSave?(clean)
        navigationController?.popViewController(animated: true)
    }
}
