import SwiftUI

/// Capsule progress bar with an explicitly filled tint: unlike `ProgressView` with
/// `.tint`, the color does not desaturate when the hosting window is not key (a
/// menu-bar panel usually is not).
public struct MeterBar: View {
    private let fraction: Double
    private let tint: Color

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
    }
}
