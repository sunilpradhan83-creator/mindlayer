# Progress

## Current Phase

id: ml-20260505-006
created: 2026-05-05
updated: 2026-05-17
scope: project
type: progress
tags: [open-source, developer-preview, script, stage-0, correctness]
confidence: high
status: in-progress
source: conversation

### Summary
Stage 0.1 Developer Preview hygiene complete. All open-source files shipped: CONTRIBUTING, CHANGELOG, README rewrite, SECURITY, CODE_OF_CONDUCT, CI workflow, issue templates, CODEOWNERS, comparison.md, examples/quickstart.md, RELEASE_NOTES. tools/test.sh passes with 0 failures, 0 lint errors, 1 known W2. Next: PyPI rename, then rc soak (48–72h, 3 independent fresh installs) before public launch.

### Details
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
