import UIKit

@MainActor
final class TaskDetailViewController: UIViewController {
    private let repository: TaskRepository
    private let taskID: UUID
    private let heading = UILabel()
    private let notes = UILabel()
    private let status = UILabel()
    private let completeButton = UIButton(type: .system)
    private let deleteButton = UIButton(type: .system)

    init(repository: TaskRepository, taskID: UUID) {
        self.repository = repository
        self.taskID = taskID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Use init(repository:taskID:)")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Task details"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .edit, target: self, action: #selector(edit)
        )
        view.backgroundColor = .systemBackground
        for label in [heading, notes, status] {
            label.numberOfLines = 0
            label.adjustsFontForContentSizeCategory = true
        }
        heading.font = .preferredFont(forTextStyle: .title2)
        notes.font = .preferredFont(forTextStyle: .body)
        status.font = .preferredFont(forTextStyle: .subheadline)
        status.textColor = .secondaryLabel

        completeButton.addTarget(
            self, action: #selector(toggle), for: .touchUpInside
        )
        completeButton.accessibilityIdentifier = "task.toggle"
        var deleteConfig = UIButton.Configuration.tinted()
        deleteConfig.title = "Delete task"
        deleteConfig.baseForegroundColor = .systemRed
        deleteButton.configuration = deleteConfig
        deleteButton.addTarget(
            self, action: #selector(confirmDelete), for: .touchUpInside
        )
        deleteButton.accessibilityIdentifier = "task.delete"

        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        let stack = UIStackView(arrangedSubviews: [
            heading, status, notes, completeButton, deleteButton
        ])
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
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
            completeButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            deleteButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
        render()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        render()
    }

    private func render() {
        guard let item = repository.item(id: taskID) else {
            heading.text = "Task no longer available"
            notes.text = nil
            status.text = nil
            completeButton.isEnabled = false
            deleteButton.isEnabled = false
            navigationItem.rightBarButtonItem?.isEnabled = false
            return
        }
        heading.text = item.title
        notes.text = item.notes.isEmpty ? "No notes added." : item.notes
        status.text = item.isComplete ? "Completed" : "Open"
        var configuration = UIButton.Configuration.filled()
        configuration.title = item.isComplete ? "Mark incomplete" : "Mark complete"
        configuration.image = UIImage(
            systemName: item.isComplete ? "arrow.uturn.backward" : "checkmark"
        )
        configuration.imagePadding = 8
        completeButton.configuration = configuration
        completeButton.accessibilityValue = status.text
    }

    @objc private func edit() {
        let editor = TaskEditorViewController(repository: repository, taskID: taskID)
        editor.onSave = { [weak self] in self?.render() }
        present(UINavigationController(rootViewController: editor), animated: true)
    }

    @objc private func toggle() {
        performChange {
            try await self.repository.toggle(id: self.taskID)
        }
    }

    @objc private func confirmDelete() {
        let alert = UIAlertController(
            title: "Delete this task?",
            message: "This removes the task from this device.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) {
            [weak self] _ in
            self?.performChange(delete: true) {
                guard let self else { return }
                try await self.repository.delete(id: self.taskID)
            }
        })
        present(alert, animated: true)
    }

    private func performChange(
        delete: Bool = false,
        operation: @escaping @MainActor () async throws -> Void
    ) {
        completeButton.isEnabled = false
        deleteButton.isEnabled = false
        navigationItem.rightBarButtonItem?.isEnabled = false
        Task { [weak self] in
            guard let self else { return }
            do {
                try await operation()
                if delete {
                    navigationController?.popViewController(animated: true)
                } else {
                    render()
                }
            } catch {
                let alert = UIAlertController(
                    title: "Could not save change",
                    message: error.localizedDescription,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
            }
            completeButton.isEnabled = true
            deleteButton.isEnabled = true
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }
}
