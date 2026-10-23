import AppKit
import SwiftUI

/// Rounded translucent chrome for content in a transparent panel.
/// Uses Liquid Glass on macOS 26 and later, and native popover material on earlier systems.
public struct PanelChrome<Content: View>: View {
    private let tint: Color?
    private let content: Content

    /// - Parameter tint: optional color washed over the surface while keeping its
    ///   translucency; the color's opacity controls the tint strength.
    public init(tint: Color? = nil, @ViewBuilder content: () -> Content) {
        self.tint = tint
        self.content = content()
    }

    public var body: some View {
        if #available(macOS 26.0, *) {
            content
                .glassEffect(glass, in: .rect(cornerRadius: Theme.Radius.panel, style: .continuous))
        } else {
            content
                .background {
                    VisualEffectBackground()
                        .overlay { tint }
                        .clipShape(.rect(cornerRadius: Theme.Radius.panel, style: .continuous))
                        .allowsHitTesting(false)
                }
        }
    }

    @available(macOS 26.0, *)
    private var glass: Glass {
        if let tint {
            .regular.tint(tint)
        } else {
            .regular
        }
    }
}

private struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .popover
        view.blendingMode = .behindWindow
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
