# Project Agents.md Guide

This is a [MoonBit](https://docs.moonbitlang.com) project.

Browse and install extra skills here:
<https://github.com/moonbitlang/skills>

## Project Structure

- `moon.mod` at the module root lists module metadata.

- Each directory with a `moon.pkg` file is a package. A package is the
  compilation unit; all `.mbt` files in the same package share scope.

- Tools are grouped by responsibility:

  ```
  better-edit-tools-mcp/
  ├── cmd/main/        # CLI / MCP server entry
  ├── error/           # Shared BeError type
  ├── read/            # be-read and range detection tools
  ├── write/           # be-write and full-file write tools
  ├── edit/            # Incremental editing tools (insert/delete/replace/chip)
  └── check/           # Structural checks (balance)
  ```

- Each package contains `.mbt` source files, black-box tests (`_test.mbt`),
  and white-box tests (`_wbtest.mbt`).

- Cross-cutting types (e.g. errors) live in the `error/` package.

## Coding Conventions

- MoonBit code is organized in blocks separated by `///|`. Block order is
  irrelevant; refactor block by block when possible.

- Keep deprecated blocks in `deprecated.mbt` inside each package.

- Use the shared `BeError` from `error/` for all tool errors. Extend it with
  new variants instead of introducing per-package suberrors.

## Testing

- Run `moon test` to execute tests; run `moon test --update` to refresh
  snapshots after intentional output changes.

- Black-box tests call only public APIs; white-box tests validate internal
  helpers.

- File I/O tests may use temporary files under `/tmp/` with absolute paths.
  Clean them up after each test.

- Prefer `assert_eq` or `assert_true(pattern is Pattern(...))` for stable
  results. For snapshot tests, derive `Debug` and use `debug_inspect` instead
  of deriving `Show`.

- Use `moon coverage analyze > uncovered.log` to inspect test coverage.

## Tooling

- Format code with `moon fmt`.

- Use `moon ide` for navigation: `peek-def`, `outline`, `find-references`.
  See `$moonbit-agent-guide` for details.

- Run `moon info` to generate `.mbti` interface files. They summarize the
  public API surface. If `.mbti` files do not change, your change likely does
  not affect external consumers and is a safe refactoring.

- Before committing, run:`moon fmt && moon info`

  Review `.mbti` diffs to confirm public API changes are intentional.

## Git Hooks

- The `pre-commit` hook in `.githooks/pre-commit` runs `moon fmt && moon info`
  before each commit.

- Enable hooks after cloning:

  ```bash
  ./.githooks/setup.sh
  ```

- If the hook modifies `.mbt` or `.mbti` files, the commit is blocked. Review
  the changes, stage them, and commit again. See `.githooks/README.md` for
  details.
