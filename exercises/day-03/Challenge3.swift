// Diagnose a duplicate interface
// A controller adds a new banner every time viewDidLayoutSubviews runs. Refactor it so layout changes do not create more banners.
// See lessons/day-03.md for requirements, hints, and acceptance checks.
// Independent exercise; do not add all course files to one Xcode target.

override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    let banner = UILabel()
    banner.text = "Tasks"
    view.addSubview(banner)
    banner.frame = CGRect(x: 20, y: 100, width: 240, height: 44)
}
