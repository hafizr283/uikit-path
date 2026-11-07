// Test a URLSession boundary without the internet
// Use an immutable URLProtocol fixture to deliver a known HTTP response. Verify that an ephemeral session receives the exact bytes and status code.
// See lessons/day-16.md for requirements, hints, and acceptance checks.
// Independent exercise; do not add all course files to one Xcode target.

import Foundation
import XCTest
// Implement FixtureURLProtocol and a URLSession test.
