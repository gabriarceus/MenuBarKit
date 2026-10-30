import SwiftUI

/// Small capsule-shaped icon button with interactive Liquid Glass on macOS 26 and later.
/// Earlier systems use a bordered capsule with pressed and disabled feedback.
public struct GlassIconButton: View {
    private let systemImage: String
    private let accessibilityLabel: String?
    private let action: () -> Void

    /// - Parameter accessibilityLabel: spoken label for VoiceOver; when `nil`,
    ///   the system image name is used.
    public init(
        systemImage: String, accessibilityLabel: String? = nil, action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    public var body: some View {
        if #available(macOS 26.0, *) {
            button
                .buttonStyle(.plain)
                .glassEffect(.regular.tint(Color.primary.opacity(0.15)).interactive(), in: .capsule)
                .accessibilityLabel(accessibilityLabel ?? systemImage)
        } else {
            button
                .buttonStyle(CapsuleButtonStyle())
                .accessibilityLabel(accessibilityLabel ?? systemImage)
        }
    }

    private var button: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .contentShape(Capsule())
        }
    }
}

private struct CapsuleButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                Capsule()
                    .fill(Color.primary.opacity(configuration.isPressed ? 0.15 : 0.06))
            }
            .overlay {
                Capsule()
                    .strokeBorder(Color.primary.opacity(0.25), lineWidth: 1)
            }
            .opacity(isEnabled ? 1 : 0.5)
    }
}
