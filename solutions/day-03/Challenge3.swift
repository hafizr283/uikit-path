// Worked solution: Diagnose a duplicate interface
// The exercise uses manual layout to isolate the lifecycle issue. Tomorrow's constraints express the same relationships more declaratively. Calling this layout method repeatedly changes the frame but does not allocate another label.
// Read lessons/day-03.md for any surrounding types or setup.

import UIKit

@MainActor
final class BannerViewController: UIViewController {
    private let banner = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        banner.text = "Tasks"
        view.addSubview(banner)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let safe = view.safeAreaLayoutGuide.layoutFrame
        banner.frame = CGRect(
            x: safe.minX + 20, y: safe.minY + 16,
            width: max(0, safe.width - 40), height: 44
        )
    }
}
