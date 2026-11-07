// Worked solution: Build a safe authorized request
// Credential attachment should have an explicit destination boundary. This exercise constructs a request only; a production client must also define redirect handling and avoid forwarding credentials outside the trusted origin. Use a fixture token during inspection.
// Read lessons/day-15.md for any surrounding types or setup.

import Foundation
enum RequestError: Error { case untrustedURL }

func authorizedGET(url: URL, token: String) throws -> URLRequest {
    guard url.scheme?.lowercased() == "https",
          url.host?.lowercased() == "api.example.com",
          url.port == nil || url.port == 443,
          url.user == nil, url.password == nil
    else { throw RequestError.untrustedURL }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(token)",
                     forHTTPHeaderField: "Authorization")
    return request
}
