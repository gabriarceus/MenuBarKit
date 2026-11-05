# Development

Read [Architecture](architecture.md) for ownership and behavior, and [Contributing](../CONTRIBUTING.md) for contribution guidance.

## Toolchain

Development requires Xcode 26 with Swift 6.2 or newer and the macOS 26 SDK or newer. [Package.swift](../Package.swift) defines the tools version, the deployment target, and resource processing. The package has no dependencies to resolve.

## Working with a consumer app

Consumer apps such as [DisplayAnchor](https://github.com/gabriarceus/DisplayAnchor) select a sibling MenuBarKit checkout when one exists next to them, and the GitHub package otherwise. Cloning this repository next to an app lets you change the library and rebuild the app without a manifest change. A local build uses the checkout's current contents, regardless of its tags.

SwiftPM caches the evaluated manifest of the consumer. After adding or removing the sibling checkout, purge the package cache and reset package state in the consumer; reset alone does not clear the shared manifest cache.

## Validation

The automated checks are the SwiftPM test suite and swift-format. Run both on macOS before requesting review.

swift-format ships with the Swift toolchain. [.swift-format](../.swift-format) holds the configuration: four-space indentation and 120-column lines. Format the files you change in place and run the strict lint over Package.swift, Sources, and Tests; it must report no findings.

Tests use XCTest and live in [Tests/MenuBarKitTests](../Tests/MenuBarKitTests). Use the matching test file when changing deterministic behavior.

| Test file                          | Coverage                                                                                          |
| ---------------------------------- | ------------------------------------------------------------------------------------------------- |
| AppLanguageOptionTests.swift       | Identifiers and the system-follow option                                                          |
| LocalizerTests.swift               | Missing keys, forced and empty languages, format arguments, literal percent signs, package strings |
| PanelNavigationTests.swift         | Published initial and changed screens                                                             |
| PanelCommandsTests.swift           | Edit menu creation, existing menus, and child-first Escape                                        |
| PanelPlacementTests.swift          | Anchors on negative origins, hidden or invalid anchors, display removal, growth, and fitting      |
| PanelHelpTests.swift               | Delay, cancellation, replaced requests, release, bubble width, and placement at every edge        |
| StatusItemControllerTests.swift    | Outside-click exclusion, icon updates, presentation, screen changes, disconnect, and release      |
| LoginItemTests.swift               | Status mapping, unbundled processes, approval, failed operations, and activation refresh          |

## Manual checks

Window behavior, hover, and system services need a real menu bar app. Select the checks that exercise the changed behavior:

- Open and close the panel from the status item and by an outside click. Check that the same click never dismisses and reopens it, and that the secondary menu opens on right-click and Control-click.
- Grow and shrink the content while the panel is open. Check the anchored top edge, fitting near screen edges, and the panel on each display, including one with a negative origin.
- Check glass, shadow, and tint in light and dark appearance, with Reduce Transparency on and off.
- Hover several help targets quickly, scroll while help is visible, and close the panel with help pending.
- Use cut, copy, paste, select all, undo, and redo in a text field of the panel, and Escape with and without a child edit in progress.
- Turn launch at login on and off from an installed app bundle, including the approval state.
- Send immediate and scheduled notifications from a built app bundle.
- Run the panel and components on macOS 15 and macOS 26 when a change touches a fallback path, and check VoiceOver names and hints.

## Releases

A release is a semantic-version Git tag on main, such as 1.3.0. Move the Unreleased entries in [CHANGELOG.md](../CHANGELOG.md) into a section for that version before tagging. Consumers that resolve the package from GitHub pick up a release only through a tag; a consumer that depends on new API raises its minimum version in its own manifest.
