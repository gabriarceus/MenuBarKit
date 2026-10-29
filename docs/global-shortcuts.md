# Consumer-side global shortcuts

The app can add [KeyboardShortcuts 3.1.0](https://github.com/sindresorhus/KeyboardShortcuts/releases/tag/3.1.0) to its own dependencies. MenuBarKit keeps no dependency on it. This guide targets that release's [event stream](https://github.com/sindresorhus/KeyboardShortcuts/blob/3.1.0/Sources/KeyboardShortcuts/KeyboardShortcuts.swift) and [recorder](https://github.com/sindresorhus/KeyboardShortcuts/blob/3.1.0/Sources/KeyboardShortcuts/Recorder.swift) APIs.

## Action ownership

Give the app action a dedicated shortcut name. Retain an owner for the app lifecycle, with a cancellable event-stream task. Handle key release once and invoke `StatusItemController.toggle()`, the same action as the status item.

```swift
import KeyboardShortcuts
import MenuBarKit

extension KeyboardShortcuts.Name {
    static let togglePanel = Self("togglePanel")
}

@MainActor
final class PanelShortcut {
    private var task: Task<Void, Never>?

    init(controller: StatusItemController) {
        task = Task { [weak controller] in
            for await event in KeyboardShortcuts.events(for: .togglePanel) {
                guard !Task.isCancelled else { break }
                switch event {
                case .keyDown:
                    break
                case .keyUp:
                    controller?.toggle()
                }
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    isolated deinit {
        task?.cancel()
    }
}
```

Cancellation ends this listener and lets the package unregister its shortcut when no other listener needs it. Avoid global handler cleanup. Keep the owner alive while the panel is closed, so the shortcut can reopen it; a task attached only to visible panel content has the wrong lifetime.

## Recording and availability

Use `KeyboardShortcuts.Recorder("Toggle panel", name: .togglePanel, onChange: ...)` in the consumer's settings. Its native recorder handles replacement, clearing, and conflict validation. Supply a localized title and keep validation feedback visible. The package owns its shortcut storage; the app owns any separate enable preference.

Use `KeyboardShortcuts.setShortcut(nil, for: .togglePanel)` for an explicit Clear action. `disable(.togglePanel)` unregisters that dedicated action without clearing its selection; `enable(.togglePanel)` restores it. Expose the distinction between no selected shortcut, disabled registration, and a selected shortcut whose registration is unavailable. Read `getShortcut(for:)` and `isEnabled(for:)` after changes or activation; a stored shortcut alone is not proof of active registration.

Check key-release activation, replacement, clearing, disabled registration, a conflicting shortcut, and listener cancellation in the consumer. The consumer must choose its own dependency version and runtime checks; this guide does not add a hotkey engine, recorder wrapper, global cleanup hook, or third-party dependency to the core.

## Verification

With the user's download approval, the public 3.1.0 source archive was built as a local dependency of an isolated host in `/private/tmp`. The exact owner example above compiled against that release and the current MenuBarKit. The host included the native recorder, clear/enable controls, registration status, and owner release. The user confirmed recording, replacement, clearing, disabled registration, a Cmd+C conflict, and stopping the listener on macOS 27.2. MenuBarKit's manifest and DisplayAnchor were unchanged.
