import AppKit
import SwiftUI
import XCTest

@testable import MenuBarKit

final class StatusItemControllerTests: XCTestCase {
    @MainActor
    func testOutsideClickExclusionUsesTheOriginalEventPosition() async throws {
        _ = NSApplication.shared
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        defer { NSStatusBar.system.removeStatusItem(item) }
        item.button?.title = "Fixture"
        let panel = MenuBarPanel(rootView: Text("Content"), width: 340)
        let controller = StatusItemController(statusItem: item, panel: panel, position: { nil })
        defer { controller.disconnect() }
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
        let button = try XCTUnwrap(item.button)
        let window = try XCTUnwrap(button.window)
        let primary = try XCTUnwrap(NSScreen.screens.first)
        let frame = window.convertToScreen(button.convert(button.bounds, to: nil))
        let original = try XCTUnwrap(
            CGEvent(
                mouseEventSource: nil, mouseType: .leftMouseDown,
                mouseCursorPosition: CGPoint(x: frame.midX, y: primary.frame.maxY - frame.midY),
                mouseButton: .left
            ))
        let event = try XCTUnwrap(NSEvent(cgEvent: original))
        XCTAssertEqual(panel.ignoreOutsideClick?(event), true)
        original.location = CGPoint(x: frame.maxX + 100, y: primary.frame.maxY - frame.midY)
        let outside = try XCTUnwrap(NSEvent(cgEvent: original))
        XCTAssertEqual(panel.ignoreOutsideClick?(outside), false)
    }

    @MainActor
    func testIconUpdatesClearOptionalTextAndBadgeAndKeepAccessibleName() {
        _ = NSApplication.shared
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        defer { NSStatusBar.system.removeStatusItem(item) }
        let panel = MenuBarPanel(rootView: Text("Content"), width: 340)
        let controller = StatusItemController(statusItem: item, panel: panel, position: { nil })
        defer { controller.disconnect() }
        let icon = NSImage(size: NSSize(width: 16, height: 16))
        controller.update(
            icon: icon, text: "12", hasBadge: true, accessibilityLabel: "Panel action")
        XCTAssertEqual(item.button?.title, "12")
        controller.update(icon: icon, accessibilityLabel: "Panel action")
        XCTAssertEqual(item.button?.title, "")
        XCTAssertEqual(item.button?.imagePosition, .imageOnly)
        XCTAssertEqual(item.button?.image?.size, icon.size)
        XCTAssertEqual(item.button?.accessibilityLabel(), "Panel action")
    }

    @MainActor
    func testPresentationIsIdempotentAndKeepsExistingDismissalCallback() async {
        _ = NSApplication.shared
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        defer { NSStatusBar.system.removeStatusItem(item) }
        let panel = MenuBarPanel(rootView: Text("Content"), width: 340)
        var dismissals = 0
        panel.onDismiss = { dismissals += 1 }
        let controller = StatusItemController(
            statusItem: item, panel: panel, position: { NSPoint(x: 100, y: 500) })
        defer { controller.disconnect() }
        controller.present()
        controller.present()
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
        XCTAssertTrue(panel.isVisible)
        XCTAssertTrue(controller.isPresented)
        controller.dismiss()
        controller.dismiss()
        XCTAssertFalse(controller.isPresented)
        XCTAssertEqual(dismissals, 1)
        controller.present()
        controller.toggle()
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
        XCTAssertFalse(panel.isVisible)
        XCTAssertEqual(dismissals, 1)
    }

    @MainActor
    func testScreenChangesReevaluateBoundsAndMissingScreensDismiss() async {
        _ = NSApplication.shared
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        defer { NSStatusBar.system.removeStatusItem(item) }
        let panel = MenuBarPanel(rootView: Text("Content"), width: 340)
        var position: NSPoint? = NSPoint(x: 100, y: 500)
        var bounds: NSRect? = NSRect(x: 0, y: 0, width: 800, height: 600)
        let controller = StatusItemController(
            statusItem: item, panel: panel, position: { position }, fittingBounds: { bounds })
        defer { controller.disconnect() }
        controller.present()
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
        position = NSPoint(x: -500, y: 400)
        bounds = NSRect(x: -600, y: 0, width: 500, height: 500)
        NotificationCenter.default.post(
            name: NSApplication.didChangeScreenParametersNotification, object: nil)
        XCTAssertEqual(panel.frame.minX, -500)
        position = nil
        bounds = nil
        NotificationCenter.default.post(
            name: NSApplication.didChangeScreenParametersNotification, object: nil)
        XCTAssertFalse(panel.isVisible)
    }

    @MainActor
    func testDisconnectRestoresInteractionAndCancelsPendingPresentation() async {
        _ = NSApplication.shared
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        defer { NSStatusBar.system.removeStatusItem(item) }
        let target = NSObject()
        let action = Selector(("previousAction:"))
        let menu = NSMenu(title: "Existing menu")
        item.button?.target = target
        item.button?.action = action
        item.button?.sendAction(on: [.leftMouseDown])
        item.menu = menu
        let panel = MenuBarPanel(rootView: Text("Content"), width: 340)
        let controller = StatusItemController(statusItem: item, panel: panel, position: { .zero })
        controller.present()
        controller.disconnect()
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
        XCTAssertFalse(panel.isVisible)
        XCTAssertTrue(item.button?.target === target)
        XCTAssertEqual(item.button?.action, action)
        XCTAssertTrue(item.menu === menu)
        XCTAssertEqual(
            item.button?.sendAction(on: []), Int(NSEvent.EventTypeMask.leftMouseDown.rawValue))
        XCTAssertNil(panel.ignoreOutsideClick)
        XCTAssertNil(panel.presentationChanged)
        controller.disconnect()
    }

    @MainActor
    func testReleaseRestoresInteraction() {
        _ = NSApplication.shared
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        defer { NSStatusBar.system.removeStatusItem(item) }
        let target = NSObject()
        item.button?.target = target
        let panel = MenuBarPanel(rootView: Text("Content"), width: 340)
        var controller: StatusItemController? = StatusItemController(
            statusItem: item, panel: panel, position: { nil })
        XCTAssertTrue(item.button?.target === controller)
        controller = nil
        XCTAssertTrue(item.button?.target === target)
        XCTAssertNil(panel.ignoreOutsideClick)
    }

    @MainActor
    func testBadgeUpdatesStartFromInputImageAndKeepItUnchanged() {
        let icon = NSImage(size: NSSize(width: 16, height: 16))
        icon.isTemplate = false
        for _ in 0..<5 {
            let image = StatusItemImage.make(icon: icon, hasBadge: true)
            XCTAssertEqual(image.size, NSSize(width: 21.5, height: 16))
            XCTAssertTrue(image.isTemplate)
        }
        let plain = StatusItemImage.make(icon: icon, hasBadge: false)
        XCTAssertEqual(plain.size, icon.size)
        XCTAssertFalse(icon.isTemplate)
        XCTAssertFalse(plain === icon)
    }
}
