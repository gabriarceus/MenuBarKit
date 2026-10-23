# macOS compatibility audit and baseline

Date: 2026-10-23. This is evidence for checkpoint 1 of the [compatibility plan](../macos-compatibility-plan.md). The availability audit is complete for the installed SDK; the visual baseline is partial. Production sources and the macOS 26 package target are unchanged.

## Environment

| Item | Observed value |
| --- | --- |
| Host runtime | macOS 27.0.1, build 26A434, Apple Silicon |
| Xcode | 27.1, build 27A9275 |
| Swift | Apple Swift 6.4, swiftlang-6.4.0.34.1 |
| Installed macOS SDK | 27.0 |
| Production deployment target | macOS 26 |
| Isolated audit deployment target | macOS 15 |
| Build configuration | Debug |
| Older runtime evidence | No macOS 15 or macOS 26 test runtime was established in this session |

The package still uses Swift tools 6.2. These checks used the installed newer compiler and SDK; they do not establish a separate Xcode 26 build result.

## Availability audit

All 14 Swift source files and the existing tests were inspected. An isolated copy of `Package.swift`, `Sources`, and `Tests` was created at `/private/tmp/menubarkit-compatibility-audit`. Only that copy had its manifest changed to `.macOS(.v15)`.

| Area | Result at the macOS 15 target | Expected maintenance |
| --- | --- | --- |
| `PanelChrome` | The private `Glass` property fails availability checking. Annotating that property exposes the unguarded `glassEffect` call in `body`. | Guard the modern body and annotate the private property; provide the planned native background. |
| `GlassIconButton` | The unguarded `glassEffect` call fails availability checking. | Select a small button surface at this integration point. |
| `MenuBarPanel` | Compiles without changes. The SDK declares `NSHostingController.sizingOptions` and `NSHostingSizingOptions.preferredContentSize` available from macOS 13. | No second sizing, input, dismissal, mask, shadow, or window implementation is indicated by this audit. |
| Other components and tokens | `InputChrome`, `PanelHeader`, `SectionLabel`, `MeterRow`, `MeterBar`, and `Theme` compile without changes. | Existing fill/border patterns and radius/spacing tokens remain reuse candidates. |
| State and concurrency | `PanelNavigation`, `SystemAccentObserver`, its Combine subscription, `MainActor.assumeIsolated`, and notification tasks compile without changes. | No availability workaround was found. |
| Localization and notifications | Resource lookup, environment values, language options, and `Notifier` compile without changes. | Notification delivery and authorization were not exercised. |

After collecting the failures, both glass component types were marked `@available(macOS 26.0, *)` in the isolated copy only. That diagnostic step allowed the remaining library and tests to build normally for macOS 15. It does not provide usable glass components on macOS 15 and is not the compatibility implementation.

The isolated build and all 9 XCTest tests passed after those diagnostic annotations. Tests ran on the macOS 27 host. `xcrun vtool -show-build` on the isolated `MenuBarPanel.o` reported `platform MACOS`, `minos 15.0`, and `sdk 27.0`. No availability-check suppression flag was used.

## Commands and build evidence

The production baseline passed with these commands from the repository root:

```sh
CLANG_MODULE_CACHE_PATH=/private/tmp/menubarkit-compat-module-cache swift build --disable-sandbox --disable-automatic-resolution --cache-path /private/tmp/menubarkit-compat-cache --manifest-cache local --scratch-path .build/compatibility-baseline
CLANG_MODULE_CACHE_PATH=/private/tmp/menubarkit-compat-module-cache swift test --disable-sandbox --disable-automatic-resolution --cache-path /private/tmp/menubarkit-compat-cache --manifest-cache local --scratch-path .build/compatibility-baseline
```

Result: build passed; 9 XCTest tests passed with 0 failures. The additional Swift Testing runner discovered 0 tests. The first build attempt failed because Clang tried to write its default module cache outside the workspace. Redirecting the cache and disabling SwiftPM's nested process sandbox allowed the checks within the existing filesystem sandbox. SwiftPM also warned that its user-level configuration and security cache directories were inaccessible; those directories were not inspected.

