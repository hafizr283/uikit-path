// Test title validation at its boundaries
// Write tests for a title normalizer that trims whitespace, rejects empty titles, and accepts titles with at most 80 characters after trimming.
// See lessons/day-16.md for requirements, hints, and acceptance checks.
// Independent exercise; do not add all course files to one Xcode target.

import Foundation
func normalizedTitle(_ input: String) -> String? {
    let value = input.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !value.isEmpty, value.count <= 80 else { return nil }
    return value
}
// Add XCTest assertions for the boundaries.
