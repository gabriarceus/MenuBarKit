# MenuBarKit

A Swift package with the shared UI foundation for macOS menu bar apps, so they all read as one design language: a borderless floating panel, Liquid Glass chrome, design tokens, and a small set of reusable SwiftUI components.

**What it gives you:** the panel that drops down from the menu bar (window setup, glass background, sizing, positioning, outside-click dismissal), plus components to fill it — headers, icon buttons, meters, field labels — on top of shared spacing/radius/typography/color tokens. Helpers for user notifications and localization come along, since menu bar apps tend to need both.

**What it does not do:** it is not an app template. You still create the `NSStatusItem`, own the app delegate, and write your own screens; MenuBarKit only gives you the panel and the pieces inside it.

## Requirements

- Declared deployment target: macOS 15. Panels and icon buttons use Liquid Glass on macOS 26 and later, and native fallback surfaces on earlier systems. Runtime verification on macOS 15 remains pending; the current tested runtime is macOS 27.0.1.
- Xcode 26 / Swift 6.2 or newer, with the macOS 26 SDK or newer
- No external dependencies

## Installation

Add the package to your app's `Package.swift`:

```swift
let package = Package(
    name: "MyApp",
    platforms: [.macOS(.v26)], // Match the requirements of the MenuBarKit release you use.
    dependencies: [
        .package(url: "https://github.com/gabriarceus/MenuBarKit.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(name: "MyApp", dependencies: ["MenuBarKit"])
    ]
)
```

In an Xcode project instead: _File ▸ Add Package Dependencies…_ and paste the same URL.

The example keeps macOS 26 for compatibility with the 1.0 and 1.1 releases. The macOS 15 fallback is currently unreleased in this checkout. To evaluate it locally, use `.package(path: "../MenuBarKit")`; an app can declare `.macOS(.v15)` after auditing its own APIs, dependencies, bundle metadata, and packaging. A successful build does not replace testing on that runtime.

## Platform support policy

macOS 26 and later remain the primary platform. Existing panels and icon buttons select their native surface automatically. Older material differs from Liquid Glass; tint opacity is preserved, and strong tints can reduce contrast with similarly colored content. The current declared floor is macOS 15, while runtime verification from this work covers macOS 27.0.1 only. macOS 15 and macOS 26 checks remain pending.

New capabilities may require a newer macOS version through `@available`. A package deployment target does not require every future API to work on that minimum. Keep the modern SDK and Swift tools requirement separate from the runtime floor.

An older-system fallback should remain small and useful. Reassess the minimum if maintaining it would require duplicated window management, state, or architecture. Raising the floor is an explicit release decision with migration notes; there is no automatic annual support window. Each consumer remains responsible for its own compatibility. Lowering MenuBarKit's target does not lower DisplayAnchor's macOS 26 requirement.

## Usage

A menu bar app is an accessory app (no Dock icon, no main window): set `LSUIElement` to `true` in its `Info.plist`, or call `NSApp.setActivationPolicy(.accessory)` at launch. From there, the app delegate owns a status item and a `MenuBarPanel`:

```swift
import AppKit
import MenuBarKit
import SwiftUI

enum MyScreen: Hashable { case main, settings }

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var panel: MenuBarPanel!
    private let navigation = PanelNavigation<MyScreen>(initial: .main)

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "gauge", accessibilityDescription: nil)
        statusItem.button?.target = self
        statusItem.button?.action = #selector(toggle)

        panel = MenuBarPanel(
            rootView: PanelChrome { MyRootView(navigation: navigation) },
            width: Theme.defaultPanelWidth
        )
        panel.onDismiss = { [weak self] in self?.navigation.screen = .main }
    }

    @objc private func toggle() {
        if panel.isVisible {
            panel.dismiss()
        } else if let button = statusItem.button, let window = button.window {
            // Top-left corner of the panel: just below the status item, aligned to its left edge.
            let onScreen = window.convertToScreen(button.convert(button.bounds, to: nil))
            panel.present(at: NSPoint(x: onScreen.minX, y: onScreen.minY - 4))
        }
    }
}
```

Wrapping the root view in `PanelChrome` gives the panel its translucent background and rounded shape — `MenuBarPanel` itself is transparent and borderless.

## Modules

### Panel

