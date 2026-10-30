import AppKit

/// Opt-in responder-chain edit commands with caller-localized titles.
@MainActor
public enum EditMenu {
    /// Returns an existing edit menu or appends one, preserving all existing menus and commands.
    @discardableResult
    public static func install(
        in mainMenu: NSMenu, title: String, undo: String, redo: String,
        cut: String, copy: String, paste: String, selectAll: String
    ) -> NSMenu {
        let actions = [
            Selector(("undo:")), Selector(("redo:")), #selector(NSText.cut(_:)),
            #selector(NSText.copy(_:)), #selector(NSText.paste(_:)),
            #selector(NSText.selectAll(_:)),
        ]
        if let existing = mainMenu.items.compactMap(\.submenu).first(where: { menu in
            menu.title == title
                || menu.items.contains { item in item.action.map(actions.contains) == true }
        }) {
            return existing
        }

        let menu = NSMenu(title: title)
        menu.addItem(withTitle: undo, action: actions[0], keyEquivalent: "z")
        let redoItem = menu.addItem(withTitle: redo, action: actions[1], keyEquivalent: "z")
        redoItem.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(.separator())
        for (title, action, key) in [
            (cut, actions[2], "x"), (copy, actions[3], "c"),
            (paste, actions[4], "v"), (selectAll, actions[5], "a"),
        ] {
            menu.addItem(withTitle: title, action: action, keyEquivalent: key)
        }
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.submenu = menu
        mainMenu.addItem(item)
        return menu
    }
}
