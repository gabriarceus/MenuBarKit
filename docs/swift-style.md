# Swift style

These rules apply to every Swift change in this repository. swift-format handles layout (see [Development](development.md#validation)); this guide covers what a formatter cannot check. For comments and documentation, read the [Writing guide](writing-guide.md).

## Scope and reuse

- Make the smallest change that solves the task completely. Do not add options, abstractions, or "for later" code that nobody asked for.
- Before writing a helper, search the package for one that already does the job, and extend it when the change is generic.
- Add a type to the package only when more than one app needs it. App-specific screens, persistence, and policy stay in the consumer.
- Touch only what the task needs. Do not refactor or reformat unrelated code. Mention dead code you notice instead of deleting it.

## Public API

- Keep the public surface small. Mark a symbol `public` only when consumers need it; tests reach internal symbols through `@testable import`.
- Every public symbol has a doc comment that states its contract.
- A changed signature, a removed symbol, or changed default behavior is a breaking change and needs a major version. Prefer a new parameter with a default that keeps the old behavior.
- Name a parameter or default after what the caller decides, such as `delay` or `isActive`. Defaults that consumers rely on stay stable within a major version.
- Helpers adopt resources the caller created. They do not register, persist, or change global state while a view is built.

## Naming

- Name a type or function after its technical behavior, not after the app that first used it.
- Follow the Swift API Design Guidelines: clear call sites, no abbreviations except well-known ones (ID, URL, UI).
- Shared extensions live in a file named after their purpose, not in the first file that needed them.

## Types and branching

- Branch on enums with an exhaustive `switch`, without `default`, so a new case causes a compile error everywhere it matters.
- For system enums that can grow, use `@unknown default` and make the unknown case visible, as LoginItem does with an explicit unavailable status.
- Do not hide invalid states behind silent fallbacks. Document a fallback on the symbol that applies it, as Localizer does for format mismatches.
- Force unwraps are for values that cannot fail, such as a copy of an `NSImage`. Use `guard` everywhere else.
- Keep a single owner for every constant. When two places need the same value, expose it from its owner, as PanelHelp does for its default delay.

## Concurrency

- Panels, controllers, observers, and views are `@MainActor`.
- AppKit and notification-center callbacks may arrive on any thread. Hop to the main actor before touching state, as Notifier does.
- Delayed work uses `Task.sleep`, keeps its task handle, cancels the previous task, and checks `Task.isCancelled` after sleeping.
- A helper that installs observers or monitors removes them on disconnect and on release.

## SwiftUI and AppKit

- Package text that users see or hear goes through the package's Localizable.strings, in every bundled language. Consumers pass their own strings in.
- Keep the macOS 26 surface and its fallback in the same type, selected with `#available`, so callers never branch on the system version.
- A small private helper stays in the file that uses it. Move it to its own file when a second file needs it.
- Code that depends on platform behavior, such as window shadows, mouse tracking, or hover delivery, gets an inline comment that names the behavior.

## Tests

- Tests use XCTest and live in Tests/MenuBarKitTests. Each test file covers one source owner; the list is in [Development](development.md#validation).
- Test deterministic logic: placement, presentation state, commands, localization, and status mapping. A view that only lays out content gets no test.
- Name a test after the behavior it protects, for example `testEscapedPercentIsNotCountedAsAnArgument`.
- A bug fix comes with a test that fails without the fix, when the logic can run without a real menu bar app.
- Hover, window, and system-service behavior need a real app. List the manual checks you did not run instead of claiming them.
