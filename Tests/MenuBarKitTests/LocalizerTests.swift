import XCTest

@testable import MenuBarKit

final class LocalizerTests: XCTestCase {
    private func makeBundle() -> Bundle {
        Bundle(for: LocalizerTests.self)
    }

    func testMissingKeyFallsBackToKeyItself() {
        let localizer = Localizer(bundle: makeBundle(), language: nil)
        XCTAssertEqual(localizer("missing.key"), "missing.key")
    }

    func testForcedUnknownLanguageFallsBackToBundle() {
        let localizer = Localizer(bundle: makeBundle(), language: "xx_XX")
        XCTAssertEqual(localizer("missing.key"), "missing.key")
    }

    func testEmptyLanguageFollowsSystem() {
        let localizer = Localizer(bundle: makeBundle(), language: "")
        XCTAssertEqual(localizer("missing.key"), "missing.key")
    }

    func testFormatArgumentsAreSubstituted() {
        let localizer = Localizer(bundle: makeBundle(), language: nil)
        // The key itself is used as the format string when missing.
        XCTAssertEqual(localizer("greeting %d", 3), "greeting 3")
    }

    func testNoArgumentsKeepsFormatVerbatim() {
        let localizer = Localizer(bundle: makeBundle(), language: nil)
        XCTAssertEqual(localizer("100% done"), "100% done")
    }
}
