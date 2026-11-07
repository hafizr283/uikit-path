// Worked solution: Create two peer tabs
// Each tab preserves its own stack while the user switches peer destinations. Use this function's return value as the scene window's root controller; do not wrap the entire tab controller in another unnecessary navigation stack.
// Read lessons/day-06.md for any surrounding types or setup.

import UIKit

@MainActor
func makeRootTabs() -> UITabBarController {
    let tasks = TaskHomeViewController()
    let settings = UIViewController()
    settings.title = "Settings"
    settings.view.backgroundColor = .systemBackground

    let taskNav = UINavigationController(rootViewController: tasks)
    taskNav.tabBarItem = UITabBarItem(
        title: "Tasks", image: UIImage(systemName: "checklist"), tag: 0
    )
    let settingsNav = UINavigationController(rootViewController: settings)
    settingsNav.tabBarItem = UITabBarItem(
        title: "Settings", image: UIImage(systemName: "gearshape"), tag: 1
    )
    let tabs = UITabBarController()
    tabs.viewControllers = [taskNav, settingsNav]
    return tabs
}
