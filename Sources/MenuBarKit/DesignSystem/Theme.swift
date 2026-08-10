import SwiftUI

/// Design tokens shared by menu-bar panel apps so they read as one design language.
public enum Theme {
    public enum Spacing {
        public static let xs: CGFloat = 4
        public static let s: CGFloat = 8
        public static let m: CGFloat = 12
        public static let l: CGFloat = 16
    }

    public enum Radius {
        public static let field: CGFloat = 7
        public static let card: CGFloat = 10
        public static let panel: CGFloat = 16
    }

    public enum Colors {
        public static let statusPositive: Color = .green
        public static let statusCaution: Color = .yellow
        public static let statusCritical: Color = .red
        public static let barTrack: Color = .primary.opacity(0.12)
    }

    public enum Typography {
        public static let rowTitle: Font = .subheadline.weight(.medium)
        public static let rowValue: Font = .subheadline.weight(.semibold).monospacedDigit()
        public static let fieldLabel: Font = .caption2.weight(.semibold)
        public static let footnote: Font = .caption
    }

    public static let defaultPanelWidth: CGFloat = 340
}
