// Worked solution: Test a URLSession boundary without the internet
// This validates that your test harness controls the URLSession boundary. Next inject this session into the actual API client and assert decoded models and non-2xx behavior. The fixture finishes synchronously, so stopLoading has no outstanding operation to cancel. An asynchronous fixture would need cancellation handling.
// Read lessons/day-16.md for any surrounding types or setup.

import Foundation
import XCTest

private final class FixtureURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == "fixture.test"
    }

    override class func canonicalRequest(
        for request: URLRequest
    ) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url,
              let response = HTTPURLResponse(
                url: url, statusCode: 200, httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
              ) else { return }
        let bytes = Data("[{\"id\":1,\"title\":\"Fixture\"}]".utf8)
        client?.urlProtocol(
            self, didReceive: response, cacheStoragePolicy: .notAllowed
        )
        client?.urlProtocol(self, didLoad: bytes)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

final class SessionBoundaryTests: XCTestCase {
    func testReceivesFixtureResponse() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [FixtureURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }

        let url = try XCTUnwrap(URL(string: "https://fixture.test/tasks"))
        let (data, response) = try await session.data(from: url)
        let http = try XCTUnwrap(response as? HTTPURLResponse)
        XCTAssertEqual(http.statusCode, 200)
        XCTAssertEqual(
            String(data: data, encoding: .utf8),
            "[{\"id\":1,\"title\":\"Fixture\"}]"
        )
    }
}
