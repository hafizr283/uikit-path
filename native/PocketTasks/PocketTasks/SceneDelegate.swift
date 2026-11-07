import UIKit

@MainActor
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let fileURL = URL.applicationSupportDirectory
            .appending(path: "PocketTasks/tasks.json")
        let repository = TaskRepository(
            persistence: TaskFileStore(fileURL: fileURL)
        )
        let navigation = UINavigationController(
            rootViewController: TaskListViewController(repository: repository)
        )
        navigation.navigationBar.prefersLargeTitles = true
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = navigation
        window.tintColor = .systemOrange
        self.window = window
        window.makeKeyAndVisible()
    }
}
