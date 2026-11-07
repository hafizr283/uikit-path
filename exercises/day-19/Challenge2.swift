// Read a small imported text file safely
// A document picker returns a URL. Read at most 64 KiB of UTF-8 task notes, balance security-scoped access, and reject larger or invalid text.
// See lessons/day-19.md for requirements, hints, and acceptance checks.
// Independent exercise; do not add all course files to one Xcode target.

import Foundation
enum ImportError: Error { case tooLarge, invalidText }
func importNotes(from url: URL) throws -> String {
    // Open, read a bounded amount, and validate UTF-8.
    ""
}
