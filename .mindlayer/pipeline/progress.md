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
Stage 0.0 for the 0.1 Developer Preview is saved. Item 0 Day 1 starter boot truth, the missing project router install blocker, the `ml diff` archived-movement blocker, and the `ml load` metadata-only ranking blocker are fixed. Next work is to cut another remaining 0.1 correctness roadmap blocker into a focused implementation story.

### Details
- Completed this session: created `knowledge/decisions/script-v0.1.md`, marked `script-v4.md` superseded, updated decisions index, rewrote canonical roadmap, mirrored public ROADMAP, added SCRIPT enforcement backlog item, and wrote the 2026-05-17 session summary.
- Completed after Stage 0.0: Item 0 Day 1 - starter-content sentinel format chosen and boot truth fixes implemented so starter project/personal memory does not appear substantive.
- Completed after Item 0 Day 1: fixed fresh installs so `.mindlayer/router.md` is created from `project-template/router.md`, with local install coverage for fresh and skip-flag installs.
- Completed after project router fix: fixed `ml diff` so entries moved into `.mindlayer/pipeline/archive/` report as archived instead of new, including Git rename handling and regression coverage.
- Completed after `ml diff` fix: fixed `ml load` ranking so importance/recency metadata cannot rank entries without a real query hit, with regression coverage for unrelated high-importance preferences.
- Stage 0.1 baseline is frozen as a 0.1 Developer Preview, not a 1.0 launch.
- Existing V4 runtime work remains shipped, but the next release focus is correctness, positioning, open-source hygiene, and rename.
- Next: choose the next 0.1 correctness blocker from the roadmap and cut it into a focused SCRIPT story.

### When to use
Use when orienting to the current project phase or deciding what to work on next.

### Related
ml-20260430-005
ml-20260505-003
