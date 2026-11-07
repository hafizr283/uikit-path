// Day 03: UIKit, scenes, and view-controller lifecycles
// Independent educational example. Read lessons/day-03.md for setup.
// Use a UIKit iOS app target with the scene lifecycle and its existing AppDelegate. Replace the generated SceneDelegate with the one above, then add LifecycleViewController to the same target.
// In the target's Info settings, preserve Application Scene Manifest and the scene delegate class entry. Remove a Storyboard Name from the application scene configuration if present, and remove the app's main storyboard setting if present. Keep the launch screen settings.
// The scene delegate creates a window for the connected UIWindowScene, gives it a navigation controller, retains it, and makes it visible.
// viewDidLoad creates the label once for that loaded view. The autoresizing mask stretches it with the container; no fixed device width is encoded.
// Run on an iOS simulator, rotate it, and inspect Xcode's console. Layout logging may repeat; appearance logging is not a promise of one immutable sequence under all transitions.

import UIKit

@MainActor
final class LifecycleViewController: UIViewController {
    private let messageLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad")
        title = "PocketTasks"
        view.backgroundColor = .systemBackground

        messageLabel.text = "Your first UIKit screen"
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.font = .preferredFont(forTextStyle: .title2)
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.frame = view.bounds
        messageLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(messageLabel)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewWillAppear")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("viewDidAppear")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("viewDidLayoutSubviews")
    }
}

// Replace the generated SceneDelegate; do not keep two classes with this name.
@MainActor
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UINavigationController(
            rootViewController: LifecycleViewController()
        )
        self.window = window
        window.makeKeyAndVisible()
    }
}
