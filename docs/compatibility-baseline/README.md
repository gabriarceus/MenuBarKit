# macOS compatibility audit and baseline

Date: 2026-10-23. The availability audit and modern visual baseline are recorded below. Production sources and the macOS 26 package target are unchanged. No macOS 15 test machine or VM is available; older-runtime verification remains pending.

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

The host creates two panels with forced Aqua and Dark Aqua appearances. Both share the tint and expanded-content state. Each has an independent action count and editable text. `Resize` adds or removes 100 points of content plus stack spacing; `Tint` switches between nil and blue at 0.3 opacity. The control window can show both panels, show either panel, hide them, record metrics, or quit. Cmd+0 returns to that window. Standard Edit menu actions support text shortcuts. Use the same content, configuration, and machine for the later comparison.

`Record metrics` writes a snapshot to `/private/tmp/menubarkit-baseline-metrics.txt`. It records wall time, cumulative process CPU time from `getrusage`, panel visibility, key status, and frames in screen points. It runs only when requested. No timer, polling loop, or background sampler is added. The host's public component composition remains the same as in the initial baseline; the added controls support observation.

For this session, the source was copied into `.build/compatibility-host/Sources/BaselineHost/Host.swift`. Its temporary manifest used Swift tools 6.2, a macOS 26 floor, a local `.package(path: "../..")` dependency, and one executable target named `BaselineHost` depending on `MenuBarKit`. Build with the same cache options and `--package-path .build/compatibility-host`. The final host source built successfully and passed `swift-format` strict lint with four-space indentation.

The executable and resource bundle from `.build/compatibility-host/.build/out/Products/Debug` were copied into `.build/compatibility-host/MenuBarKitBaseline.app/Contents/MacOS/BaselineHost` and `Contents/Resources/MenuBarKit_MenuBarKit.bundle`. The host's generated Info.plist declares bundle identifier `local.MenuBarKit.CompatibilityBaseline`, executable `BaselineHost`, package type `APPL`, and minimum system version `26.0`. This local host has no updater or persistent preferences. Its bundle and build outputs are ignored by Git.

## Runtime observations

| Check | Observation | Evidence limit |
| --- | --- | --- |
| Initial opening | Both light and dark panels rendered their title, capsule icon button, meter, text input, and controls. | Qualitative observation on macOS 27.0.1. No opening latency measurement. |
| Button action | Clicking Increment changed Actions from 0 to 1. | One click observed through accessibility state. |
| Content-driven resize | Both panels changed from 340 by 207 points to 340 by 323 points. Light-panel origin changed from (80, 1003) to (80, 887); dark-panel origin changed from (480, 1003) to (480, 887). Their top edges stayed at y=1210. Returning to compact content restored the 207-point height. | Window crops show rounded corners. The external window shadow still needs a focused visual check. |
| Tint update | A blue 0.3-opacity tint appeared on both existing panels. | Captured in forced light and dark appearances; varied backgrounds and accessibility settings remain for runtime validation. |
| Text input | The field gained an accent focus border. Cmd+A followed by typing replaced the value with `Baseline edited`. | Verified after adding the host's standard Edit menu. |
| Idle | Both compact, tinted panels remained visible and non-key across a 23.049-second sample. Cumulative process CPU increased by 0.020868 seconds, about 0.0905% of one core on average. | One short Debug baseline, including endpoint button handling. This is not a performance guarantee or a before/after comparison. |
| Explicit dismissal | Hide panels recorded `visible=false` for both panels. | Raw snapshot retained. |
| Outside click | A coordinate click in Calculator's title bar recorded `visible=false` for both panels. | Clicking a menu through accessibility alone did not establish mouse-event dismissal; the coordinate test used an ordinary external window. |
| Reopening | Show panels restored the dark panel with Actions still 1, the edited text, and the tint. | Accessibility state and a saved screenshot confirm reopening. |

Six raw measurement snapshots are saved in [measurements.txt](measurements.txt). The following window-only captures were saved before changing production rendering:

| Capture | State |
| --- | --- |
| [Light, untinted](screenshots/light-untinted.jpg) | Compact content. |
| [Dark, untinted](screenshots/dark-untinted.jpg) | Compact content before the action and edit checks. |
| [Light, tinted](screenshots/light-tinted.jpg) | Compact content with blue at 0.3 opacity. |
| [Dark, tinted](screenshots/dark-tinted.jpg) | Compact content with edited text and Actions 1. |
| [Light, expanded and tinted](screenshots/light-tinted-expanded.jpg) | Additional 100-point content and stack spacing. |
| [Dark, expanded and tinted](screenshots/dark-tinted-expanded.jpg) | Additional content with focused, edited input. |
| [Dark, reopened](screenshots/dark-reopened.jpg) | Retained tint, Actions 1, and edited text after outside-click dismissal. |

The continuation verified the individual panel controls, saved persistent window images, added standard menu actions, and measured frames and process CPU through the host. Outside-click verification used Calculator after desktop automation was unavailable. No desktop screenshot was taken.

Modern visual parity after implementation, standalone components, accessibility preferences, the external shadow, a focused before/after performance comparison, DisplayAnchor integration, and runtime behavior on macOS 15 and 26 remain pending. No older-runtime support claim follows from this baseline. The user confirmed that no macOS 15 machine or VM is available and requested that runtime verification remain pending.
