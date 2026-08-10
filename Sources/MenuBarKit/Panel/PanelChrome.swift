import SwiftUI

/// Popover-style Liquid Glass chrome for content hosted in a borderless
/// transparent panel such as `MenuBarPanel`. The glass shape defines the panel
/// edge, so no extra clipping is needed.
///
/// Plan B if glass sampling misbehaves on a borderless clear panel (edge
/// artifacts, missing shadow): bridge AppKit's `NSGlassEffectView` as the panel
/// content wrapper instead of this modifier.
public struct PanelChrome<Content: View>: View {
    private let tint: Color?
    private let content: Content

    /// - Parameter tint: optional color washed over the glass while keeping its
    ///   translucency; the color's opacity controls the tint strength.
    public init(tint: Color? = nil, @ViewBuilder content: () -> Content) {
        self.tint = tint
        self.content = content()
    }

    public var body: some View {
        content
            .glassEffect(glass, in: .rect(cornerRadius: Theme.Radius.panel, style: .continuous))
    }

    private var glass: Glass {
        if let tint {
            .regular.tint(tint)
        } else {
            .regular
        }
    }
}
