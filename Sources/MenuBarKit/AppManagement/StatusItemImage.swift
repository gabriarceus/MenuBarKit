import AppKit

@MainActor
enum StatusItemImage {
    static func make(icon: NSImage, hasBadge: Bool) -> NSImage {
        let base = icon.copy() as! NSImage
        guard hasBadge else {
            base.isTemplate = true
            return base
        }
        let diameter: CGFloat = 4
        let gap: CGFloat = 1.5
        let canvas = NSSize(width: base.size.width + gap + diameter, height: base.size.height)
        let image = NSImage(size: canvas, flipped: false) { _ in
            base.draw(in: NSRect(origin: .zero, size: base.size))
            NSColor.black.setFill()
            NSBezierPath(
                ovalIn: NSRect(
                    x: canvas.width - diameter, y: canvas.height - diameter,
                    width: diameter, height: diameter
                )
            ).fill()
            return true
        }
        image.isTemplate = true
        return image
    }
}