The isolated audit used the same cache and resolution options with `--package-path /private/tmp/menubarkit-compatibility-audit`. Temporary logs are `build-macos15.log`, `build-glass-annotation.log`, `build-non-glass.log`, and `test-non-glass.log` in that directory. Temporary logs may be removed by the system; the relevant outcomes are recorded above.

No external package resolution, authenticated registry access, notification permission request, or DisplayAnchor build or launch was performed. DisplayAnchor's manifest and development guidance identify Sparkle and updater setup, so a dependency-free local host was used for this library baseline.

## Development host

[Host.swift](Host.swift) reuses `MenuBarPanel`, `PanelChrome`, `PanelHeader`, `GlassIconButton`, `MeterRow`, `SectionLabel`, `inputChrome`, and shared tokens. It adds only development content and window controls. It is not a library target or a sample product in the production manifest.

The host creates two panels with forced Aqua and Dark Aqua appearances. Both share the tint and expanded-content state. Each has an independent action count and editable text. `Resize` adds or removes 100 points of content plus stack spacing; `Tint` switches between nil and blue at 0.3 opacity. The control window can show both panels, show either panel, hide them, or quit. Use the same content, configuration, and machine for the later comparison.

For this session, the source was copied into `.build/compatibility-host/Sources/BaselineHost/Host.swift`. Its temporary manifest used Swift tools 6.2, a macOS 26 floor, a local `.package(path: "../..")` dependency, and one executable target named `BaselineHost` depending on `MenuBarKit`. Build with the same cache options and `--package-path .build/compatibility-host`. The final host source built successfully and passed `swift-format` strict lint with four-space indentation.

The executable and resource bundle from `.build/compatibility-host/.build/out/Products/Debug` were copied into `.build/compatibility-host/MenuBarKitBaseline.app/Contents/MacOS/BaselineHost` and `Contents/Resources/MenuBarKit_MenuBarKit.bundle`. The host's generated Info.plist declares bundle identifier `local.MenuBarKit.CompatibilityBaseline`, executable `BaselineHost`, package type `APPL`, and minimum system version `26.0`. This local host has no updater or persistent preferences. Its bundle and build outputs are ignored by Git.

## Runtime observations

| Check | Observation | Evidence limit |
| --- | --- | --- |
| Initial opening | The dark panel rendered its title, capsule icon button, meter, text input, and controls. | Qualitative observation on macOS 27.0.1. No latency measurement. |
| Button action | Clicking Increment changed Actions from 0 to 1. | One click observed through accessibility state. |
| Content-driven resize | Resize increased the screenshot height from 414 to 646 pixels at the same 680-pixel width; content and rounded corners remained visible. | The captures are window crops. They do not prove screen-coordinate anchoring or the external shadow. |
| Tint update | A blue 0.3-opacity tint appeared on the existing expanded panel. | Dark appearance only. |
| Text input | The field gained an accent focus border and accepted appended text. | Full keyboard shortcut behavior was not established; the minimal AppKit host has no Edit menu. |
| Idle | The panel remained available across observation calls without an observed hang. | No timed idle sample, CPU result, or performance comparison. `ps` was blocked by the filesystem sandbox. |
| Light appearance, dismissal, reopening | Not established reliably. Cross-app automation and attempts to return to the control window gave inconsistent results. | After two attempts, the same automation approach was stopped. These checks remain pending. |

Three dark-panel screenshots were captured in the task conversation: compact untinted, expanded untinted, and expanded tinted with focused input. The computer-use tool did not provide persistent screenshot file paths; no image artifacts were saved in the repository. Capture persistent before-change images for the later comparison before implementing checkpoint 2.

The last host edit added individual light/dark show controls and was build-checked, but those added controls were not runtime-verified. Modern visual parity, standalone components, accessibility preferences, a focused opening/resizing/idle comparison, DisplayAnchor integration, and runtime behavior on macOS 15 and 26 remain pending. No older-runtime support claim follows from this audit.
