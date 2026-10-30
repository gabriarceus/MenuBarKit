import AppKit

/// A status-item position and usable screen bounds, inset by the panel margin.
public struct PanelPlacement {
    public let topLeft: NSPoint
    public let bounds: NSRect

    /// Resolves usable status-item geometry or a main-screen fallback. Returns nil without screens.
    @MainActor
    public static func below(_ statusItem: NSStatusItem, panelSize: NSSize) -> PanelPlacement? {
        let screens = NSScreen.screens
        var anchor: NSRect?
        if statusItem.isVisible, let button = statusItem.button, let window = button.window {
            anchor = window.convertToScreen(button.convert(button.bounds, to: nil))
        }
        return resolve(
            anchor: anchor,
            screens: screens.map { ScreenBounds(frame: $0.frame, visibleFrame: $0.visibleFrame) },
            mainIndex: screens.firstIndex { $0 === NSScreen.main },
            panelSize: panelSize
        )
    }

    static func resolve(
        anchor: NSRect?, screens: [ScreenBounds], mainIndex: Int?, panelSize: NSSize
    ) -> PanelPlacement? {
        let usableAnchor = anchor.flatMap { rect -> NSRect? in
            guard rect.width > 0, rect.height > 0, rect.minX.isFinite, rect.minY.isFinite,
                rect.width.isFinite, rect.height.isFinite,
                screens.contains(where: { $0.frame.intersects(rect) })
            else { return nil }
            return rect
        }
        let anchoredIndex = usableAnchor.flatMap { anchor in
            screens.firstIndex { $0.frame.intersects(anchor) }
        }
        guard let index = anchoredIndex ?? mainIndex ?? screens.indices.first else { return nil }
        let visible = screens[index].visibleFrame
        let margin = min(8, max(0, min(visible.width, visible.height) / 2))
        let bounds = visible.insetBy(dx: margin, dy: margin)
        let desired =
            usableAnchor.map { NSPoint(x: $0.midX - panelSize.width / 2, y: $0.minY - 6) }
            ?? NSPoint(x: bounds.maxX - panelSize.width, y: bounds.maxY)
        return PanelPlacement(
            topLeft: fit(desired, size: panelSize, bounds: bounds), bounds: bounds)
    }

    static func fit(_ topLeft: NSPoint, size: NSSize, bounds: NSRect) -> NSPoint {
        NSPoint(
            x: min(max(topLeft.x, bounds.minX), max(bounds.minX, bounds.maxX - size.width)),
            y: max(min(topLeft.y, bounds.maxY), min(bounds.maxY, bounds.minY + size.height))
        )
    }
}

struct ScreenBounds {
    let frame: NSRect
    let visibleFrame: NSRect
}
