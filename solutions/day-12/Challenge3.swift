// Worked solution: Protect a reusable image view
// Create one loader for the cell's image view and call cancel from prepareForReuse. The weak capture and post-await URL check prevent assigning an old request to a new model. For production, add bounded caching and prepare appropriately sized images off the main actor; this small example intentionally teaches lifecycle correctness rather than image-pipeline performance.
// Read lessons/day-12.md for any surrounding types or setup.

@MainActor
final class CellImageLoader {
    private weak var imageView: UIImageView?
    private var currentURL: URL?
    private var request: Task<Void, Never>?

    init(imageView: UIImageView) { self.imageView = imageView }

    func load(_ url: URL) {
        cancel()
        currentURL = url
        imageView?.image = UIImage(systemName: "photo")
        request = Task { [weak self] in
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                try Task.checkCancellation()
                guard let http = response as? HTTPURLResponse,
                      (200..<300).contains(http.statusCode),
                      let self, self.currentURL == url else { return }
                self.imageView?.image = UIImage(data: data)
            } catch {
                // Keep the placeholder; cancellation is expected on reuse.
            }
        }
    }

    func cancel() {
        currentURL = nil
        request?.cancel()
        request = nil
        imageView?.image = UIImage(systemName: "photo")
    }
}
