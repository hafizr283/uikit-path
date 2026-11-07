// Day 16: Testing UIKit applications
// Independent educational example. Read lessons/day-16.md for setup.
// In Xcode, add an iOS Unit Testing Bundle if the project has none. Add this file to that test target only, then use Product > Test.
// The teaching types are private and self-contained. In your app, keep the real implementation in the app or a library target and use @testable import PocketTasks in tests instead of duplicating production code.
// StubLoader is immutable and Sendable. Its result makes success, empty, and failure cases immediate and independent of a server.
// Only test methods that touch the MainActor view model are annotated. Each assertion compares a local snapshot of observable state.
// This small model assumes one load at a time. A real searchable list also needs stale-request protection and tests for out-of-order responses from Day 12.

import Foundation
import XCTest

// Self-contained teaching types. Put this entire file in an iOS
// Unit Testing target; no app module import is required.
private struct TaskItem: Equatable, Sendable {
    let id: Int
    let title: String
}

private enum StubError: Error {
    case offline
}

private protocol TaskLoading: Sendable {
    func fetchTasks() async throws -> [TaskItem]
}

private struct StubLoader: TaskLoading {
    let result: Result<[TaskItem], StubError>

    func fetchTasks() async throws -> [TaskItem] {
        try result.get()
    }
}

@MainActor
private final class TaskListViewModel {
    enum State: Equatable {
        case idle, loading, empty
        case loaded([TaskItem])
        case failed(String)
    }

    private(set) var state: State = .idle
    private let loader: any TaskLoading

    init(loader: any TaskLoading) {
        self.loader = loader
    }

    func load() async {
        state = .loading
        do {
            let items = try await loader.fetchTasks()
            try Task.checkCancellation()
            state = items.isEmpty ? .empty : .loaded(items)
        } catch is CancellationError {
            state = .idle
        } catch {
            state = .failed("Could not load tasks.")
        }
    }
}

final class TaskListViewModelTests: XCTestCase {
    @MainActor
    func testLoadSuccessPublishesItems() async {
        let items = [TaskItem(id: 1, title: "Study UIKit")]
        let model = TaskListViewModel(
            loader: StubLoader(result: .success(items))
        )
        await model.load()
        let actual = model.state
        XCTAssertEqual(actual, .loaded(items))
    }

    @MainActor
    func testEmptyResponseShowsEmptyState() async {
        let model = TaskListViewModel(
            loader: StubLoader(result: .success([]))
        )
        await model.load()
        let actual = model.state
        XCTAssertEqual(actual, .empty)
    }

    @MainActor
    func testFailureShowsRecoverableMessage() async {
        let model = TaskListViewModel(
            loader: StubLoader(result: .failure(.offline))
        )
        await model.load()
        let actual = model.state
        XCTAssertEqual(actual, .failed("Could not load tasks."))
    }
}
