// Day 19: iOS platform integration
// Independent educational example. Read lessons/day-19.md for setup.
// Add the parser to the app or a shared model target. It uses Foundation only, so its behavior can be unit tested without constructing a controller.
// Register the pockettasks custom scheme in the app target's URL Types if you want to open it from the simulator. The parser alone does not register the scheme.
// For a warm custom-scheme launch, obtain URLs in scene(_:openURLContexts:). For a Universal Link, inspect the webpageURL from the browsing user activity. Also check scene connection options on cold launch.
// Pass the parsed AppRoute to a MainActor coordinator. Check session state and whether the task exists and is accessible before presenting details.
// The accepted grammar intentionally rejects all query strings and fragments. Expand it only when a feature needs documented parameters, and add matching tests.

import Foundation

enum AppRoute: Equatable, Sendable {
    case task(UUID)
}

struct DeepLinkParser {
    let universalLinkHost: String

    func parse(_ url: URL) -> AppRoute? {
        guard url.user == nil, url.password == nil,
              url.query == nil, url.fragment == nil else {
            return nil
        }
        let parts = url.path.split(separator: "/").map(String.init)
        let candidate: String

        switch url.scheme?.lowercased() {
        case "https":
            guard url.host?.lowercased() ==
                    universalLinkHost.lowercased(),
                  url.port == nil || url.port == 443,
                  parts.count == 2,
                  parts[0] == "tasks" else { return nil }
            candidate = parts[1]
        case "pockettasks":
            guard url.host?.lowercased() == "task",
                  url.port == nil,
                  parts.count == 1 else { return nil }
            candidate = parts[0]
        default:
            return nil
        }

        guard let id = UUID(uuidString: candidate) else {
            return nil
        }
        return .task(id)
    }
}

// Fixture use:
// let parser = DeepLinkParser(
//     universalLinkHost: "pockettasks.example"
// )
// let url = URL(string:
//   "pockettasks://task/00000000-0000-0000-0000-000000000001"
// )!
// parser.parse(url) -> .task(the UUID above)
//
// The .example host is documentation-only, not a live service.
