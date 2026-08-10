import SwiftUI

/// Small capsule-shaped icon button with an interactive Liquid Glass background.
/// Tinting with `primary` keeps it visible on any appearance: the glass lightens
/// in dark mode and darkens in light mode.
public struct GlassIconButton: View {
    private let systemImage: String
    private let action: () -> Void

    public init(systemImage: String, action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.tint(Color.primary.opacity(0.15)).interactive(), in: .capsule)
    }
}
