// Worked solution: Extract a navigation flow
// The two screen classes are routing placeholders; connect onSelect to the actual list delegate and build the detail UI separately. Retain TasksCoordinator as a scene property, create it with the scene's navigation controller, and call start. The navigation controller retains its screens, so their callbacks should not strongly retain the coordinator that owns it.
// Read lessons/day-13.md for any surrounding types or setup.

import UIKit

@MainActor
final class TaskListScreen: UIViewController {
    var onSelect: ((UUID) -> Void)?
}

@MainActor
final class TaskDetailScreen: UIViewController {
    let taskID: UUID
    init(taskID: UUID) {
        self.taskID = taskID
        super.init(nibName: nil, bundle: nil)
        title = "Task details"
    }
    required init?(coder: NSCoder) {
        fatalError("Use init(taskID:).")
    }
}

@MainActor
final class TasksCoordinator {
    let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let list = TaskListScreen()
        list.title = "PocketTasks"
        list.onSelect = { [weak self] id in
            self?.navigationController.pushViewController(
                TaskDetailScreen(taskID: id), animated: true
            )
        }
        navigationController.setViewControllers([list], animated: false)
    }
}
