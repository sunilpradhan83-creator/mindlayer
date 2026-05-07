# Progress

## Current Phase

id: ml-20260505-006
created: 2026-05-05
updated: 2026-05-07 (session 9)
scope: project
type: progress
tags: [v3, memory-quality, retrieval, per-turn, contracts, commands, onboard]
confidence: high
status: active
source: manual

### Summary
V3 phase 2 further advanced. Commands restructured into memory-system/commands/ subfolder. ml onboard spec added. prompts/ folder deleted. All tests passing.

### Details
- V1 complete: installer, prompt commands, thin adapters, boot/continuity contracts.
- V2 complete: proactive behavior, archive mode, ml session, subdirectories (private/sessions/cache/tmp), Token Burned per-turn block, goal hierarchy.
- V3 phase 1 complete: memory-system/ folder split. Dynamic Next Step queue. Unified router system. Per-file health scoring in ml status.
- V3 phase 2 (partial): per-turn behavioral contracts shipped — load announcement contract, memory candidate scan checklist, index-driven retrieval check. `test-per-turn.sh` shipped (61 tests, all passing). `global-template/memory-system/per-turn.md` synced. `tools/test.sh` now runs 6 suites. Router.md simplified — announcement format owned by per-turn.md.
- V3 phase 2 (session 9): prompts/ folder deleted. Commands restructured into memory-system/commands/ with per-command files (index.md, init.md, retrieve.md, save.md, status.md, archive.md, session.md, onboard.md). Router updated with per-command conditional loads + ml onboard auto-trigger. Routing rules moved from read-write.md into router.md. global-template/index.md and ~/.mindlayer/index.md deleted. memory-system/session.md deleted (merged into commands/session.md). boot.md fixed. All renamed from /m-* to ml * format. 94 tests passing.
- V3 phase 2 (remaining): memory diff — surface what changed in memory since the last session.
- V3 phase 3: auto-summarization suggestions when entries exceed size thresholds.
- V3 phase 4: programmatic index-first retrieval with scored ranking.

### When to use
Use when orienting to the current project phase or deciding what to work on next.

### Related
ml-20260430-005
ml-20260505-003
