import XCTest

@testable import MenuBarKit

final class AppLanguageOptionTests: XCTestCase {
    func testIdMatchesCode() {
        let option = AppLanguageOption(code: "it", name: "Italiano")
        XCTAssertEqual(option.id, "it")
    }

    func testSystemOptionHasEmptyCode() {
        let option = AppLanguageOption(code: "", name: "System")
        XCTAssertEqual(option.id, "")
    }
}
