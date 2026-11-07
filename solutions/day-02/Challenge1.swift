// Worked solution: Explain and repair the cycle
// The screen still owns a loader it depends on, but the callback no longer owns the screen. This is memory-safe if the callback arrives after dismissal. A real loader may also need cancellation so irrelevant work stops.
// Read lessons/day-02.md for any surrounding types or setup.

final class Loader { var completion: (() -> Void)? }
final class Screen {
    let loader: Loader
    init(loader: Loader) { self.loader = loader }
    func start() {
        loader.completion = { [weak self] in
            self?.showResult()
        }
    }
    func showResult() { print("Ready") }
}
