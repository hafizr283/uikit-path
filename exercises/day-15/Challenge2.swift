// Build a safe authorized request
// Create a GET request for one known HTTPS API origin. Reject a URL from another host or port so a caller cannot accidentally attach a token to an unrelated image URL.
// See lessons/day-15.md for requirements, hints, and acceptance checks.
// Independent exercise; do not add all course files to one Xcode target.

import Foundation
enum RequestError: Error { case untrustedURL }
func authorizedGET(url: URL, token: String) throws -> URLRequest {
    // Validate the destination before attaching the token.
    URLRequest(url: url)
}
