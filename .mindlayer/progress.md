# Progress

## Current Phase

id: ml-20260505-006
created: 2026-05-05
updated: 2026-05-12
scope: project
type: progress
tags: [v4, phase-2, command-runner, guarded-writes, dogfood]
confidence: high
status: active
source: implementation

### Summary
V4 Phase 2 guarded write commands shipped; current work is dogfood polish before SCRIPT/runtime expansion.

### Details
- Shipped: `src/ml` argparse entry point, command modules under `src/commands/`, deterministic index ranking, boot receipt output that avoids `index-full.md`, memory diff summary, health scoring, and session threshold reporting.
- Shipped: `tests/ml/` CLI contract fixtures, `tools/test.sh` integration, and `install.sh` runtime installation to `~/.mindlayer/bin/ml` with support modules in `~/.mindlayer/lib/commands`.
- Shipped: guarded write commands for `ml save`, `ml archive`, and `ml session write` behind explicit approval.
- Next: dogfood current `ml` behavior, fix stale orientation, then plan SCRIPT/runtime expansion.

### When to use
Use when orienting to the current project phase or deciding what to work on next.

### Related
ml-20260430-005
ml-20260505-003
