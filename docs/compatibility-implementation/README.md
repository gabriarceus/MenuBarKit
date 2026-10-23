# macOS compatibility implementation checks

Date: 2026-10-23. The package now declares macOS 15 and provides native fallback surfaces. Actual runtime support on macOS 15 is still unverified. These checks ran on macOS 27.0.1 with Xcode 27.1, Swift 6.4, and the macOS 27.0 SDK in Debug on Apple Silicon.

## Changes

`PanelChrome` keeps its original Liquid Glass expression on macOS 26 and later. Earlier systems use one `NSVisualEffectView` with popover material and behind-window blending. Optional tint is placed behind the content, and a local rounded clip shapes the background. The background does not drive content size or take input. Window activity follows the native default.

`GlassIconButton` keeps the same image, font, padding, action, hit shape, and accessibility label. Earlier systems use a primary-colored fill and border based on `inputChrome`, with native button pressed state and disabled environment feedback. Buttons do not create blur views. Public initializers remain unchanged.

Both runtime decisions are at the existing effect integration points. The private `Glass` property is available from macOS 26. Only the selected branch is constructed. There is no public rendering mode, new dependency, timer, observer, or window-management change. `MenuBarPanel` and its mask, sizing, anchoring, input, and shadow logic are unchanged.

## Build and tests

The guarded implementation first built and passed all 9 XCTest tests with the original macOS 26 floor. After lowering `Package.swift` to macOS 15, the full build and the same 9 tests passed again. Tests ran on the macOS 27 host. No availability suppression flag was used.

From the repository root:

```sh
CLANG_MODULE_CACHE_PATH=/private/tmp/menubarkit-compat-module-cache swift build --disable-sandbox --disable-automatic-resolution --cache-path /private/tmp/menubarkit-compat-cache --manifest-cache local --scratch-path .build/compatibility-implementation
CLANG_MODULE_CACHE_PATH=/private/tmp/menubarkit-compat-module-cache swift test --disable-sandbox --disable-automatic-resolution --cache-path /private/tmp/menubarkit-compat-cache --manifest-cache local --scratch-path .build/compatibility-implementation
```

`xcrun vtool -show-build` on both `PanelChrome.o` and `GlassIconButton.o` reports `platform MACOS`, `minos 15.0`, and `sdk 27.0`. The package still uses Swift tools 6.2. A macOS 15 development host also compiled against the package. No claim is made about running that host on macOS 15 or building with a separate Xcode 26 installation.

No extra unit tests were added for availability expressions or decorative modifiers. The meaningful checks here are compiler availability diagnostics, the existing logic suite, native hierarchy inspection, and direct input and composition observations.

## Runtime observations

The [development host](../compatibility-baseline/Host.swift) was extended with on-demand hierarchy capture and two standalone windows. The [original baseline](../compatibility-baseline/README.md) is preserved. The modern comparison uses the same macOS 26 host target as that baseline; the library itself targets macOS 15. A first host build targeting macOS 15 changed the host's ordinary system buttons, so it was not used for the modern comparison.

| Path | Observation | Evidence |
| --- | --- | --- |
| Modern panel | The compact dark panel retains the baseline appearance and 340 by 207-point size. | [Modern panel](modern-dark.jpg), compared with the [original capture](../compatibility-baseline/screenshots/dark-untinted.jpg). |
| Modern construction | Neither main panel nor either standalone composition contains `VisualEffectBackground` or `NSVisualEffectView` in its inspected AppKit hierarchy. Source review also confirms that fallback tint, clipping, and button styling are confined to the older branch. | [Hierarchy summary](hierarchy.txt). |
| Modern standalone button | Enabled and disabled buttons remain identifiable; one click changes Actions from 0 to 1. | [Modern standalone buttons](modern-button.jpg). |
| Modern standalone chrome | The glass surface has rounded edges in a normal transparent `NSWindow`, without the `MenuBarPanel` mask. | [Modern standalone chrome](modern-chrome.jpg). |
| Fallback preview panels | Both appearances are legible. One increment and text replacement work. A live 0.3-opacity blue tint and content-driven growth keep the rounded shape. | [Dark](preview-dark.jpg), [light](preview-light.jpg), and [expanded tinted input](preview-dark-expanded.jpg). |
| Fallback preview composition | The button works on an ordinary window background. Disabled state is exposed through accessibility and visibly dimmed. Chrome retains its own rounded shape with a transparent margin. | [Standalone buttons](preview-button.jpg), [standalone chrome](preview-chrome.jpg). |
| Fallback preview construction | One native effect view per panel or standalone chrome; none for the standalone buttons. Each effect reports material 6, blending 0, and state 0: popover, behind window, and follows window activity in the installed SDK. | [Hierarchy summary](hierarchy.txt). |

## Temporary fallback preview

The fallback screenshots and input checks above ran on macOS 27.0.1. They are not macOS 15 runtime evidence.

An isolated copy of `Package.swift`, `Sources`, and `Tests` was placed in `.build/compatibility-preview/Library`. In that copy only, the two body checks were changed from `if #available(macOS 26.0, *)` to `if #available(macOS 99.0, *)`. This selects the fallback on the current host while keeping the modern declarations availability-checked. A source comparison confirmed these are the only two changes to the copied components.

The same development host was copied into `.build/compatibility-preview/Host`, with Swift tools 6.2, a macOS 15 target, and a local package dependency on `../Library`. It built with the cache and resolution options above. The temporary app used bundle identifier `local.MenuBarKit.CompatibilityPreview` and minimum version 15.0. All preview code and altered availability checks remain in ignored build output. Production has no preview switch or altered threshold.

## Remaining verification

The user has no macOS 15 Mac or VM available and accepted keeping that runtime check pending. macOS 26 has also not been tested. Native fallback preview results on macOS 27 cannot establish behavior on either older runtime.

The [later runtime record](../compatibility-runtime/README.md) adds the available macOS 27 checks, including native accessibility preferences, VoiceOver-exposed labels, tint and appearance changes, repeated geometry checks, a focused before/after CPU comparison, and consumer build/test results. Actual older-runtime behavior and the remaining manual checks stay explicit there. The declared minimum and implemented fallback are documented separately from verified runtime support. The published installation example still uses macOS 26 because the fallback is unreleased.
