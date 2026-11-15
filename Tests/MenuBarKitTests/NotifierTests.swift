import UserNotifications
import XCTest

@testable import MenuBarKit

@MainActor
final class NotifierTests: XCTestCase {
    func testDefaultActionDeliversRequestIdentifierToClickHandler() async {
        let notifier = Notifier()
        let delivered = expectation(description: "Notification click delivered")
        var clickedIdentifier: String?
        notifier.onNotificationClick = { identifier in
            clickedIdentifier = identifier
            delivered.fulfill()
        }

        notifier.handleResponse(
            actionIdentifier: UNNotificationDefaultActionIdentifier,
            requestIdentifier: "update-available"
        )

        await fulfillment(of: [delivered], timeout: 1.0)
        XCTAssertEqual(clickedIdentifier, "update-available")
    }

    func testDismissActionDoesNotInvokeClickHandler() async {
        let notifier = Notifier()
        var clickedIdentifier: String?
        notifier.onNotificationClick = { identifier in
            clickedIdentifier = identifier
        }

        notifier.handleResponse(
            actionIdentifier: UNNotificationDismissActionIdentifier,
            requestIdentifier: "update-available"
        )

        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
        XCTAssertNil(clickedIdentifier)
    }
}
