import AppKit
import Combine
import SwiftUI

/// Publishes the current macOS accent color and keeps it up to date when the
/// user changes it in System Settings. With the "Multicolor" accent, the
/// system resolves the color to the default blue.
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

    /// Accent resolved to a concrete color so a change always publishes a new value.
    private static func currentAccent() -> Color {
        Color(nsColor: NSColor.controlAccentColor.usingColorSpace(.sRGB) ?? .controlAccentColor)
    }
}
