# Agent context

MenuBarKit is a Swift package with the shared panel, design tokens, components, and optional platform helpers for macOS menu bar apps. Use this file as the entry point for project work. Read the relevant documents below before exploring the source; each topic has one main home.

## Read by task

| Task                                                   | Read                                                                     |
| ------------------------------------------------------ | ------------------------------------------------------------------------ |
| Any project change                                     | [Architecture](docs/architecture.md) and [Contributing](CONTRIBUTING.md) |
| Writing or reviewing Swift code                        | [Swift style](docs/swift-style.md)                                       |
| Writing comments, documentation, changelog, or commits | [Writing guide](docs/writing-guide.md)                                   |
| Building, testing, or local work with a consumer app   | [Development](docs/development.md)                                       |
| Using or changing a public API                         | [README](README.md) and the usage guide it links for that area           |

Most tasks match more than one row: a code change usually needs Architecture, Swift style, and the Writing guide. The architecture guide maps responsibilities to source files. The development guide maps tests and lists the checks that need a real Mac.

## Project decisions

- The package has no external dependencies. Integrations such as global shortcuts stay in the consumer; see the [global shortcuts guide](docs/global-shortcuts.md).
- The consumer owns the app lifecycle: the app delegate, the status item, the panel's content, persistence, and registration. App-management helpers are opt-in and adopt resources the app created.
- Public API is a contract with every consumer. A breaking change needs a major version; a new capability needs a minor version.
- The deployment target is macOS 15. Liquid Glass is used on macOS 26 and later, with small native fallbacks below it. See the platform policy in [Architecture](docs/architecture.md#platform-support).
- All package strings are localized in every bundled language. Consumer strings stay in the consumer.

## Boundaries

- Tagging a release, pushing, and publishing need an explicit request from the owner.
- Do not change a consumer app (such as DisplayAnchor) from this repository. When a change in MenuBarKit needs a consumer change, say so and stop.
- Never inspect or presence-check credentials.
- Without a Mac, source inspection is not a runtime test. Say which checks remain unrun.

## Before you finish

- Run `swift test`.
- Format the Swift files you changed with `swift format -i`, and check that `swift format lint --recursive --strict Package.swift Sources Tests` is clean.
- Read every comment you added or changed against the [Writing guide](docs/writing-guide.md): a contract or a reason, no history.
- Update the owning document when a documented concept, API, or file changes.
- Add one entry under Unreleased in [CHANGELOG.md](CHANGELOG.md), written for consumers of the package, or under Maintenance when the public API and behavior do not change.
- Leave no temporary notes, debug output, or test artifacts in code or documentation.
- List the manual checks that the change needs and that you did not run.
