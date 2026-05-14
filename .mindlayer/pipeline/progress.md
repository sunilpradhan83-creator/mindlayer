# Progress

## Current Phase

id: ml-20260505-006
created: 2026-05-05
updated: 2026-05-14
scope: project
type: progress
tags: [v4, phase-2, command-runner, guarded-writes, script, dogfood]
confidence: high
status: active
source: implementation

### Summary
V4 active foundation complete — ml script runtime shipped; next is open source security hardening before release.

### Details
- Shipped: `src/ml` argparse entry point, command modules under `src/commands/`, deterministic index ranking, boot receipt output that avoids `index-full.md`, memory diff summary, health scoring, and session threshold reporting.
- Shipped: `tests/ml/` CLI contract fixtures, `tools/test.sh` integration, and `install.sh` runtime installation to `~/.mindlayer/bin/ml` with support modules in `~/.mindlayer/lib/commands`.
- Shipped: guarded write commands for `ml save`, `ml clean`, and `ml session write` behind explicit approval.
- Shipped: `ml clean` as the single public cleanup command, with archive/delete as internal approved actions and post-completion clean scans.
- Shipped: full `ml script` runtime — signal, cut, refine, story start/done, transfer. 109 CLI contract tests, full suite clean. Commits: 1e35d7f, 2fdbc21.
- Next: open source security hardening — CODEOWNERS, branch protection, release signing + checksums for `install.sh`. Then IDE extensions.

### When to use
Use when orienting to the current project phase or deciding what to work on next.

### Related
ml-20260430-005
ml-20260505-003
