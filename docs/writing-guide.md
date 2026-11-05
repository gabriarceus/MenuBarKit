# Writing guide

These rules apply to code comments, project documentation, the changelog, and commit messages. Write in plain English: short sentences, common words, few negations. Keep the precise technical term when it is the right word.

## Where information goes

Each kind of information has one home. Put it there and nowhere else.

| Information                                                        | Home                                              |
| ------------------------------------------------------------------ | ------------------------------------------------- |
| What a symbol is and does, what nil means, side effects, ownership | Doc comment (`///`) on the symbol                 |
| Why non-obvious code has its shape                                 | Inline comment (`//`) next to that code           |
| How to use an area of the package                                  | README.md and the usage guide it links            |
| Concepts, constraints, and file ownership                          | The owning document in docs/, listed in AGENTS.md |
| What changed for consumers of a release                            | CHANGELOG.md                                      |
| Why a change was made, alternatives, history, test sessions        | Commit message or pull request                    |
| Instructions for AI agents                                         | AGENTS.md only                                    |

## Doc comments

- State the contract: what the symbol is and does. Add what nil means, when it fails, side effects, and what would surprise a caller. Use one line unless the behavior needs more.
- Do not explain why the symbol exists, who calls it, or how it was fixed. Phrases such as "so that", "in order to", "used by", "called from", "now", "no longer", and "previously" usually mark text that belongs in a commit.
- Refer to symbols with backticks, such as `isActive` or `present(at:)`. Square brackets are not Swift documentation syntax.
- Put the doc comment directly on the declaration it describes.
- When behavior changes, update its doc comment in the same change. Keep the comments of code you did not change.

## Inline comments

- Write one only when the reason is not visible in the code: a platform quirk, an ordering constraint, a unit, a piece of math, or a workaround. "The glass renders asynchronously; recompute the shadow once it has drawn" is a good example.
- Do not restate what the code does.
- Do not write "keep in sync with X". Remove the duplication instead, with one owner or a shared constant. When the other side is outside the repository (a system API, a consumer's manifest), a short comment that names it is fine.

## Project documentation

- Each topic has one owning document. README.md introduces the package, lists the API, and links the usage guides. Usage guides explain how a consumer adopts one area, with a short example. Architecture owns concepts and file ownership, development owns checks and releases, and the Swift style guide and this guide own conventions. Link to the owner instead of repeating it.
- Code samples belong in README.md and the usage guides, where they show an integration. Keep them short and compilable against the current API.
- Write only lasting facts. No dates of test runs, test-session results, "the user confirmed" notes, or TODO lists. Remaining manual checks go to the list in [Development](development.md#manual-checks).
- Keep consumer apps out of usage guides, except as an example of a consumer.
- When a change affects a documented concept, API, or file, update the owning document and its links in the same change.
- In Markdown, write one line per paragraph or list item. Do not wrap prose by hand.

## Changelog

CHANGELOG.md follows Keep a Changelog. Consumers read it to decide whether to upgrade.

- Add entries under Unreleased only. A released section changes only to fix a mistake.
- Use the categories Added, Changed, Fixed, Maintenance, and Removed, in this order, and only those a release needs. Keep entries in alphabetical order within a category.
- Write Added, Changed, Fixed, and Removed for consumers: the public API and the behavior they will notice. Name the symbol in backticks.
- Put changes that leave the API and behavior unchanged under Maintenance: tooling, tests, and documentation.
- One change gets one entry. Small fixes for the same change share that entry.

## Commit messages and pull requests

- Write a short imperative summary line, then the reason for the change and anything a reviewer must check by hand.
- The design rationale, the alternatives that were rejected, and the history of a fix go here, not into code comments.
