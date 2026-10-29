import SwiftUI

enum PanelEscape {
    static func handle(cancelEditing: () -> Bool, dismiss: () -> Void) {
        if !cancelEditing() { dismiss() }
    }
}

extension View {
    /// Handles Escape after child cancellation. Return true from cancelEditing when it consumes Escape.
    public func panelEscape(
        cancelEditing: @escaping () -> Bool = { false }, dismiss: @escaping () -> Void
    ) -> some View {
        onExitCommand { PanelEscape.handle(cancelEditing: cancelEditing, dismiss: dismiss) }
    }
}
