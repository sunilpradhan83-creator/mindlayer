# Progress

## Current Phase

id: ml-20260505-006
created: 2026-05-05
updated: 2026-07-01
scope: project
type: progress
tags: [open-source, developer-preview, script, stage-0, correctness, adr, migration]
confidence: high
status: in-progress
source: conversation

### Summary
ADR-0001 target architecture is frozen and committed on branch `adr-0001-architecture`
(commit `c669261`; `main` untouched). Typed-status schema landed. The 13 spec-layout
test failures are cleared (root cause: stale live `~/.mindlayer/` install, not a repo
defect; re-synced via `install.sh --global-only`). Suite is 81/0 green, strict lint 0
errors, 2 W2 near-limit warnings. Current phase: Step 2 — ADR-0001 migration foundation
(not started, deferred to a fresh session). Ordered plan: Step 2a runtime+verification
scaffold with dual-layout back-compat, 2b pipeline/->work/current.md, 2c templates->seed/,
2d router->executable runtime. MCP work (Steps 3-4) follows the migration, not before.

### Details
- Completed 2026-07-01: committed ADR-0001 + typed-status schema (`c669261`), reviewed for consistency across index/architecture.md/schema/install.sh/lint.sh, and cleared the 13 spec-layout failures via a non-destructive live-runtime re-sync. Next work is Step 2 (ADR migration foundation), deferred to a fresh session; see `knowledge/sessions/2026-07-01.md` for the ordered 2a-2d slices.
- Completed this session: created `knowledge/decisions/script-v0.1.md`, marked `script-v4.md` superseded, updated decisions index, rewrote canonical roadmap, mirrored public ROADMAP, added SCRIPT enforcement backlog item, and wrote the 2026-05-17 session summary.
- Completed after Stage 0.0: Item 0 Day 1 - starter-content sentinel format chosen and boot truth fixes implemented so starter project/personal memory does not appear substantive.
- Completed after Item 0 Day 1: fixed fresh installs so `.mindlayer/router.md` is created from `project-template/router.md`, with local install coverage for fresh and skip-flag installs.
- Completed after project router fix: fixed `ml diff` so entries moved into `.mindlayer/pipeline/archive/` report as archived instead of new, including Git rename handling and regression coverage.
- Completed after `ml diff` fix: fixed `ml load` ranking so importance/recency metadata cannot rank entries without a real query hit, with regression coverage for unrelated high-importance preferences.
- Completed after `ml load` ranking fix: fixed `ml load` section extraction so nested summaries stay attached to their parent heading and title/heading mismatches can resolve by entry id.
- Completed after `ml load` section fix: fixed `ml status` duplicate detection so repeated standard subheadings like `### Summary` do not trigger duplicate-entry warnings, while duplicate `##` entry headings still do.
- Completed after `ml status` fix: fixed hierarchical `ml clean`, nearest-index `ml save`, README CLI/runtime drift, and README adapter drift; added regression/lint coverage.
- Stage 0.1 baseline is frozen as a 0.1 Developer Preview, not a 1.0 launch.
- Existing V4 runtime work remains shipped, but the next release focus is correctness, positioning, open-source hygiene, and rename.
- Next: begin 0.1 launch hygiene from the roadmap: open-source files, CI, release notes, rename, and final clean test/lint output.

### When to use
Use when orienting to the current project phase or deciding what to work on next.

### Related
ml-20260430-005
ml-20260505-003
