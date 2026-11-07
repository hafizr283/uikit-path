import Foundation

@main
enum ValidationMain {
    static func main() async {
        for _ in 0..<3 {
            let count = await countCompletedWork()
            precondition(count == 100, "Actor increments must not be lost")
        }
    }
}
