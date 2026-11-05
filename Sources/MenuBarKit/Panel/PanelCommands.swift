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

    /// While `isActive`, calls `perform` for each left click in the app's windows
    /// that does not land on a text field or its field editor. The click still
    /// reaches its target.
    public func onClickOutsideTextInput(isActive: Bool, perform: @escaping () -> Void) -> some View {
        modifier(OutsideTextClickModifier(isActive: isActive, perform: perform))
    }
}

private struct OutsideTextClickModifier: ViewModifier {
    let isActive: Bool
    let perform: () -> Void

    @State private var monitor: Any?

    func body(content: Content) -> some View {
        content
            .onAppear { update(isActive) }
            .onChange(of: isActive) { _, active in update(active) }
            .onDisappear { update(false) }
    }

    private func update(_ active: Bool) {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        guard active else { return }
        let perform = perform
        // A panel stays key and plain SwiftUI content takes no focus, so a click
        // outside the field would leave it editing without this monitor.
        monitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { event in
            let hit = event.window?.contentView?.hitTest(event.locationInWindow)
            if !TextInputHit.isTextInput(hit) { MainActor.assumeIsolated { perform() } }
            return event
        }
    }
}
