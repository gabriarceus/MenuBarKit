# MenuBarKit

Shared UI foundation for macOS menu bar apps, so they all read as one design language: a borderless floating panel, Liquid Glass chrome, design tokens, and a small set of reusable SwiftUI components.

Requires Xcode 26 (Swift 6.2, macOS 26+). No external dependencies.

## Installation

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/gabriarceus/MenuBarKit.git", from: "1.0.0")
],
targets: [
    .executableTarget(name: "MyApp", dependencies: ["MenuBarKit"])
]
```

## Usage

Typical wiring from an `NSApplicationDelegate`:

```swift
let navigation = PanelNavigation<MyScreen>(initial: .main)
let panel = MenuBarPanel(
    rootView: MyRootView(navigation: navigation), // wraps its content in PanelChrome
    width: Theme.defaultPanelWidth
)
panel.present(at: topLeftBelowStatusItem)
```

## Modules

### Panel

| Type                      | Purpose                                                                                                                                                                                                                                                                                                                                                                   |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `MenuBarPanel`            | Borderless, non-activating floating `NSPanel` that presents popover-style content without anchoring to a view — it stays put even if a menu bar manager (Ice, Bartender, …) hides the status icon while open. Sizes itself from the SwiftUI content, keeps the top-left corner pinned while growing, dismisses on outside clicks, and can become key so text fields work. |
| `PanelChrome`             | Liquid Glass chrome for the panel content. Optional `tint:` washes a color over the glass while keeping its translucency (the color's opacity controls the strength).                                                                                                                                                                                                     |
| `PanelNavigation<Screen>` | Observable current-screen state, drivable from both SwiftUI (back button) and the panel owner (reset on dismiss).                                                                                                                                                                                                                                                         |

### DesignSystem

`Theme` — shared tokens: `Spacing`, `Radius`, `Colors`, `Typography`, and `defaultPanelWidth`.

`SystemAccentObserver` — `ObservableObject` publishing the current macOS accent color, updated live when it changes in System Settings (the "Multicolor" accent resolves to the default blue).

### Components

| Component               | Purpose                                                                                                                                                                     |
| ----------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `PanelHeader`           | Header row: optional leading accessory, headline title, trailing actions.                                                                                                   |
| `GlassIconButton`       | Small capsule icon button with an interactive glass background; the `primary`-based tint lightens in dark mode and darkens in light mode, so it stays visible on any theme. |
| `MeterRow` / `MeterBar` | Metered quantity (title, tinted value, capsule bar, optional footnote). The bar keeps its tint when the window is not key, unlike a tinted `ProgressView`.                  |
| `SectionLabel`          | Small field label; renders its text uppercase, so callers pass normal-case strings.                                                                                         |
| `inputChrome(focused:)` | View modifier wrapping a text input in a bordered container with an accent highlight on focus.                                                                              |

### Notifications

`Notifier` — `UNUserNotificationCenter` wrapper: authorization tracking (`authorizationDenied`), immediate `send`, and re-drivable one-shot `schedule`/`cancelScheduled` by identifier. Every entry point no-ops when the process is not running from a `.app` bundle (the notification center aborts under `swift run`).

### Localization

`Localizer` — resolves UI strings from a bundle's `.lproj` tables, with an optional language override (empty/`nil` follows the system). Missing keys fall back to the key itself. Inject it once per app via `EnvironmentValues.localizer` and read it in views with `@Environment(\.localizer)`.

`Bundle.languageOptions(systemLabel:)` — lists a bundle's localizations (each in its own name) plus a leading system-follow entry, ready to drive a language `Picker`. Each app keeps its own `Localizable.strings` under `Resources/*.lproj`; adding a language is a copy-and-translate with no code change.

## Gotchas baked into the implementation

- **Window shadow vs glass**: SwiftUI `glassEffect` on a borderless clear panel leaves faintly opaque pixels across the hosting view's full rectangular bounds, so AppKit casts the window shadow for a rectangle — a dark rim with squared corners. `MenuBarPanel` masks the hosting view's layer to the panel corner radius and invalidates the shadow after presenting/resizing.
- **Positioning**: content-driven resizes re-anchor the top-left corner (`setFrameTopLeftPoint` on `didResize`), so the panel grows downward instead of moving its top edge.
- **Plan B**: if glass sampling ever misbehaves on the borderless panel (edge artifacts, missing shadow), bridge AppKit's `NSGlassEffectView` as the content wrapper instead of the `glassEffect` modifier.

## Local development

Apps built on MenuBarKit (e.g. [ClaudeUsageMenuBar](https://github.com/gabriarceus/ClaudeUsageMenuBar), [MacOSDisplayLayout](https://github.com/gabriarceus/MacOSDisplayLayout)) declare a conditional dependency: a sibling `MenuBarKit` checkout is used automatically when present, otherwise the package is resolved from GitHub. So cloning this repo next to an app is enough to edit the library and rebuild the app with no manifest change:

```
git-projects/
├── MenuBarKit/
├── ClaudeUsageMenuBar/
└── MacOSDisplayLayout/
```

SwiftPM caches the evaluated manifest, so after **adding or removing** the sibling checkout run `swift package reset` once in the app (or `touch Package.swift`) to make it re-evaluate. Day to day, with the sibling always present, nothing extra is needed.

API changes: commit here, then tag a new semver (`git tag 1.1.0 && git push origin 1.1.0`) so outside consumers pick it up. Local builds don't wait for a tag.

## License

MIT — see [LICENSE](LICENSE).
