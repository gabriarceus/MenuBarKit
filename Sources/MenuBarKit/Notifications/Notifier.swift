import AppKit
import UserNotifications

/// Wrapper around `UNUserNotificationCenter`. Every method does nothing outside a `.app` bundle,
/// where the notification center aborts.
@MainActor
public final class Notifier: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    /// True when the user denied notifications for the app.
    @Published public private(set) var authorizationDenied = false

    /// Called when the notification center rejects a delivery request. The
    /// default implementation logs the error.
    public var onDeliveryError: ((Error) -> Void)?

    private let isBundled = Bundle.main.bundleURL.pathExtension == "app"

    public override init() {
        super.init()
        onDeliveryError = { error in
            NSLog("Notification delivery failed: %@", String(describing: error))
        }
    }

    /// Sets the notifier as the center's delegate, asks for alert and sound permission when it is
    /// not decided yet, and updates `authorizationDenied`.
    public func requestAuthorizationIfNeeded() {
        guard isBundled else { return }
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) {
                    granted, _ in
                    Task { @MainActor in self?.authorizationDenied = !granted }
                }
            case .denied:
                Task { @MainActor in self?.authorizationDenied = true }
            case .authorized, .provisional, .ephemeral:
                Task { @MainActor in self?.authorizationDenied = false }
            @unknown default:
                NSLog("Unknown notification authorization status: %ld", settings.authorizationStatus.rawValue)
            }
        }
    }

    /// Delivers a notification now. A rejected request goes to `onDeliveryError`.
    public func send(title: String, body: String) {
        guard isBundled else {
            NSLog("Notification suppressed (not running from a .app bundle): %@ — %@", title, body)
            return
        }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { [weak self] error in
            if let error {
                Task { @MainActor in self?.onDeliveryError?(error) }
            }
        }
    }

    /// Schedules a one-shot notification at `date`, replacing a pending request with the same
    /// `identifier`. A `date` that is not in the future removes that pending request instead. The
    /// system delivers it at that wall-clock time, also while the app is idle.
    public func schedule(title: String, body: String, at date: Date, identifier: String) {
        guard isBundled else {
            NSLog(
                "Scheduled notification suppressed (not running from a .app bundle): %@ — %@",
                title, body)
            return
        }
        let center = UNUserNotificationCenter.current()
        guard date.timeIntervalSinceNow > 0 else {
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
            return
        }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: identifier, content: content, trigger: trigger)
        center.add(request) { [weak self] error in
            if let error {
                Task { @MainActor in self?.onDeliveryError?(error) }
            }
        }
    }

    /// Cancels a pending scheduled notification by `identifier`. No-op if none is pending.
    public func cancelScheduled(identifier: String) {
        guard isBundled else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            identifier
        ])
    }

    /// Cancels every pending notification whose identifier starts with `prefix`, except `excluding`,
    /// including requests left by an earlier run of the app.
    public func cancelScheduled(prefix: String, excluding: String? = nil) {
        guard isBundled else { return }
        Task {
            let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
            let stale = requests.map(\.identifier)
                .filter { $0.hasPrefix(prefix) && $0 != excluding }
            guard !stale.isEmpty else { return }
            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: stale)
        }
    }

    /// Shows banners and plays sounds while the app is active.
    nonisolated public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
