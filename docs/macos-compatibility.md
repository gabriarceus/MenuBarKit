# macOS compatibility verification

Last checked: 2026-10-23. The package declares macOS 15, but runtime verification covers macOS 27.0.1 only. Support on macOS 15 and macOS 26 remains unverified. See the [platform support policy](../README.md#platform-support-policy) for development and consumer requirements.

## Implementation

Panels and icon buttons use Liquid Glass on macOS 26 and later. Earlier systems use native popover material for panels and a bordered capsule for buttons. Public component signatures and window management remain unchanged. The modern path creates no fallback surfaces, and the change adds no dependencies or recurring background work.

## Recorded results

Checks ran on Apple Silicon with macOS 27.0.1, Xcode 27.1, Swift 6.4, and the macOS 27 SDK in Debug builds. These are results from the compatibility implementation work, not a claim that each later revision has passed the same checks.

| Area | Result | Limit |
| --- | --- | --- |
| Build and unit tests | The library built with a macOS 15 target and passed all 9 XCTest tests. Object files confirmed the deployment target; normal availability checking remained enabled. | Tests ran on macOS 27, not macOS 15. |
| Modern UI | Appearance, tint, text editing, standalone components, sizing, and anchoring were checked. Manual checks confirmed outside-click dismissal and reopening with state preserved. | Verified on macOS 27.0.1 only. |
| Native fallback | A forced preview checked light/dark appearance, tint, input, enabled/disabled buttons, and standalone rounded chrome. | The preview ran on macOS 27 and does not establish older-runtime behavior. |
| Regression checks | Thirty opening/resizing cycles before and thirty after the change had no growth or anchoring failures. Short CPU samples showed no repeatable increase. | Debug samples are not a performance guarantee or evidence of an improvement. |
| Accessibility | Reduced transparency and combined accessibility preferences were checked; accessibility trees exposed button labels and disabled state. | Full VoiceOver keyboard navigation and spoken output remain unverified. |
| DisplayAnchor integration | An isolated consumer built for arm64 and x86_64 and passed all 37 tests. The user confirmed rendering, shadow, navigation, appearance/tint changes, and numeric editing. | Consumer UI results were manual; DisplayAnchor still requires macOS 26. |

## Remaining verification

- Run the panel and standalone component checks on actual macOS 15 and macOS 26 systems, including input, sizing, dismissal, reopening, appearance, and accessibility preferences.
- Verify full VoiceOver keyboard navigation and spoken output.
- Check contrast with strong consumer tints on macOS 15; preserved tint opacity can reduce contrast with similarly colored content.

The temporary diagnostic host, screenshots, and raw measurements are excluded from the maintained source tree. This summary preserves the useful results and their limits.
