# Compact settings

Use `PanelSection` for a titled surface inside a panel. It reuses `SectionLabel` and the shared spacing, radius, and typography tokens. The optional description follows the content; omit it to leave no description text or spacing. Titles and descriptions are caller-supplied strings, resolved through the app's localization system.

The container adds no control behavior. Keep bindings, validation, persistence, and actions in the app. Use native controls and `LabeledContent` for rows; give each control its own meaningful title even when its visual label is hidden. Avoid making a whole row clickable or combining a section into one accessibility element.

## Composition

This example has independent bindings, a wrapping label, a description, a section without a description, and a disabled control. The strings are example copy; replace them with localized strings from the consumer.

```swift
import MenuBarKit
import SwiftUI

struct SettingsExample: View {
    @State private var enabled = true
    @State private var appearance = "system"
    @State private var delay = 5
    @State private var automaticUpdates = false

    private let automaticTitle = "Apply settings automatically when the configuration changes"

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            PanelSection(
                "Preferences",
                description: "Changes apply to the current configuration."
            ) {
                LabeledContent {
                    Toggle(automaticTitle, isOn: $enabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                } label: {
                    Text(automaticTitle)
                        .fixedSize(horizontal: false, vertical: true)
                }
                LabeledContent("Appearance") {
                    Picker("Appearance", selection: $appearance) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .fixedSize()
                }
                LabeledContent("Delay in seconds") {
                    TextField("Delay in seconds", value: $delay, format: .number)
                        .labelsHidden()
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                }
            }
            PanelSection("Updates") {
                Toggle("Check for updates automatically", isOn: $automaticUpdates)
                    .fixedSize(horizontal: false, vertical: true)
                    .disabled(true)
            }
        }
        .controlSize(.small)
        .padding(Theme.Spacing.m)
        .frame(width: Theme.defaultPanelWidth)
    }
}
```

Keep long row labels flexible and vertically sized, as shown above for both `Text` and the disabled `Toggle`. Avoid a fixed width for the label itself. The numeric field has a bounded width appropriate to this example; each app chooses its input width and validation. A long picker value may need a vertical label and control composition instead of a fixed-width horizontal row.

`PanelSection` does not set a toggle style or control size, hide control labels, manage focus, or add scrolling. Apply those choices in the consumer. Use `PanelChrome` at the panel root as usual.

## Native alternatives

Compare the layout needed by the consumer with native [`Form`](https://developer.apple.com/documentation/swiftui/form), [`Section`](https://developer.apple.com/documentation/swiftui/section), and [`LabeledContent`](https://developer.apple.com/documentation/swiftui/labeledcontent). A grouped form is useful when a scrolling settings page is wanted. In the temporary 340-point comparison, the automatic form used a control column that crowded long labels, while the grouped form added row spacing and a scroll area. `PanelSection` shares the existing compact surface without introducing a form or a control wrapper. `LabeledContent` remains the native row composition.

## Verification

On 2026-10-29, a temporary host on macOS 27.2 checked a 340-point composition in English and Italian, in light and dark appearance. Long titles, control labels, and descriptions wrapped; omitting a description left no extra line. Toggle, picker, and numeric-field changes reached the caller's bindings, and the disabled control stayed unchanged. Keyboard checks covered picker arrow selection and numeric text entry. The accessibility tree retained control names with hidden visual labels, values, disabled state, and section headings. The example above compiled against the local package.

The package built and all 9 existing tests passed. This visual container adds no deterministic control logic or new test suite. Runtime checks on macOS 15 and 26, full keyboard focus navigation, and VoiceOver spoken output remain unverified.
