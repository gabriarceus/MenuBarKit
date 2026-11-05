import AppKit
import SwiftUI

enum PanelEscape {
    static func handle(cancelEditing: () -> Bool, dismiss: () -> Void) {
        if !cancelEditing() { dismiss() }
    }
}

enum TextInputHit {
    /// Whether `view` is a text field or a field editor, the views that own text editing.
    static func isTextInput(_ view: NSView?) -> Bool {
        view is NSTextField || view is NSText
    }
}

extension View {
    /// Handles Escape: calls `cancelEditing` first and calls `dismiss` only when it returns false.
    public func panelEscape(
        cancelEditing: @escaping () -> Bool = { false }, dismiss: @escaping () -> Void
    ) -> some View {
        onExitCommand { PanelEscape.handle(cancelEditing: cancelEditing, dismiss: dismiss) }
    }

    /// While `isActive`, calls the latest `perform` for each left click in the app's windows
    /// that lands neither inside this view nor on a text field or its field editor.
    /// The click still reaches its target. The monitor stays installed until `isActive`
    /// becomes false or the view disappears, so set `isActive` to false when the panel hides.
    public func onClickOutsideTextInput(isActive: Bool, perform: @escaping () -> Void) -> some View {
        modifier(OutsideTextClickModifier(isActive: isActive, perform: perform))
    }
}

/// Values the event monitor reads at click time, refreshed on every body pass.
@MainActor
private final class OutsideTextClickState {
    var perform: () -> Void = {}
    /// The modified view's frame in its window's content view, top-left origin.
    var frame: CGRect = .zero
    var monitor: Any?
}

private struct OutsideTextClickModifier: ViewModifier {
    let isActive: Bool
    let perform: () -> Void

    @State private var state = OutsideTextClickState()

    func body(content: Content) -> some View {
        state.perform = perform
        return
            content
            .onGeometryChange(for: CGRect.self) {
                $0.frame(in: .global)
            } action: {
                state.frame = $0
            }
            .onAppear { update(isActive) }
            .onChange(of: isActive) { _, active in update(active) }
            .onDisappear { update(false) }
    }

    private func update(_ active: Bool) {
        if let monitor = state.monitor { NSEvent.removeMonitor(monitor) }
        state.monitor = nil
        guard active else { return }
        let state = state
        // A panel stays key and plain SwiftUI content takes no focus, so a click
        // outside the field would leave it editing without this monitor.
        state.monitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { event in
            MainActor.assumeIsolated {
                guard let contentView = event.window?.contentView else { return state.perform() }
                // `.global` frames use the hosting content view's coordinates.
                // shortcut: the frame is not tied to a window, so a click at the same point in
                // another window of the app counts as inside; store the window if that matters.
                let point = contentView.convert(event.locationInWindow, from: nil)
                let flipped =
                    contentView.isFlipped ? point : CGPoint(x: point.x, y: contentView.bounds.height - point.y)
                if state.frame.contains(flipped) { return }
                if !TextInputHit.isTextInput(contentView.hitTest(event.locationInWindow)) { state.perform() }
            }
            return event
        }
    }
}
