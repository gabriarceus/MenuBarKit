import AppKit
import Combine
import SwiftUI

/// Publishes the macOS accent color and follows changes made in System Settings.
/// The Multicolor accent resolves to the default blue.
@MainActor
public final class SystemAccentObserver: ObservableObject {
    @Published public private(set) var color: Color

    private var cancellable: AnyCancellable?

    public init() {
        color = Self.currentAccent()
        cancellable = NotificationCenter.default
            .publisher(for: NSColor.systemColorsDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                MainActor.assumeIsolated { self?.color = Self.currentAccent() }
            }
    }

    /// The accent as an sRGB color.
    private static func currentAccent() -> Color {
        // A concrete color makes every change publish a new value.
        Color(nsColor: NSColor.controlAccentColor.usingColorSpace(.sRGB) ?? .controlAccentColor)
    }
}
