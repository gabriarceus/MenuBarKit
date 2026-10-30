# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-10-30

### Added

- `PanelSection` for compact titled surfaces with an optional description and caller-supplied native controls. See the [settings composition guide](docs/compact-settings.md).
- Native launch-at-login state and explicit registration actions, including approval, unavailable states, errors, and refresh after returning from System Settings.
- Native panel and icon-button surfaces for macOS 15, preserving Liquid Glass on macOS 26 and later. The package deployment target is now macOS 15. Build and focused UI checks ran on macOS 27.0.1; runtime verification on macOS 15 and 26 remains pending. See the [verification summary](docs/macos-compatibility.md).
- Opt-in native edit-menu commands and child-first Escape handling, preserving existing application menus.
- Optional root-hosted contextual help sized to its text within panel bounds, with cancellation on hover exit, removal, and host deactivation; accessible names remain separate from help text.
- Optional status-item integration with primary/secondary actions, template icons, text, and notification dots; optional screen-aware panel positioning with caller-owned content sizing and scrolling.

## [1.1.0] - 2026-08-25

### Added

- `GlassIconButton` now accepts an optional `accessibilityLabel` (defaults to the system image name).
- `MeterBar` exposes an accessibility element with a percentage value.
- `MeterRow` combines its children into a single accessibility element.
- `Notifier.onDeliveryError` callback, invoked when the notification center rejects a delivery request.
- Unit test target covering `Localizer`, `PanelNavigation`, and `AppLanguageOption`.

## [1.0.0] - Initial release

- Design tokens (`Theme`) and reusable SwiftUI components (`GlassIconButton`, `MeterBar`, `MeterRow`, `PanelHeader`, `SectionLabel`, `inputChrome`).
- Floating menu-bar panel with Liquid Glass chrome (`MenuBarPanel`, `PanelChrome`).
- Localization helpers (`Localizer`, `AppLanguageOption`, bundle utilities).
- Notification scheduling (`Notifier`).
- Panel navigation state (`PanelNavigation`).
