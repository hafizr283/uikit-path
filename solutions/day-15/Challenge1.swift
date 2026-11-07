// Worked solution: Make expiry logic deterministic
// Time is a dependency even when it looks like a global utility. Passing now makes expiration behavior reproducible. This allowance reduces near-expiry failures but cannot replace server-side validation.
// Read lessons/day-15.md for any surrounding types or setup.

import Foundation
struct AccessCredential {
    let value: String
    let expiresAt: Date

    func needsRefresh(at now: Date) -> Bool {
        expiresAt.timeIntervalSince(now) <= 30
    }
}
