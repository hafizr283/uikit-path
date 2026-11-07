// Worked solution: Present a cancellable sheet
// The navigation controller is presented modally, so dismiss ends the flow. This help screen has no unsaved state, making interactive dismissal reasonable. Add content as an extension exercise; the solution focuses on presentation behavior.
// Read lessons/day-06.md for any surrounding types or setup.

import UIKit

@MainActor
func showHelp(from presenter: UIViewController) {
    let help = UIViewController()
    help.title = "How PocketTasks works"
    help.view.backgroundColor = .systemBackground
    help.navigationItem.rightBarButtonItem = UIBarButtonItem(
        title: "Done", primaryAction: UIAction { [weak help] _ in
            help?.dismiss(animated: true)
        }
    )
    let navigation = UINavigationController(rootViewController: help)
    navigation.modalPresentationStyle = .pageSheet
    if let sheet = navigation.sheetPresentationController {
        sheet.detents = [.medium(), .large()]
        sheet.prefersGrabberVisible = true
    }
    presenter.present(navigation, animated: true)
}
