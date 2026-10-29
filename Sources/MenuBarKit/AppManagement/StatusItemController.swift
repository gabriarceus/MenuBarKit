import AppKit
import Combine

/// Opt-in actions for one caller-owned status item and panel. Retain until disconnected.
@MainActor
public final class StatusItemController: NSObject, ObservableObject {
    @Published public private(set) var isPresented = false
    public var secondaryMenu: NSMenu?

    private let statusItem: NSStatusItem
    private let panel: MenuBarPanel
    private let position: () -> NSPoint?
    private let fittingBounds: (() -> NSRect?)?
    private weak var previousTarget: AnyObject?
    private let previousAction: Selector?
    private let previousMenu: NSMenu?
    private var previousEventMask: NSEvent.EventTypeMask = []
    private var isConnected = true
    private var isPresentationPending = false

    /// Adopts the button action until disconnect. A nil position prevents presentation.
    public init(
        statusItem: NSStatusItem, panel: MenuBarPanel, position: @escaping () -> NSPoint?,
        fittingBounds: (() -> NSRect?)? = nil
    ) {
        precondition(
            panel.ignoreOutsideClick == nil && panel.presentationChanged == nil,
            "The panel already has a controller")
        self.statusItem = statusItem
        self.panel = panel
        self.position = position
        self.fittingBounds = fittingBounds
        self.previousTarget = statusItem.button?.target
        self.previousAction = statusItem.button?.action
        self.previousMenu = statusItem.menu
        super.init()

        if let button = statusItem.button {
            previousEventMask = .init(
                rawValue: .init(
                    truncatingIfNeeded: button.sendAction(on: [.leftMouseUp, .rightMouseUp])))
            button.target = self
            button.action = #selector(activate)
        }
        statusItem.menu = nil
        isPresented = panel.isVisible
        panel.ignoreOutsideClick = { [weak self] event in
            guard let self, let frame = self.statusItemFrame,
                let point = event.cgEvent?.unflippedLocation
            else { return false }
            return frame.contains(point)
        }
        panel.presentationChanged = { [weak self] visible in self?.isPresented = visible }
        if fittingBounds != nil {
            NotificationCenter.default.addObserver(
                self, selector: #selector(screensChanged),
                name: NSApplication.didChangeScreenParametersNotification, object: nil
            )
        }
    }

    /// Uses status-item geometry with screen fitting. The caller owns content height and scrolling.
    public convenience init(statusItem: NSStatusItem, panel: MenuBarPanel) {
        self.init(
            statusItem: statusItem, panel: panel,
            position: { PanelPlacement.below(statusItem, panelSize: panel.frame.size)?.topLeft },
            fittingBounds: { PanelPlacement.below(statusItem, panelSize: panel.frame.size)?.bounds }
        )
    }

    /// Toggles the same presentation action used by primary status-item activation.
    public func toggle() {
        guard isConnected else { return }
        if panel.isVisible || isPresentationPending {
            dismiss()
        } else {
            present()
        }
    }

    /// Queues presentation after status-button tracking. Repeated requests have no extra effect.
    public func present() {
        guard isConnected, !panel.isVisible, !isPresentationPending else { return }
        isPresentationPending = true
        DispatchQueue.main.async { [weak self] in
            guard let self, self.isConnected, self.isPresentationPending else { return }
            self.isPresentationPending = false
            guard let point = self.position() else { return }
            self.show(at: point)
        }
    }

    /// Cancels pending presentation and dismisses the panel.
    public func dismiss() {
        guard isConnected else { return }
        isPresentationPending = false
        panel.dismiss()
    }

    /// Updates a fresh template copy. A missing text or badge reserves no space for it.
    public func update(
        icon: NSImage, text: String? = nil, hasBadge: Bool = false, accessibilityLabel: String
    ) {
        guard isConnected, let button = statusItem.button else { return }
        button.image = StatusItemImage.make(icon: icon, hasBadge: hasBadge)
        button.title = text ?? ""
        button.imagePosition = button.title.isEmpty ? .imageOnly : .imageLeading
        button.contentTintColor = nil
        button.setAccessibilityLabel(accessibilityLabel)
    }

    /// Dismisses and restores the previous button interaction. Safe to call repeatedly.
    public func disconnect() {
        guard isConnected else { return }
        isConnected = false
        isPresentationPending = false
        panel.dismiss()
        panel.ignoreOutsideClick = nil
        panel.presentationChanged = nil
        NotificationCenter.default.removeObserver(
            self, name: NSApplication.didChangeScreenParametersNotification, object: nil)
        if let button = statusItem.button {
            button.target = previousTarget
            button.action = previousAction
            button.sendAction(on: previousEventMask)
            statusItem.menu = previousMenu
        }
    }

    isolated deinit {
        disconnect()
    }

    private var statusItemFrame: NSRect? {
        guard statusItem.isVisible, let button = statusItem.button, let window = button.window,
            let screen = window.screen
        else { return nil }
        let frame = window.convertToScreen(button.convert(button.bounds, to: nil))
        guard frame.width > 0, frame.height > 0, screen.frame.intersects(frame) else { return nil }
        return frame
    }

    private func show(at point: NSPoint) {
        if let bounds = fittingBounds?() {
            panel.present(at: point, fittingWithin: bounds)
        } else {
            panel.present(at: point)
        }
    }

    @objc private func screensChanged() {
        guard isConnected, panel.isVisible else { return }
        guard let point = position(), fittingBounds?() != nil else {
            dismiss()
            return
        }
        show(at: point)
    }

    @objc private func activate() {
        switch NSApp.currentEvent?.type {
        case .rightMouseUp:
            showSecondaryMenu()
        case .leftMouseUp where NSApp.currentEvent?.modifierFlags.contains(.control) == true:
            showSecondaryMenu()
        default:
            toggle()
        }
    }

    private func showSecondaryMenu() {
        guard isConnected, let menu = secondaryMenu, let button = statusItem.button else { return }
        statusItem.menu = menu
        defer { if isConnected { statusItem.menu = nil } }
        button.performClick(nil)
    }
}
