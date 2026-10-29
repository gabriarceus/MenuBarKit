# Contextual help

Use `.panelHelp(text)` for a short-delay tooltip and `.panelHelpHost()` once above the panel's scrolling content. The target publishes its anchor, and the host draws one input-transparent overlay. Native `.help(text)` remains suitable when system timing is wanted.

```swift
VStack {
    ScrollView {
        Button("Settings", action: openSettings)
            .accessibilityLabel("Open settings")
            .panelHelp(settingsHelp)
    }
}
.panelHelpHost(isActive: isPanelPresented)
```

Pass localized strings from the app. The modifier adds an accessibility hint; it preserves an explicit name such as “Open settings”. Keep essential actions available through normal controls and keyboard interaction. The bubble itself is hidden from accessibility to avoid duplicate help.

Help appears after 350 milliseconds. Exiting or removing a target cancels pending work and hides visible help. Changing its text restarts the delay, and switching targets cancels the old request. Empty text creates no bubble. Each target owns its pending task; there is no global service.

Set `isActive` to false when retained panel content closes. Hiding an AppKit window can retain the SwiftUI tree, so disappearance alone is insufficient. The flag immediately removes help and cancels pending work; activation waits for a new hover. It defaults to true for content whose lifetime already follows presentation.

Apply the host outside inner `ScrollView` clips. Bubbles wrap to at most 260 points and fit within the host, preferring a position above the target and falling below when needed. Text longer than the available host height can truncate; the full text remains in the accessibility hint. The overlay neither accepts input nor participates in the panel's size.

## Verification

Automated checks cover cancellation before presentation, replacing pending work, hiding visible help, release, edge placement, oversized content, and empty or tiny hosts. Accessibility inspection on macOS 27.2 confirmed separate explicit names and help text, with controls still actionable.

The computer-use tool's button clicks did not deliver SwiftUI hover events in the temporary host; a diagnostic counter confirmed this. The user then confirmed real pointer checks for rapid target changes, target removal, scrolling, edge rendering, and host deactivation. Runtime checks on macOS 15 and 26 and VoiceOver spoken output remain pending.
