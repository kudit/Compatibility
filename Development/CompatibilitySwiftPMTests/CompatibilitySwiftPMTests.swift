// MARK: - Swift Package Manager regression tests
// These XCTest cases live outside the Playgrounds app target so `swift test` can
// validate public Compatibility APIs without affecting Playgrounds compilation.

import Compatibility
import Foundation
import XCTest

final class CompatibilitySwiftPMTests: XCTestCase {
    /// Verifies the CLI's `banana` example continues to use the public extension.
    func testBananaExample() {
        XCTAssertEqual("Bob".banana, "Bob, Bob, bo-ob\nBanana-fana fo-fob\nFee-fy-mo-mob\nBob!")
    }

    /// Verifies a documented date format is accepted by the public date parser.
    func testParseDateExample() {
        guard let date = Date(parse: "2023-01-02 17:12:00") else {
            return XCTFail("Compatibility should parse its documented MySQL date format.")
        }
        let components = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date)
        XCTAssertEqual(components.year, 2023)
        XCTAssertEqual(components.month, 1)
        XCTAssertEqual(components.day, 2)
    }

    /// Rejecting unsupported text keeps the command-line error path predictable.
    func testParseDateRejectsUnsupportedText() {
        XCTAssertNil(Date(parse: "not a supported Compatibility date"))
    }
}
