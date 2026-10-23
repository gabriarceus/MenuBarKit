import AppKit
import MenuBarKit
import SwiftUI

@MainActor
final class BaselineState: ObservableObject {
    @Published var tinted = false
    @Published var tintOpacity = 0.3
    @Published var expanded = false
}

struct BaselineContent: View {
    @ObservedObject var state: BaselineState
    let title: String
    @State private var text = "Editable value"
    @State private var count = 0
    @FocusState private var focused: Bool

    var body: some View {
        PanelChrome(tint: state.tinted ? Color.blue.opacity(state.tintOpacity) : nil) {
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

private struct StandaloneButtons: View {
    @State private var count = 0

    var body: some View {
        VStack(spacing: Theme.Spacing.l) {
            Text("Actions: \(count)")
            HStack {
                GlassIconButton(systemImage: "plus", accessibilityLabel: "Increment") { count += 1 }
                GlassIconButton(systemImage: "plus", accessibilityLabel: "Disabled action") {
                    count += 1
                }
                .disabled(true)
            }
        }
        .padding(Theme.Spacing.l)
        .frame(width: 300, height: 120)
    }
}

@MainActor
final class BaselineDelegate: NSObject, NSApplicationDelegate {
    private let state = BaselineState()
    private var panels: [MenuBarPanel] = []
    private var controls: NSWindow!
    private var standaloneButton: NSWindow?
    private var standaloneChrome: NSWindow?
    private var backdrop: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let menu = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(
            withTitle: "Show controls", action: #selector(showControls), keyEquivalent: "0"
        )
        .target = self
        for (title, action) in [
            ("Show test background", #selector(showBackdrop)),
            ("Weaker tint", #selector(useWeakTint)),
            ("Consumer tint", #selector(useConsumerTint)),
            ("Stronger tint", #selector(useStrongTint)),
            ("System appearance", #selector(useSystemAppearance)),
            ("Forced appearances", #selector(useForcedAppearances)),
            ("Record metrics", #selector(recordMetrics)),
            ("Run workload", #selector(runWorkload)),
        ] {
            appMenu.addItem(withTitle: title, action: action, keyEquivalent: "").target = self
        }
        appMenu.addItem(
            withTitle: "Quit baseline", action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q")
        appItem.submenu = appMenu
        menu.addItem(appItem)
        let editItem = NSMenuItem()
        editItem.title = "Edit"
        let editMenu = NSMenu(title: "Edit")
        for (title, action, key) in [
            ("Cut", #selector(NSText.cut(_:)), "x"),
            ("Copy", #selector(NSText.copy(_:)), "c"),
            ("Paste", #selector(NSText.paste(_:)), "v"),
            ("Select All", #selector(NSText.selectAll(_:)), "a"),
        ] {
            editMenu.addItem(withTitle: title, action: action, keyEquivalent: key)
        }
        editItem.submenu = editMenu
        menu.addItem(editItem)
        NSApp.mainMenu = menu
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
            contentRect: NSRect(x: 100, y: 120, width: 360, height: 300),
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
                Button("Record metrics") { self.recordMetrics() }
                Button("Show standalone button") { self.showStandaloneButton() }
                Button("Show standalone chrome") { self.showStandaloneChrome() }
                Button("Quit baseline") { NSApp.terminate(nil) }
            }.padding()
        )
        controls.makeKeyAndOrderFront(nil)
        showPanels()
    }

    private func showPanels() {
        for index in panels.indices { showPanel(at: index) }
    }

    @objc private func showControls() {
        controls.makeKeyAndOrderFront(nil)
    }

    private func cpuTime() -> Double {
        var usage = rusage()
        getrusage(RUSAGE_SELF, &usage)
        return
            Double(usage.ru_utime.tv_sec + usage.ru_stime.tv_sec)
            + Double(usage.ru_utime.tv_usec + usage.ru_stime.tv_usec) / 1_000_000
    }

    @objc private func recordMetrics() {
        let workspace = NSWorkspace.shared
        var lines = [
            "Time: \(Date().timeIntervalSince1970)", "CPU seconds: \(cpuTime())",
            "Active: \(NSApp.isActive)", "Tint: \(state.tinted), opacity: \(state.tintOpacity)",
            "Reduce Transparency: \(workspace.accessibilityDisplayShouldReduceTransparency)",
            "Increase Contrast: \(workspace.accessibilityDisplayShouldIncreaseContrast)",
            "Reduce Motion: \(workspace.accessibilityDisplayShouldReduceMotion)",
            "VoiceOver: \(workspace.isVoiceOverEnabled)",
        ]
        for panel in panels {
            lines.append(
                "\(panel.title): visible=\(panel.isVisible), key=\(panel.isKeyWindow), frame=\(panel.frame), appearance=\(panel.effectiveAppearance.name.rawValue)"
            )
        }
        func appendHierarchy(_ view: NSView, indent: String = "") {
            var detail = ""
            switch view {
            case let effect as NSVisualEffectView:
                detail =
                    " material=\(effect.material.rawValue), blending=\(effect.blendingMode.rawValue), state=\(effect.state.rawValue)"
            default:
                break
            }
            lines.append(
                "\(indent)\(String(reflecting: type(of: view))) frame=\(view.frame)\(detail)")
            for child in view.subviews { appendHierarchy(child, indent: indent + "  ") }
        }
        for window in panels + [standaloneButton, standaloneChrome].compactMap({ $0 }) {
            lines.append("Hierarchy: \(window.title)")
            if let content = window.contentView { appendHierarchy(content) }
        }
        try! lines.joined(separator: "\n").write(
            toFile: "/private/tmp/menubarkit-baseline-metrics.txt", atomically: true,
            encoding: .utf8)
    }

    @objc private func useWeakTint() {
        state.tintOpacity = 0.1
        state.tinted = true
    }
    @objc private func useConsumerTint() {
        state.tintOpacity = 0.3
        state.tinted = true
    }
    @objc private func useStrongTint() {
        state.tintOpacity = 0.6
        state.tinted = true
    }

    @objc private func useSystemAppearance() {
        for panel in panels { panel.appearance = nil }
    }

    @objc private func useForcedAppearances() {
        panels[0].appearance = NSAppearance(named: .aqua)
        panels[1].appearance = NSAppearance(named: .darkAqua)
    }

    @objc private func showBackdrop() {
        if backdrop == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 40, y: 800, width: 860, height: 440),
                styleMask: [.titled, .closable], backing: .buffered, defer: false)
            window.title = "Material test background"
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(
                rootView: HStack(spacing: 0) {
                    Color.white
                    Color.black
                    Color.red
                    Color.blue
                    Color.green
                })
            backdrop = window
        }
        backdrop?.orderFrontRegardless()
        showPanels()
    }

    @objc private func runWorkload() {
        Task {
            state.tintOpacity = 0.3
            state.tinted = true
            state.expanded = false
            var lines: [String] = []
            for sample in 1...3 {
                let start = Date()
                let startCPU = cpuTime()
                var failures = 0
                for _ in 0..<10 {
                    showPanels()
                    let frames = panels.map(\.frame)
                    try! await Task.sleep(for: .milliseconds(200))
                    state.expanded = true
                    try! await Task.sleep(for: .milliseconds(100))
                    for (panel, frame) in zip(panels, frames) {
                        if abs(panel.frame.minX - frame.minX) > 0.5
                            || abs(panel.frame.maxY - frame.maxY) > 0.5
                            || panel.frame.height <= frame.height
                        {
                            failures += 1
                        }
                    }
                    state.expanded = false
                    try! await Task.sleep(for: .milliseconds(100))
                    for panel in panels { panel.dismiss() }
                    try! await Task.sleep(for: .milliseconds(100))
                }
                lines.append(
                    "Sample \(sample): wall=\(Date().timeIntervalSince(start)), cpu=\(cpuTime() - startCPU), geometry failures=\(failures)"
                )
            }
            showPanels()
            try! (lines.joined(separator: "\n") + "\n").write(
                toFile: "/private/tmp/menubarkit-workload.txt", atomically: true, encoding: .utf8)
        }
    }

    private func showStandaloneButton() {
        if standaloneButton == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 900, y: 500, width: 300, height: 120),
                styleMask: [.titled, .closable], backing: .buffered, defer: false)
            window.title = "Standalone button"
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: StandaloneButtons())
            standaloneButton = window
        }
        standaloneButton?.makeKeyAndOrderFront(nil)
    }

    private func showStandaloneChrome() {
        if standaloneChrome == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 900, y: 700, width: 300, height: 140),
                styleMask: [.titled, .closable], backing: .buffered, defer: false)
            window.title = "Standalone chrome"
            window.isReleasedWhenClosed = false
            window.isOpaque = false
            window.backgroundColor = .clear
            window.contentView = NSHostingView(
                rootView: PanelChrome(tint: Color.blue.opacity(0.3)) {
                    Text("Standalone chrome")
                        .frame(width: 268, height: 108)
                }
                .padding(16))
            standaloneChrome = window
        }
        standaloneChrome?.makeKeyAndOrderFront(nil)
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
