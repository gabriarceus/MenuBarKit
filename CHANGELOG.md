# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `PanelSection` for compact titled surfaces with an optional description and caller-supplied native controls. See the [settings composition guide](docs/compact-settings.md).
- Native panel and icon-button surfaces for macOS 15, preserving Liquid Glass on macOS 26 and later. The package deployment target is now macOS 15. Build and focused UI checks ran on macOS 27.0.1; runtime verification on macOS 15 and 26 remains pending. See the [verification summary](docs/macos-compatibility.md).

## [1.1.0] - 2026-08-25

### Added

- Unit test target covering `Localizer`, `PanelNavigation`, and `AppLanguageOption`.
- `GlassIconButton` now accepts an optional `accessibilityLabel` (defaults to the system image name).
- `MeterBar` exposes an accessibility element with a percentage value.
- `MeterRow` combines its children into a single accessibility element.
- `Notifier.onDeliveryError` callback, invoked when the notification center rejects a delivery request.

## [1.0.0] - Initial release

- Floating menu-bar panel with Liquid Glass chrome (`MenuBarPanel`, `PanelChrome`).
- Design tokens (`Theme`) and reusable SwiftUI components (`GlassIconButton`, `MeterBar`, `MeterRow`, `PanelHeader`, `SectionLabel`, `inputChrome`).
- Panel navigation state (`PanelNavigation`).
- Notification scheduling (`Notifier`).
- Localization helpers (`Localizer`, `AppLanguageOption`, bundle utilities).
