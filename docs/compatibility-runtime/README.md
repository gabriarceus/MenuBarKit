# macOS compatibility runtime checks

Date: 2026-10-23. These results cover macOS 27.0.1 and a forced fallback preview on that same runtime. Actual macOS 15 and macOS 26 checks remain pending. Compatibility support is not declared complete.

## Environment and scope

The host is Apple Silicon running macOS 27.0.1, build 26A434, with Xcode 27.1, Swift 6.4, and SDK 27.0. The library declares macOS 15. The modern development host targets macOS 26 to match the original baseline. All performance samples use Debug builds.

The [development host](../compatibility-baseline/Host.swift) now has on-demand commands for 0.1, 0.3, and 0.6 blue tint opacity, forced and system appearance, a controlled color background, and a finite opening/resizing workload. Metrics also record native accessibility preferences and effective panel appearance. These commands belong only to the development host; no rendering mode, sampler, or timer was added to the library.

The fallback preview uses the same isolated macOS 99 availability thresholds described in the [implementation record](../compatibility-implementation/README.md). It cannot establish macOS 15 runtime behavior.

## Focused before/after check

The comparison uses library commit `ca89c79586d49a3080019155f4c32c2c0e08ede4` before the compatibility implementation and `bcadb93c8df7e7498f9af236db7c757e9c237957` after it. The earlier library was extracted into ignored build output. Both variants used byte-identical host source, the same executable path and bundle identity, the same machine, a macOS 26 host target, and the same Debug configuration. The app was stopped before replacing its executable.

Each of three samples runs ten cycles with two panels: present, wait 200 ms, expand, wait 100 ms, check growth and top-left anchoring, shrink, wait 100 ms, dismiss, and wait 100 ms. Tint is blue at 0.3 opacity. CPU counters come from `getrusage`. Wall time includes the fixed waits and is not an opening-latency or frame-pacing measurement.

| Observation | Before | After |
| --- | --- | --- |
| Cycles | 30 | 30 |
| Growth or anchoring failures | 0 | 0 |
| Mean CPU per ten-cycle sample | 1.135 s | 1.053 s |
| CPU sample range | 1.104–1.162 s | 0.995–1.147 s |
| Mean wall time per sample | 5.485 s | 5.456 s |
| Idle observation duration | 38.149 s | 50.896 s |
| Idle process CPU | 0.090082 s | 0.054598 s |
| Mean idle CPU, as a share of one core | 0.2361% | 0.1073% |

No repeatable CPU increase or geometry failure was observed. The ranges overlap; these samples do not establish a performance improvement. Idle windows differ in duration, so the table includes normalized rates. Both idle samples had the same two compact, tinted, visible, non-key panels, with the app inactive and all four tested accessibility preferences off. This is a focused regression check, not a benchmark suite or an Instruments trace.

Raw evidence: [before workload](workload-before.txt), [after workload](workload-after.txt), [before idle start](idle-before-start.txt), [before idle end](idle-before-end.txt), [after idle start](idle-after-start.txt), and [after idle end](idle-after-end.txt).

## Runtime observations

| Area | Observed result on macOS 27 | Limit |
| --- | --- | --- |
| Modern rendering | The current glass path keeps the original rounded panel and readable controls; blue tint changes update the existing surface. | Earlier baseline and implementation captures remain separate. |
| Shape and sizing | All 60 before/after cycles preserved horizontal position and top edge while increasing content height. | The automated check allows 0.5 points for frame comparisons. |
| Native preview tint | Nil, 0.1, 0.3, and 0.6 opacity update the native surface. Forced light/dark and system appearance are represented. | Strong blue tint reduces contrast for values using the same blue. Supplied opacity is preserved by contract; arbitrary colored-content contrast is not certified. |
| Native preview construction | One native visual-effect view per panel; none for standalone buttons. | Counts apply to the forced preview on macOS 27. |
| Native preview idle | 0.084569 process CPU seconds over 41.617 seconds, or about 0.2032% of one core, with two visible non-key panels. | One short observation; no macOS 15 cost result. |
| Reduced transparency | Both paths become opaque and retain readable primary content. The modern process reports the native preference as true. | Tested separately before enabling the other preferences. |
| Combined accessibility preferences | Reduce Transparency, Increase Contrast, Reduce Motion, and VoiceOver were all enabled through System Settings. Both processes reported all four as true. Enabled buttons fired once; disabled buttons remained exposed as disabled. | Contrast and motion were checked in this combined state, not in every independent combination. |
| VoiceOver labels | The live accessibility trees expose `Increment` and `Disabled action` while VoiceOver is enabled. | Spoken audio and full VoiceOver keyboard navigation were not audited. |
| Modern input | One increment and Cmd+A text replacement produced Actions 1 and `Runtime edited`, with the dark panel visible and key. | Captured in the diagnostic host; consumer numeric editing has separate manual confirmation. |
| Outside click | In a later manual follow-up, the user confirmed that clicking another app closes both panels and that `Show panels` reopens them with Actions 1 and text `Manual check` preserved. | Confirmed manually on macOS 27; the earlier automated attempts did not establish this result. |
| Preference restoration | All four values were initially false and were restored to false, as confirmed by the app's native getters. | The user's separate menu-bar hiding tool was controlled by the user. |

