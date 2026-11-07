// Worked solution: Separate setup from repeated refresh
// This counts appearances of this controller instance, not app launches. Returning from a pushed detail screen increments it without constructing another label. Use it as a root controller and navigate away and back once you implement navigation on Day 6.
// Read lessons/day-03.md for any surrounding types or setup.

import UIKit

@MainActor
final class VisitViewController: UIViewController {
    private let label = UILabel()
    private var visits = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        label.frame = view.bounds
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        label.textAlignment = .center
        view.addSubview(label)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        visits += 1
        label.text = "Appearance \(visits)"
    }
}
