import SwiftUI

/// A titled panel surface with caller-supplied content and an optional description.
public struct PanelSection<Content: View>: View {
    private let title: String
    private let description: String?
    private let content: Content

    /// A nil description adds no text or spacing below the content.
    public init(
        _ title: String,
        description: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.description = description
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            SectionLabel(title)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                content
                if let description {
                    Text(description)
                        .font(Theme.Typography.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(Theme.Spacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .fill(Color.primary.opacity(0.05))
            )
        }
    }
}
