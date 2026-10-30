# Compact feedback

DisplayAnchor already shows saved-profile storage warnings, an empty saved-profile list, and update-check progress with native views. These are the concrete examples for this checkpoint. The app continues to own those conditions and their transitions; this guide adds no shared loading model or production migration.

Use native `Label` for an empty or failed result and `ProgressView` for active work. Add a normal `Button` only when the caller supplies an action. The warning symbol and message identify a failure without relying on color. `PanelSection` supplies the compact surface and optional description; no additional feedback component is needed.

## Composition

The following local example demonstrates caller-selected phases. Its enum belongs to the example, not to MenuBarKit. Resolve its strings through the consumer's localization system.

```swift
import MenuBarKit
import SwiftUI

enum ExamplePhase {
    case empty, busy, failed
}

struct FeedbackExample: View {
    let phase: ExamplePhase
    var description: String? = nil
    var retry: (() -> Void)? = nil
    var canRetry = true

    var body: some View {
        PanelSection("Saved items", description: description) {
            switch phase {
            case .empty:
                Label("No saved items", systemImage: "tray")
                    .fixedSize(horizontal: false, vertical: true)
            case .busy:
                ProgressView("Loading saved items")
                    .controlSize(.small)
            case .failed:
                Label("Could not load saved items", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
                if let retry {
                    Button("Try again", action: retry)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(!canRetry)
                }
            }
        }
        .padding(Theme.Spacing.m)
        .frame(width: Theme.defaultPanelWidth)
    }
}
```

Omitting `description` or `retry` leaves no placeholder. The button invokes its closure once per activation, and native disabled behavior prevents activation while `canRetry` is false. The caller starts work and changes the phase; this view performs no requests, automatic retries, timers, or persistence.

[`ContentUnavailableView`](https://developer.apple.com/documentation/swiftui/contentunavailableview) is another native option for a dedicated empty page. Compare it at the consumer's actual width and height before using it in an inline section. Keep native `Label`, `ProgressView`, and buttons for compact inline feedback when a full unavailable-content presentation adds unnecessary space.

## Verification

On macOS 27.2, a temporary host compiled this example and compared it with `ContentUnavailableView` at 340 points. All three phases were visually distinct. A long English and Italian description wrapped inside the compact surface. Omitting the description and action removed their space. One retry activation incremented a caller-owned counter once; a disabled retry left it unchanged. Accessibility inspection exposed the busy label and disabled button state. The larger unavailable-content presentation remains suitable for dedicated empty pages.