| Type                      | Purpose                                                                                                                                                                                                                                                                                                                                                                           |
| ------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `MenuBarPanel`            | Borderless, non-activating floating `NSPanel` that presents popover-style content without anchoring to a view — it stays put even if a menu bar manager (Ice, Bartender, …) hides the status icon while open. Sizes itself from the SwiftUI content, keeps the top-left corner pinned while growing, dismisses on clicks outside the app, and can become key so text fields work. |
| `PanelChrome`             | Liquid Glass on macOS 26 and later, with native popover material on earlier systems. Optional `tint:` colors the translucent surface (the color's opacity controls the strength).                                                                                                                                                                                                             |
| `PanelNavigation<Screen>` | Observable current-screen state (`@Published var screen`), drivable from both SwiftUI (back button) and the panel owner (reset on dismiss).                                                                                                                                                                                                                                       |

### DesignSystem

`Theme` — shared tokens: `Spacing` (`xs`/`s`/`m`/`l`), `Radius` (`field`/`card`/`panel`), `Colors` (status colors + bar track), `Typography` (row title/value, field label, footnote), and `defaultPanelWidth`.

`SystemAccentObserver` — `ObservableObject` publishing the current macOS accent color as `color`, updated live when it changes in System Settings (the "Multicolor" accent resolves to the default blue).

### Components

| Component               | Purpose                                                                                                                                                                     |
| ----------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `PanelHeader`           | Header row: optional leading accessory, headline title, trailing actions.                                                                                                   |
| `GlassIconButton`       | Capsule icon button with interactive Liquid Glass on macOS 26 and later, and a primary-colored bordered surface on earlier systems. |
| `MeterRow` / `MeterBar` | Metered quantity (title, tinted value, capsule bar, optional footnote). The bar keeps its tint when the window is not key, unlike a tinted `ProgressView`.                  |
| `SectionLabel`          | Small field label; renders its text uppercase, so callers pass normal-case strings.                                                                                         |
| `inputChrome(focused:)` | View modifier wrapping a text input in a bordered container with an accent highlight on focus.                                                                              |

### Notifications

`Notifier` — `UNUserNotificationCenter` wrapper: `requestAuthorizationIfNeeded()` with a published `authorizationDenied` flag, immediate `send(title:body:)`, and re-drivable one-shot `schedule(title:body:at:identifier:)` / `cancelScheduled(identifier:)` (plus `cancelScheduled(prefix:excluding:)` to clear a family of pending notifications). Every entry point no-ops when the process is not running from a `.app` bundle, because the notification center aborts under `swift run`.

### Localization

`Localizer` — resolves UI strings from a bundle's `.lproj` tables, with an optional language override (empty/`nil` follows the system). Missing keys fall back to the key itself. Inject it once per app via `EnvironmentValues.localizer` and read it in views with `@Environment(\.localizer)`.

`Bundle.languageOptions(systemLabel:)` — lists a bundle's localizations (each in its own name) plus a leading system-follow entry, ready to drive a language `Picker` via `AppLanguageOption`. Each app keeps its own `Localizable.strings` under `Resources/*.lproj`; adding a language is a copy-and-translate with no code change.

`Bundle.resourceBundle(named:fallback:)` — finds a SwiftPM resource bundle inside the built `.app`, falling back to `Bundle.module` when running straight from the build directory (the fallback is an autoclosure on purpose: `Bundle.module` probes an absolute build path that must not be touched in a shipped app).

## Implementation notes

Behaviour that looks arbitrary but is deliberate:

- **Window shadow vs glass**: SwiftUI `glassEffect` on a borderless clear panel leaves faintly opaque pixels across the hosting view's full rectangular bounds, so AppKit casts the window shadow for a rectangle — a dark rim with squared corners. `MenuBarPanel` masks the hosting view's layer to the panel corner radius and invalidates the shadow after presenting/resizing.
- **Positioning**: content-driven resizes re-anchor the top-left corner (`setFrameTopLeftPoint` on `didResize`), so the panel grows downward instead of moving its top edge.
- **Plan B (not implemented)**: if glass sampling ever misbehaves on the borderless panel (edge artifacts, missing shadow), the escape hatch is to bridge AppKit's `NSGlassEffectView` as the content wrapper instead of the `glassEffect` modifier.

## Local development

Apps built on MenuBarKit (e.g. [DisplayAnchor](https://github.com/gabriarceus/DisplayAnchor)) declare a conditional dependency: a sibling `MenuBarKit` checkout is used automatically when present, otherwise the package is resolved from GitHub. So cloning this repo next to an app is enough to edit the library and rebuild the app with no manifest change:

```
git-projects/
├── MenuBarKit/
└── DisplayAnchor/
```

SwiftPM caches the evaluated manifest, so after **adding or removing** the sibling checkout run `swift package reset` once in the app (or `touch Package.swift`) to make it re-evaluate. Day to day, with the sibling always present, nothing extra is needed.

API changes: commit here, then tag a new semver (`git tag 1.1.0 && git push origin 1.1.0`) so outside consumers pick it up. Local builds don't wait for a tag.

## License

MIT — see [LICENSE](LICENSE).
