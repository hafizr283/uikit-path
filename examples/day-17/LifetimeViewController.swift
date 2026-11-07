// Day 17: Debugging, performance & reliability
// Independent educational example. Read lessons/day-17.md for setup.
// Add this file to the iOS app target. From an existing controller inside a UINavigationController, push LifetimeViewController(). It needs no storyboard.
// Tap Refresh and confirm that the visible count increases. Pop the controller and look for the deinit message, which contains no user data.
// Place a breakpoint in viewDidLoad and inspect the view hierarchy after layout using Xcode's View Debugger.
// For a deliberate local leak experiment, temporarily make the refresh closure capture self strongly. Push and pop again, then find the retained controller and closure in Memory Graph. Revert the change after observing it.
// The weak capture breaks this particular cycle. A missing deinit message alone does not identify a cause; transitions, navigation stacks, caches, or other owners may still legitimately retain a controller.

import UIKit

@MainActor
final class LifetimeViewController: UIViewController {
    private let statusLabel = UILabel()
    private var refresh: (() -> Void)?
    private var refreshCount = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Lifetime lab"
        view.backgroundColor = .systemBackground

        statusLabel.text = "Refresh count: 0"
        statusLabel.font = .preferredFont(forTextStyle: .body)
        statusLabel.adjustsFontForContentSizeCategory = true

        refresh = { [weak self] in
            guard let self else { return }
            self.refreshCount += 1
            self.statusLabel.text =
                "Refresh count: \(self.refreshCount)"
        }

        var configuration = UIButton.Configuration.filled()
        configuration.title = "Refresh"
        let button = UIButton(configuration: configuration)
        button.addAction(UIAction { [weak self] _ in
            self?.refresh?()
        }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [
            statusLabel, button
        ])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: 24
            ),
            stack.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -24
            ),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    deinit {
        print("LifetimeViewController released")
    }
}
