// Worked solution: Create a validated title value
// Every successfully created instance satisfies the same rule. A production client and server must agree on length measurement: a backend may count bytes rather than user-perceived characters.
// Read lessons/day-01.md for any surrounding types or setup.

import Foundation

enum TitleError: Error {
    case blank
    case tooLong(maximum: Int)
}

struct ValidatedTitle {
    let value: String

    init(_ raw: String) throws {
        let clean = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { throw TitleError.blank }
        guard clean.count <= 80 else { throw TitleError.tooLong(maximum: 80) }
        value = clean
    }
}
