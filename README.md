# MenuBarKit

A Swift package with the shared UI foundation for macOS menu bar apps, so they read as one design language: a borderless floating panel, Liquid Glass chrome, design tokens, and a small set of reusable SwiftUI components.

**What it gives you:** the panel that drops down from the menu bar (window setup, glass background, sizing, positioning, outside-click dismissal), components to fill it, and shared spacing, radius, typography, and color tokens. Optional helpers cover the status item, edit commands, launch at login, notifications, contextual help, and localization.

**What it does not do:** it is not an app template. Your app owns the app delegate, the status item, its screens, and its data. MenuBarKit has no external dependencies.

## Requirements

- macOS 15 or later. Panels and icon buttons use Liquid Glass on macOS 26 and later, and native fallback surfaces on earlier systems.
- Xcode 26 / Swift 6.2 or newer, with the macOS 26 SDK or newer.

## Installation

Add the package to your app's `Package.swift`:

```swift
let package = Package(
    name: "MyApp",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/gabriarceus/MenuBarKit.git", from: "1.3.0")
    ],
    targets: [
        .executableTarget(name: "MyApp", dependencies: ["MenuBarKit"])
    ]
)
```

In an Xcode project: _File ▸ Add Package Dependencies…_ and paste the same URL.

## Usage

A menu bar app is an accessory app with no Dock icon: set `LSUIElement` to `true` in its `Info.plist`, or call `NSApp.setActivationPolicy(.accessory)` at launch. The app delegate creates a status item and a `MenuBarPanel`, and a `StatusItemController` connects them:

```swift
import AppKit
import MenuBarKit
import SwiftUI

enum MyScreen: Hashable { case main, settings }

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let navigation = PanelNavigation<MyScreen>(initial: .main)
    private var statusItem: NSStatusItem?
    private var controller: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let panel = MenuBarPanel(
            rootView: PanelChrome { MyRootView(navigation: navigation) },
            width: Theme.defaultPanelWidth
        )
        panel.onDismiss = { [weak self] in self?.navigation.screen = .main }

        let controller = StatusItemController(statusItem: statusItem, panel: panel)
        if let icon = NSImage(systemSymbolName: "gauge", accessibilityDescription: nil) {
            controller.update(icon: icon, accessibilityLabel: "MyApp")
        }
        self.statusItem = statusItem
        self.controller = controller
    }
}
```

`PanelChrome` gives the content its translucent background and rounded shape; `MenuBarPanel` itself is transparent and borderless. To place the panel yourself, skip the controller and call `panel.present(at:)` with a top-left point in screen coordinates.

## API

### Panel

| Type                      | Purpose                                                                                                                                                                 |
| ------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `MenuBarPanel`            | Borderless, non-activating floating panel. Sizes itself from its SwiftUI content, keeps its top-left corner pinned while growing, dismisses on outside clicks, and can become key for text fields. |
| `PanelChrome`             | Liquid Glass on macOS 26 and later, native popover material on earlier systems. An optional `tint` colors the surface; the color's opacity sets the strength.          |
| `PanelNavigation<Screen>` | Observable current screen, driven by both SwiftUI and the panel's owner.                                                                                               |

### Design system

| Type                   | Purpose                                                                                                              |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `Theme`                | `Spacing`, `Radius`, `Colors`, `Typography`, and `defaultPanelWidth`.                                                |
| `SystemAccentObserver` | Publishes the current macOS accent color and follows changes in System Settings. The Multicolor accent resolves to blue. |

### Components

| Component                                          | Purpose                                                                                                                      |
| -------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| `PanelHeader`                                      | Header row with an optional leading accessory, a headline title, and trailing actions.                                       |
| `GlassIconButton`                                  | Capsule icon button with interactive Liquid Glass, and a bordered capsule on earlier systems.                                |
| `MeterRow` / `MeterBar`                            | Metered quantity with a title, a tinted value, a capsule bar, and an optional footnote. The bar keeps its tint in a window that is not key. |
| `SectionLabel`                                     | Small field label shown in uppercase; pass normal-case text.                                                                 |
| `PanelSection`                                     | Titled surface with caller-supplied content and an optional description. See the [compact settings guide](docs/compact-settings.md) and the [compact feedback guide](docs/compact-feedback.md). |
| `panelHelp(_:)` / `panelHelpHost(isActive:delay:)` | Delayed, root-hosted contextual help that keeps accessible names. See the [contextual help guide](docs/contextual-help.md).  |
| `inputChrome(focused:)`                            | Bordered container for a text input, with an accent border while focused.                                                   |

### App management

| Type                                               | Purpose                                                                                                   |
| -------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| `StatusItemController`                             | Primary and secondary actions, presentation state, and a template icon with optional text and a dot for a caller-owned status item and panel. |
| `PanelPlacement`                                   | Position below the status item, or a main-screen fallback, with usable bounds for content sizing.         |
| `EditMenu` / `panelEscape(cancelEditing:dismiss:)` | Responder-chain edit commands and child-first Escape handling.                                            |
| `onClickOutsideTextInput(isActive:perform:)` | Reports a click outside the view and outside text fields, so the app can end text editing.               |
| `LoginItem`                                        | Launch-at-login status, explicit registration, errors, and refresh after app activation.                  |

See the [app management guide](docs/app-management.md). For global shortcuts, see the [global shortcuts guide](docs/global-shortcuts.md).

### Notifications

`Notifier` wraps the user notification center: authorization with a published `authorizationDenied` flag, immediate `send(title:body:)`, one-shot `schedule(title:body:at:identifier:)`, and `cancelScheduled` by identifier or prefix. Every call does nothing outside a `.app` bundle, where the notification center would abort.

### Localization

| API                                     | Purpose                                                                                                                           |
| --------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| `Localizer`                             | Strings from a bundle's `.lproj` tables, with an optional forced language. Missing keys return the key. Inject it with `EnvironmentValues.localizer`. |
| `Bundle.languageOptions(systemLabel:)`  | A system-follow entry plus each bundled language in its own name, for a language picker of `AppLanguageOption` values.            |
| `Bundle.resourceBundle(named:fallback:)` | A SwiftPM resource bundle inside the built app, or the fallback when running from the build directory.                           |

## Documentation

- [Architecture](docs/architecture.md): source map, ownership, panel behavior, and platform support.
- [Development](docs/development.md): local work with a consumer app, checks, and releases.
- [Contributing](CONTRIBUTING.md).

## License

MIT — see [LICENSE](LICENSE).
