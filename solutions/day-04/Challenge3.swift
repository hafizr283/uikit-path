// Worked solution: Update a stored constraint instead of duplicating it
// There is one active height constraint throughout the screen's lifetime. Changing its constant modifies the existing layout system instead of creating contradictory requirements. The animation closure is short-lived; retaining self for the animation is intentional here.
// Read lessons/day-04.md for any surrounding types or setup.

import UIKit

@MainActor
final class ExpandViewController: UIViewController {
    private var panelHeight: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        let panel = UIView()
        panel.backgroundColor = .systemTeal
        panel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(panel)
        let height = panel.heightAnchor.constraint(equalToConstant: 80)
        panelHeight = height
        NSLayoutConstraint.activate([
            panel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            panel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            panel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            height
        ])
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Resize", primaryAction: UIAction { [weak self] _ in
                self?.togglePanel()
            }
        )
    }

    private func togglePanel() {
        guard let panelHeight else { return }
        view.layoutIfNeeded()
        panelHeight.constant = panelHeight.constant == 80 ? 160 : 80
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }
}
