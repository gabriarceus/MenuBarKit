import SwiftUI

/// One metered quantity: title, tinted value, capsule bar, and an optional footnote.
public struct MeterRow: View {
    private let title: String
    private let valueText: String
    private let tint: Color
    private let fraction: Double
    private let footnote: String?

    /// - Parameter fraction: fill amount in `0...1`; values outside are clamped.
    public init(title: String, valueText: String, tint: Color, fraction: Double, footnote: String? = nil) {
        self.title = title
        self.valueText = valueText
        self.tint = tint
        self.fraction = fraction
        self.footnote = footnote
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                Text(title)
                    .font(Theme.Typography.rowTitle)
                Spacer()
                Text(valueText)
                    .font(Theme.Typography.rowValue)
                    .foregroundStyle(tint)
            }
            MeterBar(fraction: fraction, tint: tint)
            if let footnote {
                Text(footnote)
                    .font(Theme.Typography.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
