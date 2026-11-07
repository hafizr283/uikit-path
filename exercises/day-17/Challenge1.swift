// Replace an unsafe index assumption
// A detail screen crashes when a saved index becomes invalid after a refreshed list shrinks. Write a safe accessor and explain why production navigation should prefer a stable task identifier.
// See lessons/day-17.md for requirements, hints, and acceptance checks.
// Independent exercise; do not add all course files to one Xcode target.

func element<T>(at index: Int, in values: [T]) -> T? {
    // Validate membership in the array's valid indices.
    nil
}
