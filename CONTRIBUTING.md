# Contributing to MindLayer

MindLayer is in **0.1 Developer Preview**. Contributions are welcome, but the scope is intentionally narrow: correctness, install safety, and honest framing over features.

## Before You Start

Open an issue before writing code. The backlog is small and opinionated. A fix or feature that doesn't match the current phase will be deferred, and an issue lets us align first.

Good areas to contribute now:
- Bug fixes with a clear reproduction
- Test coverage for untested `ml` commands
- Documentation corrections
- Fresh-install experience issues

Defer until after 0.1 stabilizes:
- New `ml` commands
- MCP server or IDE extension
- Embeddings, vector search, or backend storage

## Dev Setup

```sh
git clone <repo>
cd mindlayer
bash install.sh --project .
```

Install into your own home and project. The installer is idempotent.

After editing `src/commands/`, sync the installed copy:

```sh
rm -rf ~/.mindlayer/lib/commands && cp -R src/commands ~/.mindlayer/lib/commands
```

The test suite catches drift between `src/commands/` and the installed copy (`E8`), so sync before running tests.

## Running Tests

```sh
bash tools/test.sh
```

This runs memory/adapter lint, sandboxed install tests, behavior contract tests, and `ml` CLI contract tests. All must pass before opening a PR.

For lint only:

```sh
bash tools/lint.sh --project .
```

For a live agent dogfood check (optional, requires API access):

```sh
tools/dogfood.sh
```

## Code Style

- Python for `src/commands/`. No external dependencies beyond the standard library.
- Bash for `install.sh`, `tools/`, and `tests/`. POSIX-compatible where possible; bash extensions only when necessary.
- No comments explaining what the code does. A comment is only warranted when the why is non-obvious.
- Keep memory files within the 300-line hard limit and 240-line warning threshold.

## Pull Requests

1. Open an issue first for anything beyond a one-line fix.
2. Keep PRs small and focused. One concern per PR.
3. `tools/test.sh` must pass with 0 errors.
4. `tools/lint.sh --project . --strict` must pass.
5. If you change `src/commands/`, update `~/.mindlayer/lib/commands/` in your local env and verify `E8` passes.
6. If you change installer behavior, add or update a scenario in `tests/local-install/test-install.sh`.
7. Update `CHANGELOG.md` under `[Unreleased]` with a one-line summary.

## Reporting Bugs

Use GitHub Issues. Include:
- OS and shell
- `ml` command that failed and its full output
- Whether this is a fresh install or an existing install
- Steps to reproduce

## Architecture Notes

Two memory layers — global (`~/.mindlayer/`) and project (`.mindlayer/`) — with thin tool adapters that are not memory stores. The `ml` CLI is the control plane. Writes require explicit human approval.

The install test suite (`tests/local-install/test-install.sh`) is the authoritative source of truth for installer behavior. If you are unsure whether a change is safe, check what the install tests cover.

Command specs live in `global-template/memory-system/commands/` and are installed to `~/.mindlayer/memory-system/commands/`. Changing a command spec means changing the markdown in `global-template/` and the Python in `src/commands/`.
