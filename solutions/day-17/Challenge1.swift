// Worked solution: Replace an unsafe index assumption
// Bounds validation stops the trap, but an index can remain valid while pointing to a different item after sorting or deletion. Store and look up a stable task ID when preserving navigation across list changes.
// Read lessons/day-17.md for any surrounding types or setup.

func element<T>(at index: Int, in values: [T]) -> T? {
    guard values.indices.contains(index) else { return nil }
    return values[index]
}

// Expected results:
// element(at: -1, in: [10, 20]) == nil
// element(at: 1, in: [10, 20]) == 20
// element(at: 2, in: [10, 20]) == nil
// element(at: 0, in: [Int]()) == nil
