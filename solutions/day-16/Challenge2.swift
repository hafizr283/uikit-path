// Worked solution: Prove recovery after an initial failure
// This fake models an important temporal behavior with a controlled sequence. It verifies that failure does not permanently trap the model. It does not prove the retry button is wired correctly; a separate UI test covers that connection.
// Read lessons/day-16.md for any surrounding types or setup.

// Add to the same test file as the example.
private actor RetryLoader: TaskLoading {
    private var calls = 0
    func fetchTasks() async throws -> [TaskItem] {
        calls += 1
        if calls == 1 { throw StubError.offline }
        return [TaskItem(id: 2, title: "Retry succeeded")]
    }
}

extension TaskListViewModelTests {
    @MainActor
    func testRetryReplacesFailureWithContent() async {
        let model = TaskListViewModel(loader: RetryLoader())
        await model.load()
        let first = model.state
        XCTAssertEqual(first, .failed("Could not load tasks."))

        await model.load()
        let second = model.state
        XCTAssertEqual(
            second,
            .loaded([TaskItem(id: 2, title: "Retry succeeded")])
        )
    }
}
