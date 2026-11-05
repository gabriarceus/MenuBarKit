# Contributing to MenuBarKit

Thanks for helping improve MenuBarKit. Small, focused changes are easiest to review.

## Before opening an issue

Search existing issues first. For a visual or interaction problem, include the macOS version, the component or helper involved, and a short code sample or screenshot that shows the problem.

## Pull requests

- Create a branch from `main`; do not commit directly to `main`.
- Keep each pull request scoped to one change and explain how you tested it.
- Add or update tests for deterministic logic where practical.
- Run `swift test` and the swift-format lint on macOS before requesting review.
- Keep the package free of external dependencies.

The package needs Xcode 26 (Swift 6.2) or newer. Panel and interaction behavior must be tested manually in a real menu bar app. See [Development](docs/development.md) for checks and local work with a consumer app, and [Architecture](docs/architecture.md) for the source map. Agents should start with [AGENTS.md](AGENTS.md).

By contributing, you agree that your contributions are licensed under the MIT License.
