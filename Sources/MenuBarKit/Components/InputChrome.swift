import SwiftUI

extension View {
    /// Applies the plain text field style and draws a bordered container, with an accent border while `focused`.
    public func inputChrome(focused: Bool) -> some View {
        textFieldStyle(.plain)
            .padding(.horizontal, Theme.Spacing.s)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.field, style: .continuous)
                    .fill(Color.primary.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.field, style: .continuous)
                    .strokeBorder(
                        focused ? Color.accentColor : Color.primary.opacity(0.25),
                        lineWidth: focused ? 1.5 : 1
                    )
            )
    }
}
