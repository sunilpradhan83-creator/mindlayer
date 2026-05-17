# Changelog

All notable changes to MindLayer are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow [Semantic Versioning](https://semver.org/).

---

## [Unreleased]

- CONTRIBUTING.md added.

---

## [0.1.0] - upcoming

First public release. Developer preview — correct and honest, not polished.

### Added

- Local `ml` command runner: `boot`, `load`, `status`, `diff`, `save`, `clean`, `session`, `script`, `archive`.
- Programmatic ranked loader (`ml load`) with deterministic scoring and query-gated ranking.
- `ml diff` showing project memory changes since the last session commit, with archive/rename handling.
- `ml status` per-file health check: line budget, staleness, duplicate headings, and overall summary.
- `ml script` lifecycle commands: `signal`, `cut`, `refine`, `story`, `transfer`.
- Hierarchical `ml clean` and nearest-index `ml save` with explicit approval gates.
- Starter-content sentinel format so fresh installs never report placeholder files as substantive memory.
- Project router template installed on fresh installs so `.mindlayer/router.md` is always present.
- Adapter integrity lock (`adapters.lock`) preventing silent template drift or accidental user-content overwrites.
- Selective adapter detection: only installs adapters for tools present in the environment.
- `E8` lint check: detects drift between `src/commands/` and the installed `~/.mindlayer/lib/commands/`.
- W4 lint false-positive fix: `YYYY-MM-DD` in session filename patterns and installer-managed headers no longer flagged as scaffold placeholders.
- Sandboxed install test suite covering fresh, idempotent, skip-flag, selective, and drift scenarios.
- Behavior contract tests for boot, continuity, per-turn, load ranking, diff, onboard, and autosummarize.
- `ml` CLI contract tests for all commands.
- Live agent dogfood harness for Claude and Codex.

### Fixed

- `ml load` section extraction: nested summaries now stay attached to their parent heading; title/heading mismatches resolve by entry id.
- `ml load` ranking: entries without a query hit cannot rank above entries that match, regardless of importance or recency metadata.
- `ml status` duplicate detection: repeated standard subheadings (`### Summary`, `### Details`) no longer trigger false CRITICAL; only duplicate `##` entry headings do.
- `ml diff` archived entries: items moved into `pipeline/archive/` now report as archived rather than new, including Git rename detection.
- Boot truth: starter project and personal memory no longer reported as substantive context on fresh installs.
- README aligned with actual CLI commands, adapter model, and runtime architecture.

---

## [0.0.1] - 2026-04-30

Internal seed. Markdown memory layout, global/project two-layer model, thin tool adapters, and initial install script.
