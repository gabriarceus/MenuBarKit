# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `panelHelpHost(isActive:delay:)` sets how long the pointer must rest on a target before its help appears.

### Changed

- Contextual help appears after one second by default, instead of 350 milliseconds.

### Fixed

- Contextual help is as wide as its text and wraps only beyond 260 points. Short help no longer shows a wide bubble.
- `Localizer` treats `%%` as a literal percent sign, so a string such as `"%d%% done"` is formatted with its argument.
- The spoken name of `MeterBar` follows the SwiftUI `locale` of the view, so an app with a forced language no longer gets it in the system language.

### Maintenance

- Added AGENTS.md, contributing, architecture, development, Swift style, and writing guides. The README lists the API and links the usage guides; test-session results and the compatibility record were removed from the documentation.
- Added a swift-format configuration and formatted the package.
- An unknown notification authorization status is logged.

## [1.2.0] - 2026-10-30

### Added

- `PanelSection` for compact titled surfaces with an optional description and caller-supplied native controls. See the [settings composition guide](docs/compact-settings.md).
- Native launch-at-login state and explicit registration actions, including approval, unavailable states, errors, and refresh after returning from System Settings.
- Native panel and icon-button surfaces for macOS 15, preserving Liquid Glass on macOS 26 and later. The package deployment target is now macOS 15.
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
