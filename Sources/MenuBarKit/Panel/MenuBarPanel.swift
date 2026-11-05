import AppKit
import SwiftUI

/// A borderless floating panel for popover-style content. It does not track the
/// status item, so it stays in place when a menu bar manager hides the icon. It
/// sizes itself to its SwiftUI content with the top-left corner fixed, and
/// dismisses on a mouse-down in another app.
public final class MenuBarPanel: NSPanel {
    /// Called after every dismissal, once the panel is hidden.
    public var onDismiss: (() -> Void)?

    private var clickMonitor: Any?
    /// Returns true for an outside click that must not dismiss the panel.
    var ignoreOutsideClick: ((NSEvent) -> Bool)?
    /// Called with true on presentation and false on dismissal.
    var presentationChanged: ((Bool) -> Void)?

    /// Top-left corner (screen coordinates) the panel is pinned to. While set,
    /// content-driven resizes are re-anchored so the panel grows downward instead
    /// of moving its top edge.
    private var anchorTopLeft: NSPoint?
    private var fittingBounds: NSRect?

    /// Creates a hidden panel that hosts `rootView`, with an initial width of `width` points.
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

    /// Always true: borderless windows are not key by default, and text fields need key status.
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

    /// Like `present(at:)`, and keeps the panel inside `bounds` on presentation and on every resize.
    /// The caller constrains content size and scrolling.
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
