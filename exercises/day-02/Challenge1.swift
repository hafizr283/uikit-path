// Explain and repair the cycle
// A Loader stores a completion closure and a Screen owns its Loader. Repair the callback so the screen can be released while the loader is retained elsewhere.
// See lessons/day-02.md for requirements, hints, and acceptance checks.
// Independent exercise; do not add all course files to one Xcode target.

final class Loader { var completion: (() -> Void)? }
final class Screen {
    let loader: Loader
    init(loader: Loader) { self.loader = loader }
    func start() {
        loader.completion = { self.showResult() }
    }
    func showResult() { print("Ready") }
}
