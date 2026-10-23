import AppKit
import MenuBarKit
import SwiftUI

@MainActor
final class BaselineState: ObservableObject {
    @Published var tinted = false
    @Published var expanded = false
}

struct BaselineContent: View {
    @ObservedObject var state: BaselineState
    let title: String
    @State private var text = "Editable value"
    @State private var count = 0
    @FocusState private var focused: Bool

    var body: some View {
        PanelChrome(tint: state.tinted ? Color.blue.opacity(0.3) : nil) {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                PanelHeader(title: title) {
                    GlassIconButton(systemImage: "plus", accessibilityLabel: "Increment") {
                        count += 1
                    }
                }
                MeterRow(title: "Actions", valueText: "\(count)", tint: .blue, fraction: 0.6)
                SectionLabel("Text input")
                TextField("Value", text: $text)
                    .focused($focused)
                    .inputChrome(focused: focused)
                if state.expanded {
                    Text("Additional content")
                        .frame(height: 100)
                }
                HStack {
                    Button("Resize") { state.expanded.toggle() }
                    Button("Tint") { state.tinted.toggle() }
                }
            }
            .padding(Theme.Spacing.l)
            .frame(width: Theme.defaultPanelWidth)
        }
    }
}

@MainActor
final class BaselineDelegate: NSObject, NSApplicationDelegate {
    private let state = BaselineState()
    private var panels: [MenuBarPanel] = []
    private var controls: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        for (title, appearance) in [
            ("Light baseline", NSAppearance.Name.aqua),
            ("Dark baseline", NSAppearance.Name.darkAqua),
        ] {
            let panel = MenuBarPanel(
                rootView: BaselineContent(state: state, title: title),
                width: Theme.defaultPanelWidth
            )
            panel.title = title
            panel.appearance = NSAppearance(named: appearance)
            panels.append(panel)
        }
        controls = NSWindow(
            contentRect: NSRect(x: 100, y: 120, width: 360, height: 180),
            styleMask: [.titled, .closable], backing: .buffered, defer: false
        )
        controls.title = "MenuBarKit baseline controls"
        controls.isReleasedWhenClosed = false
        controls.contentView = NSHostingView(
            rootView: VStack(spacing: Theme.Spacing.m) {
                Button("Show panels") { self.showPanels() }
                Button("Show light panel") { self.showPanel(at: 0) }
                Button("Show dark panel") { self.showPanel(at: 1) }
                Button("Hide panels") {
                    for panel in self.panels { panel.dismiss() }
                }
                Button("Quit baseline") { NSApp.terminate(nil) }
            }.padding()
        )
        controls.makeKeyAndOrderFront(nil)
        showPanels()
    }

    private func showPanels() {
        for index in panels.indices { showPanel(at: index) }
    }

    private func showPanel(at index: Int) {
        let screen = NSScreen.main!.visibleFrame
        panels[index].present(
            at: NSPoint(x: screen.minX + 80 + CGFloat(index) * 400, y: screen.maxY - 80))
    }
}

@main
enum BaselineHost {
    static func main() {
        let app = NSApplication.shared
        let delegate = BaselineDelegate()
        app.setActivationPolicy(.regular)
        app.delegate = delegate
        app.run()
        withExtendedLifetime(delegate) {}
    }
}
