// Day 10: Concurrency without UI races
// Independent educational example. Read lessons/day-10.md for setup.
// Add the file to a UIKit iOS app and push AsyncDemoViewController. MessageService uses a cancellable delay to simulate a network request; it does not access a real server.
// The controller and its UI state are MainActor isolated. The button starts an unstructured Task from that context, so its UI mutations remain isolated.
// The actor service suspends during the delay. It does not block the main thread while waiting.
// The task closure weakly captures the controller and does not promote it to a strong reference before the await, so the request need not keep the screen alive.
// A second tap cancels the previous task. Leaving the screen cancels outstanding work. The post-await check prevents a cancelled result from being rendered.
// For production search with services that may ignore cancellation, also use the generation-token exercise below.

import UIKit

actor MessageService {
    func fetchMessage() async throws -> String {
        try await Task.sleep(for: .milliseconds(900))
        try Task.checkCancellation()
        return "Your task list is ready."
    }
}

@MainActor
final class AsyncDemoViewController: UIViewController {
    private let service = MessageService()
    private let label = UILabel()
    private var loadTask: Task<Void, Never>?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Async loading"
        view.backgroundColor = .systemBackground
        label.text = "Tap Load"
        label.textAlignment = .center
        label.numberOfLines = 0

        let button = UIButton(type: .system)
        button.setTitle("Load", for: .normal)
        button.addTarget(self, action: #selector(load), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [label, button])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)
        ])
    }

    @objc private func load() {
        loadTask?.cancel()
        label.text = "Loading…"
        let service = service
        loadTask = Task { [weak self] in
            do {
                let message = try await service.fetchMessage()
                try Task.checkCancellation()
                self?.label.text = message
            } catch is CancellationError {
                // A newer load or navigation made this work unnecessary.
            } catch {
                self?.label.text = "Could not load. Try again."
            }
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        loadTask?.cancel()
        loadTask = nil
    }
}
