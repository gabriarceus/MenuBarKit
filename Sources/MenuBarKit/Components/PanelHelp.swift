import SwiftUI

@MainActor
final class HelpPresentation: ObservableObject {
    @Published private(set) var isPresented = false
    private(set) var pendingTask: Task<Void, Never>?

    func schedule() {
        cancel()
        pendingTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(350))
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

extension EnvironmentValues {
    fileprivate var panelHelpEnabled: Bool {
        get { self[HelpEnabledKey.self] }
        set { self[HelpEnabledKey.self] = newValue }
    }
}

private struct PanelHelp: ViewModifier {
    let text: String
    @Environment(\.panelHelpEnabled) private var isEnabled
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
            presentation.schedule()
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
        Text(text)
            .font(.caption2)
            .lineLimit(nil)
            .foregroundStyle(.primary)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .frame(
                maxWidth: max(0, min(260, container.width - 8)),
                maxHeight: max(0, container.height - 8)
            )
            .fixedSize(horizontal: false, vertical: true)
            .clipped()
            .background(.regularMaterial, in: .rect(cornerRadius: 5))
            .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(.quaternary))
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

extension View {
    /// Adds delayed panel help as an accessibility hint without replacing the control's name.
    public func panelHelp(_ text: String) -> some View {
        modifier(PanelHelp(text: text))
    }

    /// Hosts help outside inner scrolling clips. Set isActive to false when retained content closes.
    public func panelHelpHost(isActive: Bool = true) -> some View {
        environment(\.panelHelpEnabled, isActive)
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
