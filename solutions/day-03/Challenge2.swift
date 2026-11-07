// Worked solution: Own a custom root view
// The controller has a typed reference without an unsafe cast, and the view can be reused or previewed independently. The coder initializer intentionally rejects storyboard/XIB construction; do not connect this particular class in Interface Builder.
// Read lessons/day-03.md for any surrounding types or setup.

import UIKit

@MainActor
final class WelcomeView: UIView {
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        label.text = "Welcome to PocketTasks"
        label.textAlignment = .center
        label.frame = bounds
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(label)
    }

    required init?(coder: NSCoder) {
        fatalError("This example supports programmatic construction only")
    }
}

@MainActor
final class WelcomeViewController: UIViewController {
    private let contentView = WelcomeView(frame: .zero)

    override func loadView() {
        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Welcome"
    }
}
