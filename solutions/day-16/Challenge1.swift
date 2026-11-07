// Worked solution: Test title validation at its boundaries
// Boundary tests are more valuable than repeating many ordinary inputs. The contract here uses user-perceived characters; if a backend limits bytes, define and test a matching contract rather than assuming the two are equivalent.
// Read lessons/day-16.md for any surrounding types or setup.

import Foundation
import XCTest

private func normalizedTitle(_ input: String) -> String? {
    let value = input.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !value.isEmpty, value.count <= 80 else { return nil }
    return value
}

final class TitleValidationTests: XCTestCase {
    func testTrimsBeforeValidation() {
        XCTAssertEqual(normalizedTitle("  Read docs\n"), "Read docs")
    }

    func testWhitespaceIsRejected() {
        XCTAssertNil(normalizedTitle(" \n\t "))
    }

    func testMaximumBoundary() {
        let accepted = String(repeating: "a", count: 80)
        XCTAssertEqual(normalizedTitle(accepted), accepted)
        XCTAssertNil(normalizedTitle(accepted + "a"))
    }
}
