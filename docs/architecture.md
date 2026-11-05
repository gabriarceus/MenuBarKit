# Architecture

MenuBarKit is a SwiftPM library for macOS menu bar apps. It uses AppKit for the panel window and the status item, and SwiftUI for chrome and components. It has no external dependencies.

## Source map

Paths in this table are relative to [Sources/MenuBarKit](../Sources/MenuBarKit). Start with the owner of the behavior you need to change.

| Area           | Files                                                                                                                             | Responsibility                                                                          |
| -------------- | --------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| Panel window   | Panel/MenuBarPanel.swift                                                                                                          | Borderless floating panel, content sizing, top-left anchoring, outside-click dismissal  |
| Panel chrome   | Panel/PanelChrome.swift                                                                                                           | Liquid Glass surface and the native material fallback                                   |
| Placement      | Panel/PanelPlacement.swift                                                                                                        | Status-item anchor, screen selection, margins, and position fitting                     |
| Navigation     | Panel/PanelNavigation.swift                                                                                                       | Observable current screen                                                               |
| Commands       | Panel/PanelCommands.swift, AppManagement/EditMenu.swift                                                                           | Child-first Escape handling and responder-chain edit commands                           |
| Status item    | AppManagement/StatusItemController.swift, AppManagement/StatusItemImage.swift                                                     | Primary and secondary actions, presentation state, template icon with text and badge    |
| Login item     | AppManagement/LoginItem.swift                                                                                                     | ServiceManagement status mapping and explicit registration                              |
| Design tokens  | DesignSystem/Theme.swift, DesignSystem/SystemAccentObserver.swift                                                                 | Spacing, radius, colors, typography, panel width, and the live accent color             |
| Components     | Components/PanelHeader.swift, GlassIconButton.swift, MeterBar.swift, MeterRow.swift, SectionLabel.swift, PanelSection.swift, InputChrome.swift | Reusable SwiftUI building blocks for panel content                                      |
| Contextual help | Components/PanelHelp.swift                                                                                                       | Delayed help targets, the root host, bubble sizing, and placement                       |
| Localization   | Localization/Localization.swift, Localization/ResourceBundle.swift                                                                | Localizer, language options, and resource bundle lookup in a built app                  |
| Notifications  | Notifications/Notifier.swift                                                                                                      | Authorization, immediate and scheduled notifications, and bundle checks                 |
| Package strings | Resources/\*.lproj/Localizable.strings                                                                                           | Strings the package shows itself, such as accessibility labels                          |

## Ownership

The consumer creates and owns the app delegate, the status item, the panel's root view, persistence, and every user-visible string of its own. MenuBarKit provides the window, the surfaces, and components to fill it. App-management helpers adopt resources the app created: they install no app delegate and register nothing while a view is built.

`StatusItemController` takes over the status button's target, action, event mask, and menu while it is connected, and restores them on `disconnect()` or release. It is the only owner of the panel's outside-click and presentation hooks, and a panel accepts one controller.

## Panel behavior

`MenuBarPanel` is a borderless, non-activating `NSPanel` at pop-up-menu level. It does not track the status item, so it stays in place when a menu bar manager hides the icon. It can become key, so text fields work. Its size follows the SwiftUI content through the hosting controller's preferred content size.

Content-driven resizes keep the top-left corner fixed, so the panel grows downward. When fitting bounds are supplied, the position is clamped into them on presentation and on every resize. A global mouse-down monitor dismisses the panel on clicks in other apps; the controller ignores clicks on its own status button, comparing the original event position with the live button rectangle.

`presentationChanged` reports transitions made through `present` and `dismiss` only. A direct `orderOut` bypasses it.

## Rendering constraints

- The glass effect leaves faintly opaque pixels across the hosting view's full rectangle, so AppKit would cast a rectangular shadow with dark square corners. The panel masks the hosting layer to its corner radius and invalidates the shadow after presentation and after each resize.
- The glass renders asynchronously, so the shadow is recomputed again on the next run-loop pass after presentation.
- `MeterBar` fills its capsule with an explicit color: a tinted `ProgressView` loses saturation in a window that is not key, and a menu bar panel usually is not.
- Contextual help is drawn once by a host above the panel's scrolling content, so bubbles escape `ScrollView` clipping. Hiding the panel can keep the SwiftUI tree alive, so the host's `isActive` flag, not view disappearance, ends pending help.
- If glass sampling misbehaves on the borderless panel (edge artifacts, a missing shadow), the fallback design is to bridge AppKit's `NSGlassEffectView` as the content wrapper instead of the `glassEffect` modifier.

## Localization and resources

`Localizer` reads `.strings` tables from a bundle, with an optional forced language. Missing keys return the key itself. A format whose specifiers do not match the arguments is returned unformatted instead of crashing; `%%` is a literal percent sign. Without arguments, the string is returned verbatim.

Package strings live in the package resource bundle and follow the SwiftUI `locale` of the view that shows them. `Bundle.resourceBundle(named:fallback:)` finds a SwiftPM resource bundle in the built app's Resources directory. Its fallback is an autoclosure: the generated `Bundle.module` accessor probes an absolute build path, a read that must not happen in a shipped app.

## Platform support

The deployment target is macOS 15. macOS 26 and later are the primary platform: panels and icon buttons use Liquid Glass there, and native popover material and a bordered capsule below it. Tint opacity is preserved on the fallback; strong tints can reduce contrast with content of a similar color.

New capabilities may require a newer macOS through `@available`; the deployment target does not promise every future API on the minimum. Keep the SDK and Swift tools requirement separate from the runtime floor. A fallback should stay small. Raising the floor is an explicit release decision with migration notes. Each consumer sets its own deployment target.

For checks and runtime verification, read [Development](development.md).
