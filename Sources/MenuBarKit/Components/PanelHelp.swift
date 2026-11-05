import SwiftUI

/// Presentation state of one help target, set after a delay.
@MainActor
final class HelpPresentation: ObservableObject {
    @Published private(set) var isPresented = false
    private(set) var pendingTask: Task<Void, Never>?

    func schedule(after delay: Duration) {
        cancel()
        pendingTask = Task { [weak self] in
            do {
                try await Task.sleep(for: delay)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            self?.isPresented = true
        }
    }

    func cancel() {
        pendingTask?.cancel()
        pendingTask = nil
        isPresented = false
    }

    deinit {
        pendingTask?.cancel()
    }
}

enum HelpPlacement {
    /// Bubble frame centered on `target`, above it when there is room, and clamped inside `container`.
    static func frame(target: CGRect, bubble: CGSize, container: CGSize) -> CGRect {
        let margin = min(4, max(0, min(container.width, container.height) / 2))
        let size = CGSize(
            width: min(bubble.width, max(0, container.width - margin * 2)),
            height: min(bubble.height, max(0, container.height - margin * 2))
        )
        let maxX = max(margin, container.width - margin - size.width)
        let maxY = max(margin, container.height - margin - size.height)
        let above = target.minY - margin - size.height
        let y = above >= margin ? above : target.maxY + margin
        return CGRect(
            x: min(max(target.midX - size.width / 2, margin), maxX),
            y: min(max(y, margin), maxY),
            width: size.width,
            height: size.height
        )
    }
}

private struct HelpValue {
    let text: String
    let anchor: Anchor<CGRect>
}

private struct HelpKey: PreferenceKey {
    static let defaultValue: HelpValue? = nil

    static func reduce(value: inout HelpValue?, nextValue: () -> HelpValue?) {
        if let next = nextValue() { value = next }
    }
}

private struct HelpEnabledKey: EnvironmentKey {
    static let defaultValue = true
}

private struct HelpDelayKey: EnvironmentKey {
    static let defaultValue = PanelHelpDefaults.delay
}

@usableFromInline
enum PanelHelpDefaults {
    @usableFromInline static let delay: Duration = .seconds(1)
    static let maxWidth: CGFloat = 260
}

extension EnvironmentValues {
    fileprivate var panelHelpEnabled: Bool {
        get { self[HelpEnabledKey.self] }
        set { self[HelpEnabledKey.self] = newValue }
    }

    fileprivate var panelHelpDelay: Duration {
        get { self[HelpDelayKey.self] }
        set { self[HelpDelayKey.self] = newValue }
    }
}

private struct PanelHelp: ViewModifier {
    let text: String
    @Environment(\.panelHelpEnabled) private var isEnabled
    @Environment(\.panelHelpDelay) private var delay
    @StateObject private var presentation = HelpPresentation()
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .onHover { hovered in
                isHovered = hovered
                update()
            }
            .onChange(of: text) { update() }
            .onChange(of: isEnabled) {
                isHovered = false
                presentation.cancel()
            }
            .onDisappear {
                isHovered = false
                presentation.cancel()
            }
            .anchorPreference(key: HelpKey.self, value: .bounds) { anchor in
                presentation.isPresented && isEnabled ? HelpValue(text: text, anchor: anchor) : nil
            }
            .accessibilityHint(Text(text))
    }

    private func update() {
        if isHovered && isEnabled && !text.isEmpty {
            presentation.schedule(after: delay)
        } else {
            presentation.cancel()
        }
    }
}

private struct HelpBubble: View {
    let text: String
    let target: CGRect
    let container: CGSize
    @State private var size: CGSize = .zero

    var body: some View {
        let frame = HelpPlacement.frame(target: target, bubble: size, container: container)
        HelpBubbleLabel(
            text: text,
            maxWidth: max(0, min(PanelHelpDefaults.maxWidth, container.width - 8)),
            maxHeight: max(0, container.height - 8)
        )
        .onGeometryChange(for: CGSize.self) {
            $0.size
        } action: {
            size = $0
        }
        .position(x: frame.midX, y: frame.midY)
        .opacity(size == .zero ? 0 : 1)
        .accessibilityHidden(true)
    }
}

/// Bubble text and chrome, as wide as the text needs up to `maxWidth`, wrapping beyond it.
struct HelpBubbleLabel: View {
    let text: String
    let maxWidth: CGFloat
    let maxHeight: CGFloat

    var body: some View {
        WidthLimit(maxWidth: maxWidth) {
            Text(text)
                .font(.caption2)
                .lineLimit(nil)
                .foregroundStyle(.primary)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
        }
        .frame(maxHeight: maxHeight)
        .fixedSize(horizontal: false, vertical: true)
        .clipped()
        .background(.regularMaterial, in: .rect(cornerRadius: 5))
        .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(.quaternary))
    }
}

// `frame(maxWidth:)` would grow to the whole proposed width, even for one word.
/// Proposes at most `maxWidth` to its content and takes the size the content returns.
private struct WidthLimit: Layout {
    let maxWidth: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let content = subviews.first else { return .zero }
        let width = min(proposal.width ?? maxWidth, maxWidth)
        return content.sizeThatFits(ProposedViewSize(width: width, height: nil))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(at: bounds.origin, proposal: ProposedViewSize(bounds.size))
    }
}

extension View {
    /// Adds delayed panel help as an accessibility hint without replacing the control's name.
    public func panelHelp(_ text: String) -> some View {
        modifier(PanelHelp(text: text))
    }

    /// Draws the help of `panelHelp(_:)` targets below it, outside inner scroll clipping. While
    /// `isActive` is false, no help appears and pending help is cancelled.
    /// - Parameter delay: how long the pointer must rest on a target before its help appears.
    public func panelHelpHost(isActive: Bool = true, delay: Duration = PanelHelpDefaults.delay) -> some View {
        environment(\.panelHelpEnabled, isActive)
            .environment(\.panelHelpDelay, delay)
            .overlayPreferenceValue(HelpKey.self) { value in
                GeometryReader { proxy in
                    if isActive, let value {
                        HelpBubble(
                            text: value.text, target: proxy[value.anchor], container: proxy.size)
                    }
                }
                .allowsHitTesting(false)
            }
    }
}
