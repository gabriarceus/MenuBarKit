# Optional app management

MenuBarKit's components and explicit-coordinate panel API remain usable on their own. The following helpers adopt resources created by the app. They add no package dependencies, app delegate, persistence, or registration side effects during UI construction.

## Status item and panel actions

Retain one `StatusItemController` for a caller-created `NSStatusItem` and `MenuBarPanel`. Its convenience initializer uses the actual status-item geometry with screen fitting. The initializer with a `position` closure keeps placement under caller control; returning nil prevents presentation. Supply `fittingBounds` to that initializer when fitting is wanted.

```swift
import AppKit
import MenuBarKit

@MainActor
func connect(
    item: NSStatusItem, panel: MenuBarPanel, icon: NSImage,
    name: String, menu: NSMenu
) -> StatusItemController {
    let controller = StatusItemController(statusItem: item, panel: panel)
    controller.secondaryMenu = menu
    controller.update(icon: icon, hasBadge: false, accessibilityLabel: name)
    return controller
}
```

Use `present()`, `dismiss()`, and `toggle()` for app actions, including shortcuts. Presentation is queued after status-button tracking and can be cancelled before it runs. Primary activation toggles once; right-click or Control-click only opens the supplied secondary menu. Outside-click dismissal compares the original mouse-event position with the live status-button rectangle, avoiding dismissal and reopening from the same click. A missing secondary menu produces no secondary action.

The controller owns the button's target, action, event mask, and menu while connected. Call `disconnect()` before replacing those settings. Disconnecting or releasing the controller cancels pending presentation, dismisses the panel, removes its hooks and display observation, and restores the previous interaction. Existing `onDismiss` callbacks still run. The caller keeps ownership of the status item and removes it when appropriate.

`update` draws a fresh template copy, optionally with a notification dot and text. It keeps the source image unchanged. Passing no text or badge reserves no space for them; repeated updates from the same source do not accumulate decorations. Use `NSStatusItem.variableLength` for an item with changing image or text width. The latest image and text remain on the caller's item after disconnect.

`isPresented` publishes transitions made through the panel's `present` and `dismiss` APIs. Forward that state to retained root content's `.panelHelpHost(isActive:)`; keep any subscription free of strong ownership cycles. Direct native `orderOut` calls bypass the shared presentation contract.

## Screen fitting and content height

`PanelPlacement.below(item, panelSize:)` returns a top-left position and usable `bounds`, with an eight-point screen margin and a six-point anchor gap. It uses a status-button rectangle only when it has usable geometry on a live screen. `isVisible` alone is insufficient. Missing or hidden geometry falls back to the main or first screen; no screens returns nil.

Use those bounds to constrain the consumer's viewport and scrolling before presentation. The bounds belong to the selected display, including displays with negative origins. A fitting position alone cannot make oversized fixed-height content reachable: the app must constrain its width and height and provide scrolling when needed.

`panel.present(at: point, fittingWithin: bounds)` clamps the position on presentation and content-driven resizing. Growth can move the top edge upward to keep the panel within the supplied bounds. Oversized content aligns to the available top-left; the helper does not resize or scroll its content. `panel.present(at: point)` clears fitting and preserves the original explicit-coordinate behavior.

The controller's fitting mode re-evaluates position and bounds after display changes, dismissing if its providers no longer return usable geometry. Direct callers of the fitting overload must refresh their supplied bounds when screens change.

## Edit commands and Escape

Create or keep the app's normal main menu, then opt in to `EditMenu.install`. Every visible title comes from the caller's localization system. The helper returns an existing menu with edit commands or the supplied title, preserving its contents. If none exists, it appends a new Edit menu and leaves other menus in place. An existing partial menu remains the app's responsibility.

```swift
EditMenu.install(
    in: mainMenu, title: editTitle, undo: undoTitle, redo: redoTitle,
    cut: cutTitle, copy: copyTitle, paste: pasteTitle, selectAll: selectAllTitle
)
```

The commands use nil targets and standard key equivalents, allowing native fields and their undo managers to handle editing through the responder chain. The helper does not assign `NSApp.mainMenu`; the app keeps that lifecycle decision.

Apply `.panelEscape(cancelEditing:dismiss:)` to the root that owns cancellation. Return true when a child edit consumes Escape; only a false result dismisses the panel. Keep the child's draft and focus in the app. The modifier does not install a global event monitor or change the panel's default key handling.

## Launch at login

Retain a `LoginItem` to read the main app's actual ServiceManagement status. Initialization and app activation only refresh status. `setEnabled(_:)` is an explicit registration action; the adapter refreshes state after success or error and forwards errors to the caller. UI views should invoke it only from an explicit user action.

| Status | Consumer behavior |
| --- | --- |
| `enabled` | Show registration as enabled. |
| `disabled` | Show registration as disabled. |
| `requiresApproval` | Explain approval and offer an explicit `LoginItem.openSettings()` action. Do not claim login launch is enabled. |
| `unavailable(reason)` | Disable registration controls and localize the reason: an unbundled process, missing service, or unsupported future platform status. |

An unbundled process never accesses the native service or registers successfully. Repeated enable requests while enabled or awaiting approval do not register again. Disabling an enabled or approval-pending item requests removal. Registration does not follow view appearance, and no helper silently enables login.

The adapter refreshes on app activation, including return from System Settings. A consumer can call `refresh()` explicitly as well. Format native operation errors and the adapter's unavailable reasons with the app's localized UI. Opening System Settings changes no registration by itself.

For global shortcuts, use the separate [consumer integration guide](global-shortcuts.md).

## Verification

On 2026-10-29, all 35 XCTest tests passed on macOS 27.2. Native checks cover interaction restoration, release, cancellation, idempotent presentation, existing dismissal callbacks, image/text/name updates, the original-event click guard, screen-change handling, fitted resizing, and unchanged explicit-coordinate presentation. Geometry tests cover negative origins, missing anchors, display removal, and oversized content. Command checks preserve existing menus and give child cancellation priority. Login checks use a fake service for state mapping, approval, errors, unbundled execution, activation refresh, and release.

An isolated accessory-app bundle verified select-all, cut, copy, paste, undo, and redo in a real panel. The user confirmed primary and secondary status-item actions, reachable scrolling content after growth, and Escape cancelling the child before closing the panel. The temporary bundle's native login status was `notFound`, exposed as `unavailable(.serviceNotFound)`; real registration was not changed. Enabled and approval-pending login outcomes were verified with the fake service.

Runtime coverage is macOS 27.2. Physical display removal, macOS 15/26 checks, live login registration from an installed app, and full VoiceOver spoken output remain additional verification. The existing [compatibility track](macos-compatibility.md) stays open for its recorded checks.