Preference and state evidence: [initial state](initial-state.txt), [modern reduced transparency](modern-reduced-transparency.txt), [modern combined accessibility](modern-accessibility.txt), [preview combined accessibility](preview-accessibility.txt), [restored state](restored-state.txt), [modern system appearance](modern-system-appearance.txt), [preview system appearance](preview-system-appearance.txt), and [preview consumer tint](preview-consumer-tint.txt).

Component evidence: [modern accessibility tree](modern-accessibility-ax.txt), [preview accessibility tree](preview-accessibility-ax.txt), [preview view counts](preview-view-counts.txt), [preview idle start](idle-preview-start.txt), and [preview idle end](idle-preview-end.txt).

Input evidence: [modern input tree](modern-input-ax.txt) and [visible key panel](modern-key-input.txt). The [benchmark host hash](benchmark-host-sha256.txt) identifies the identical host source used for the completed before/after samples.

## Captures

| Modern path | Native preview on macOS 27 |
| --- | --- |
| [Controlled background](modern-backdrop.jpg) | [Untinted background](preview-backdrop-nil.jpg) |
| [Reduced transparency](modern-reduced-transparency.jpg) | [Reduced transparency](preview-reduced-transparency.jpg) |
| [Combined accessibility preferences](modern-accessibility.jpg) | [Combined accessibility preferences](preview-accessibility.jpg) |
| [Strong tint](modern-strong-tint.jpg) | [Weak tint](preview-weak-tint.jpg), [strong tint](preview-strong-tint.jpg), and [light strong tint](preview-light-strong-tint.jpg) |
| [System appearance](modern-system-appearance.jpg) | [System appearance](preview-system-appearance.jpg) |

Captures are app-window images. They do not establish external shadow quality outside the window crop or prove older-runtime rendering.

## DisplayAnchor integration

The user authorized dependency downloads, build, tests, and opening an isolated DisplayAnchor copy. Its [source revision](consumer-revision.txt) was archived into `.build/displayanchor-validation/DisplayAnchor` and linked to the current local MenuBarKit through a sibling symlink. The bundle uses `local.MenuBarKit.DisplayAnchorValidation` for separate preferences; the installed app and the consumer checkout were not changed. Fresh preferences leave automatic display restoration disabled by the consumer's own defaults.

The documented `bash build.sh </dev/null` completed, producing an arm64/x86_64 app, embedding Sparkle 2.10.0, and passing ad-hoc signature verification. Non-interactive input prevents installation. `swift test` then passed all 37 tests in five suites. `vtool` confirms a macOS 26 floor for both executable slices. Xcode also emitted an Intel deprecation warning; architecture settings were not changed.

The accessory app started, but the UI tool timed out selecting a visible window. The user temporarily disabled the menu-bar hiding tool and opened the panel. Selection still timed out. A second, test-only startup in the isolated copy uses regular activation and calls the existing `togglePopover()` automatically. Consumer views and library code remain unchanged. This makes the copy appear in the app inventory, but selection fails with ScreenCaptureKit internal error `-3811`, including after a fresh inventory check. The installed app remained running and untouched.

Consumer build and tests pass. The user manually confirmed that the validation panel is visible and legible with regular corners and shadow. The user then confirmed all three requested interaction checks: repeated settings/back navigation changes height while preserving the top edge; Light, Dark, System, and all three tint modes update immediately and remain legible; Cmd+A edits the settle-time field from 3 to 4 and back to 3. Automated consumer UI inspection remains unavailable. These are manual results in the isolated test startup, not automated capture results or a check of the installed app. The validation process was closed afterward. No update was installed and no display-layout action was invoked.

## Remaining checks

Keep macOS 15 and macOS 26 runtime validation pending. The forced preview is not a substitute. Consumer rendering, corners, shadow, navigation, appearance/tint updates, and numeric editing have manual confirmation; automated consumer capture remains unavailable. Full VoiceOver keyboard interaction and spoken audio remain unverified: the user deferred the requested manual follow-up. Existing accessibility-tree and preference checks still apply. Review colored-content contrast with strong consumer tints on the actual older runtime. No library changes were made during this validation work.

The earlier automated dismissal follow-up was stopped without a result. After the user requested continuation, a manual check confirmed dismissal and state-preserving reopening on macOS 27. The separate VoiceOver follow-up was deferred, and the [final state](manual-followup-state.txt) confirms VoiceOver remained off. The diagnostic host was closed afterward. No older-runtime or VoiceOver success is inferred from the completed outside-click check.
