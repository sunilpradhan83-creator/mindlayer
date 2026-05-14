# Progress

## Current Phase

id: ml-20260505-006
created: 2026-05-05
updated: 2026-05-14
scope: project
type: progress
tags: [v4, phase-2, command-runner, guarded-writes, dogfood]
confidence: high
status: active
source: implementation

### Summary
V4 Phase 2 guarded writes and ml clean consolidation shipped; next work is SCRIPT/runtime expansion planning.

### Details
- Shipped: `src/ml` argparse entry point, command modules under `src/commands/`, deterministic index ranking, boot receipt output that avoids `index-full.md`, memory diff summary, health scoring, and session threshold reporting.
- Shipped: `tests/ml/` CLI contract fixtures, `tools/test.sh` integration, and `install.sh` runtime installation to `~/.mindlayer/bin/ml` with support modules in `~/.mindlayer/lib/commands`.
- Shipped: guarded write commands for `ml save`, `ml clean`, and `ml session write` behind explicit approval.
- Shipped: `ml clean` as the single public cleanup command, with archive/delete as internal approved actions and post-completion clean scans.
- Next: SCRIPT lifecycle design is complete and review-hardened (ml-20260514-001/002/003 plus external-review refinements in ml-20260514-004). Design is build-ready; next is spec-first implementation of the `ml script` runtime.

### When to use
Use when orienting to the current project phase or deciding what to work on next.

### Related
ml-20260430-005
ml-20260505-003
