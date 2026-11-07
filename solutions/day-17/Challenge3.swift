// Worked solution: Remove repeated membership scans without changing behavior
// The original work is roughly proportional to items multiplied by selected IDs. Building a Set then filtering is roughly proportional to their sum on average, with extra memory for the Set. Measure both versions under the same optimized configuration and workload rather than promising a device-independent speedup.
// Read lessons/day-17.md for any surrounding types or setup.

import XCTest

private struct Item: Equatable {
    let id: Int
}

private func selectedItems(
    _ items: [Item], ids: [Int]
) -> [Item] {
    let membership = Set(ids)
    return items.filter { membership.contains($0.id) }
}

final class SelectionPerformanceTests: XCTestCase {
    func testPreservesSourceOrderAndMembership() {
        let items = [Item(id: 3), Item(id: 1), Item(id: 2)]
        XCTAssertEqual(
            selectedItems(items, ids: [2, 3, 3]),
            [Item(id: 3), Item(id: 2)]
        )
    }

    func testSelectionPerformance() {
        let items = (0..<20_000).map { Item(id: $0) }
        let ids = Array(stride(from: 0, to: 20_000, by: 2))
        measure {
            let result = selectedItems(items, ids: ids)
            XCTAssertEqual(result.count, 10_000)
        }
    }
}
