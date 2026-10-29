import AppKit
import ServiceManagement
import XCTest

@testable import MenuBarKit

@MainActor
private final class TestLoginService: LoginService {
    var currentStatus = SMAppService.Status.notRegistered
    var statusAfterRegister = SMAppService.Status.requiresApproval
    var registrationError: Error?
    var removalError: Error?
    var reads = 0
    var registrations = 0
    var removals = 0

    var status: SMAppService.Status {
        reads += 1
        return currentStatus
    }

    func register() throws {
        registrations += 1
        currentStatus = statusAfterRegister
        if let registrationError { throw registrationError }
    }

    func unregister() throws {
        removals += 1
        if let removalError { throw removalError }
        currentStatus = .notRegistered
    }
}

final class LoginItemTests: XCTestCase {
    private enum Failure: Error { case rejected }

    @MainActor
    func testMapsActualServiceStatesWithoutRegistering() {
        let service = TestLoginService()
        let item = LoginItem(service: service, isBundled: true)
        for (native, expected) in [
            (SMAppService.Status.enabled, LoginItemStatus.enabled),
            (.notRegistered, .disabled), (.requiresApproval, .requiresApproval),
            (.notFound, .unavailable(.serviceNotFound)),
        ] {
            service.currentStatus = native
            item.refresh()
            XCTAssertEqual(item.status, expected)
        }
        XCTAssertEqual(service.registrations, 0)
        XCTAssertEqual(service.removals, 0)
    }

    @MainActor
    func testUnbundledProcessNeverAccessesOrRegistersService() {
        let service = TestLoginService()
        service.currentStatus = .enabled
        let item = LoginItem(service: service, isBundled: false)
        XCTAssertEqual(item.status, .unavailable(.notBundled))
        XCTAssertThrowsError(try item.setEnabled(true)) { error in
            guard case LoginItemError.unavailable(.notBundled) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
        XCTAssertEqual(service.reads, 0)
        XCTAssertEqual(service.registrations, 0)
    }

    @MainActor
    func testPendingApprovalIsReportedAndRepeatedEnableDoesNotRegisterAgain() throws {
        let service = TestLoginService()
        let item = LoginItem(service: service, isBundled: true)
        try item.setEnabled(true)
        XCTAssertEqual(item.status, .requiresApproval)
        try item.setEnabled(true)
        XCTAssertEqual(service.registrations, 1)
        try item.setEnabled(false)
        XCTAssertEqual(item.status, .disabled)
        XCTAssertEqual(service.removals, 1)
    }

    @MainActor
    func testFailedOperationsRefreshStatusWithoutOptimisticSuccess() {
        let service = TestLoginService()
        service.registrationError = Failure.rejected
        let item = LoginItem(service: service, isBundled: true)
        XCTAssertThrowsError(try item.setEnabled(true))
        XCTAssertEqual(item.status, .requiresApproval)
        service.currentStatus = .enabled
        service.removalError = Failure.rejected
        XCTAssertThrowsError(try item.setEnabled(false))
        XCTAssertEqual(item.status, .enabled)
    }

    @MainActor
    func testActivationRefreshesStateAndReleaseRemovesObservation() {
        let service = TestLoginService()
        var item: LoginItem? = LoginItem(service: service, isBundled: true)
        service.currentStatus = .enabled
        NotificationCenter.default.post(
            name: NSApplication.didBecomeActiveNotification, object: nil)
        XCTAssertEqual(item?.status, .enabled)
        item = nil
        let reads = service.reads
        NotificationCenter.default.post(
            name: NSApplication.didBecomeActiveNotification, object: nil)
        XCTAssertEqual(service.reads, reads)
    }
}
