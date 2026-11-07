// Make expiry logic deterministic
// A request should proactively refresh when its access token is within 30 seconds of expiration. Write a pure value type so you can test exact boundary times without waiting for the clock.
// See lessons/day-15.md for requirements, hints, and acceptance checks.
// Independent exercise; do not add all course files to one Xcode target.

import Foundation
struct AccessCredential {
    let value: String
    let expiresAt: Date
    func needsRefresh(at now: Date) -> Bool {
        // Compare against a 30-second allowance.
        false
    }
}
