import SwiftUI

/// Capsule bar filled to `fraction` with an explicit `tint`, which keeps its color in a window that is not key.
public struct MeterBar: View {
    private let fraction: Double
    private let tint: Color
    @Environment(\.locale) private var locale

    /// - Parameter fraction: fill amount in `0...1`; values outside are clamped.
    public init(fraction: Double, tint: Color) {
        self.fraction = fraction
        self.tint = tint
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.Colors.barTrack)
                Capsule()
                    .fill(tint)
                    .frame(width: geometry.size.width * min(max(fraction, 0), 1))
            }
        }
        .frame(height: 6)
        .accessibilityElement()
        .accessibilityLabel(Self.progressLabel(language: locale.language.languageCode?.identifier))
        .accessibilityValue("\(Int((min(max(fraction, 0), 1) * 100).rounded()))%")
        .accessibilityAddTraits(.updatesFrequently)
    }

    /// The spoken bar name in `language`, or in the system language when nil.
    static func progressLabel(language: String?) -> String {
        Localizer(bundle: resources, language: language)("progress")
    }

    private static let resources = Bundle.resourceBundle(named: "MenuBarKit_MenuBarKit", fallback: .module)
}
