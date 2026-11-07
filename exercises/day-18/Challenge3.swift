// Localize a task count with plural resources
// Replace hard-coded English count assembly with a localized count. Use Xcode's String Catalog plural variants for an English one/other example, then inspect what a second language needs.
// See lessons/day-18.md for requirements, hints, and acceptance checks.
// Independent exercise; do not add all course files to one Xcode target.

import Foundation
func remainingMessage(count: Int) -> String {
    // Replace concatenated fragments with a localizable sentence.
    "\(count) tasks remaining"
}
