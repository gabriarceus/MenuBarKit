import AppKit
import SwiftUI

/// A floating panel that presents popover-style content without anchoring to a
/// view. Unlike `NSPopover`, it does not track the status item, so once shown it
/// stays at its position even if a menu bar manager (Ice, Bartender, …) hides the
/// icon while it is open. It resizes to fit its SwiftUI content while keeping its
/// top-left corner fixed, and dismisses on a mouse-down outside its bounds.
public final class MenuBarPanel: NSPanel {
    /// Invoked right after the panel dismisses itself, so the owner can debounce a
    /// status-item click that would otherwise immediately reopen it.
    public var onDismiss: (() -> Void)?

    private var clickMonitor: Any?
    var ignoreOutsideClick: ((NSEvent) -> Bool)?
    var presentationChanged: ((Bool) -> Void)?

    /// Top-left corner (screen coordinates) the panel is pinned to. While set,
    /// content-driven resizes are re-anchored so the panel grows downward instead
    /// of moving its top edge.
    private var anchorTopLeft: NSPoint?
    private var fittingBounds: NSRect?

    public init(rootView: some View, width: CGFloat) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: width, height: 200),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        level = .popUpMenu
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovable = false
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
        animationBehavior = .utilityWindow

        // Drives the window size from the SwiftUI content; chrome (material, rounded
        // corners) lives in the content so the window can stay borderless and clear.
        let host = NSHostingController(rootView: rootView)
        host.sizingOptions = .preferredContentSize
        contentViewController = host

        // The glass backdrop fills the hosting view's rectangular bounds with
        // faintly opaque pixels, so the window shadow is cast for a rectangle —
        // a dark rim with squared corners around the rounded panel. Masking the
        // hosting view to the panel shape zeroes the alpha outside it.
        host.view.wantsLayer = true
        if let layer = host.view.layer {
            layer.cornerRadius = Theme.Radius.panel
            layer.cornerCurve = .continuous
            layer.masksToBounds = true
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reanchor),
            name: NSWindow.didResizeNotification,
            object: self
        )
    }

    /// Borderless windows do not become key by default, but the content needs key
    /// status for text editing (e.g. account fields in a settings form).
    public override var canBecomeKey: Bool { true }

    /// Re-pins the top-left after a content-driven resize. Moving only the origin
    /// posts a move (not a resize) notification, so this does not recurse.
    /// The shadow is recomputed as well: AppKit caches it from the previous
    /// content shape, leaving a dark rectangular outline around the rounded glass.
    @objc private func reanchor() {
        guard let top = anchorTopLeft, isVisible else { return }
        setFrameTopLeftPoint(resolvedTopLeft(top))
        invalidateShadow()
    }

    /// Positions the panel so its top-left corner sits at `topLeft` (screen
    /// coordinates) and shows it, arming the outside-click dismissal.
    public func present(at topLeft: NSPoint) {
        fittingBounds = nil
        show(at: topLeft)
    }

    /// Fits the position during presentation and growth. The caller constrains content size and scrolling.
    public func present(at topLeft: NSPoint, fittingWithin bounds: NSRect) {
        fittingBounds = bounds
        show(at: topLeft)
    }

    private func resolvedTopLeft(_ topLeft: NSPoint) -> NSPoint {
        guard let fittingBounds else { return topLeft }
        return PanelPlacement.fit(topLeft, size: frame.size, bounds: fittingBounds)
    }

    private func show(at topLeft: NSPoint) {
        anchorTopLeft = topLeft
        layoutIfNeeded()
        setFrameTopLeftPoint(resolvedTopLeft(topLeft))
        makeKeyAndOrderFront(nil)
        // The glass renders asynchronously; recompute the shadow once it has
        // drawn, or it is cast for an opaque rectangle (dark squared corners).
        DispatchQueue.main.async { [weak self] in
            self?.invalidateShadow()
        }
        if clickMonitor == nil {
            clickMonitor = NSEvent.addGlobalMonitorForEvents(
                matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
            ) { [weak self] event in
                guard self?.ignoreOutsideClick?(event) != true else { return }
                self?.dismiss()
            }
        }
        presentationChanged?(true)
    }

    /// Hides the panel and tears down the click monitor. Safe to call repeatedly.
    public func dismiss() {
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
            clickMonitor = nil
        }
        guard isVisible else { return }
        orderOut(nil)
        anchorTopLeft = nil
        fittingBounds = nil
        presentationChanged?(false)
        onDismiss?()
    }
}
