import SwiftUI

enum PanelEscape {
    static func handle(cancelEditing: () -> Bool, dismiss: () -> Void) {
        if !cancelEditing() { dismiss() }
    }
}

extension View {
    /// Handles Escape: calls `cancelEditing` first and calls `dismiss` only when it returns false.
    public func panelEscape(
        cancelEditing: @escaping () -> Bool = { false }, dismiss: @escaping () -> Void
    ) -> some View {
        onExitCommand { PanelEscape.handle(cancelEditing: cancelEditing, dismiss: dismiss) }
    }
}
