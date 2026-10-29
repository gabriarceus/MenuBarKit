import AppKit
import Combine
import ServiceManagement

public enum LoginItemUnavailableReason: Equatable, Sendable {
    case notBundled, serviceNotFound, unsupportedServiceStatus
}

/// Actual registration state. Approval-required does not mean login launch is enabled.
public enum LoginItemStatus: Equatable, Sendable {
    case enabled, disabled, requiresApproval
    case unavailable(LoginItemUnavailableReason)
}

public enum LoginItemError: Error {
    case unavailable(LoginItemUnavailableReason)
}

/// Opt-in main-app login registration. Construction and activation refresh status without registering.
@MainActor
public final class LoginItem: NSObject, ObservableObject {
    @Published public private(set) var status: LoginItemStatus = .unavailable(.notBundled)
    private let service: any LoginService
    private let isBundled: Bool

    public override convenience init() {
        self.init(
            service: SystemLoginService(), isBundled: Bundle.main.bundleURL.pathExtension == "app")
    }

    init(service: any LoginService, isBundled: Bool) {
        self.service = service
        self.isBundled = isBundled
        super.init()
        refresh()
        NotificationCenter.default.addObserver(
            self, selector: #selector(refresh), name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    /// Re-reads platform state, including approval changes made in System Settings.
    @objc public func refresh() {
        guard isBundled else {
            status = .unavailable(.notBundled)
            return
        }
        switch service.status {
        case .enabled: status = .enabled
        case .notRegistered: status = .disabled
        case .requiresApproval: status = .requiresApproval
        case .notFound: status = .unavailable(.serviceNotFound)
        @unknown default: status = .unavailable(.unsupportedServiceStatus)
        }
    }

    /// Requests registration or removal and refreshes actual state even if the platform throws.
    public func setEnabled(_ enabled: Bool) throws {
        refresh()
        switch status {
        case .unavailable(let reason):
            throw LoginItemError.unavailable(reason)
        case .enabled where enabled:
            return
        case .disabled where !enabled:
            return
        case .requiresApproval where enabled:
            return
        case .enabled, .disabled, .requiresApproval:
            defer { refresh() }
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
        }
    }

    /// Opens the system login-items page without changing registration.
    public static func openSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }

    isolated deinit {
        NotificationCenter.default.removeObserver(
            self, name: NSApplication.didBecomeActiveNotification, object: nil)
    }
}

@MainActor
protocol LoginService {
    var status: SMAppService.Status { get }
    func register() throws
    func unregister() throws
}

private struct SystemLoginService: LoginService {
    var status: SMAppService.Status { SMAppService.mainApp.status }
    func register() throws { try SMAppService.mainApp.register() }
    func unregister() throws { try SMAppService.mainApp.unregister() }
}
