import AppKit
import XCTest

@testable import MenuBarKit

final class PanelCommandsTests: XCTestCase {
    @MainActor
    func testEditMenuAddsNativeResponderCommandsAndPreservesOtherMenus() {
        let root = NSMenu()
        let existing = NSMenuItem(title: "File", action: nil, keyEquivalent: "")
        root.addItem(existing)
        let menu = install(in: root)
        XCTAssertTrue(root.items.first === existing)
        XCTAssertEqual(root.items.count, 2)
        let commands = menu.items.filter { !$0.isSeparatorItem }
        XCTAssertEqual(commands.map(\.keyEquivalent), ["z", "z", "x", "c", "v", "a"])
        XCTAssertTrue(commands.allSatisfy { $0.target == nil })
        XCTAssertEqual(commands[1].keyEquivalentModifierMask, [.command, .shift])
        XCTAssertTrue(install(in: root) === menu)
        XCTAssertEqual(root.items.count, 2)
    }

    @MainActor
    func testExistingLocalizedEditMenuIsNotReplacedOrModified() {
        let root = NSMenu()
        let menu = NSMenu(title: "Modifica")
        let copy = menu.addItem(
            withTitle: "Copia", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        let item = NSMenuItem()
        item.submenu = menu
        root.addItem(item)
        XCTAssertTrue(install(in: root) === menu)
        XCTAssertEqual(menu.items.count, 1)
        XCTAssertTrue(menu.items.first === copy)
    }

    func testEscapeCancelsChildBeforeDismissingPanel() {
        var events: [String] = []
        PanelEscape.handle(
            cancelEditing: {
                events.append("cancel")
                return true
            }, dismiss: { events.append("dismiss") })
        XCTAssertEqual(events, ["cancel"])
        PanelEscape.handle(
            cancelEditing: {
                events.append("cancel")
                return false
            }, dismiss: { events.append("dismiss") })
        XCTAssertEqual(events, ["cancel", "cancel", "dismiss"])
    }

    @MainActor
    private func install(in menu: NSMenu) -> NSMenu {
        EditMenu.install(
            in: menu, title: "Edit", undo: "Undo", redo: "Redo", cut: "Cut", copy: "Copy",
            paste: "Paste", selectAll: "Select All")
    }
}
