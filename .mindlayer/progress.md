# Progress

## Current Phase

id: ml-20260505-006
created: 2026-05-05
updated: 2026-05-07 (session 10)
scope: project
type: progress
tags: [v3, memory-quality, retrieval, per-turn, contracts, commands, onboard]
confidence: high
status: active
source: manual

### Summary
ml onboard fully shipped — spec, boot/router integration, 25 contract tests. V3 phase 2 remaining: memory diff only.

### Details
- V1 complete: installer, prompt commands, thin adapters, boot/continuity contracts.
- V2 complete: proactive behavior, archive mode, ml session, subdirectories (private/sessions/cache/tmp), Token Burned per-turn block, goal hierarchy.
- V3 phase 1 complete: memory-system/ folder split. Dynamic Next Step queue. Unified router system. Per-file health scoring in ml status.
- V3 phase 2 (partial): per-turn behavioral contracts shipped — load announcement contract, memory candidate scan checklist, index-driven retrieval check. `test-per-turn.sh` shipped (61 tests, all passing). Router.md simplified — announcement format owned by per-turn.md.
- V3 phase 2 (session 9): commands restructured into memory-system/commands/ (8 per-command files). prompts/ deleted. Router updated. Routing rules consolidated. boot.md fixed. All renamed m-* → ml *. 94 tests passing.
- V3 phase 2 (session 10): ml onboard three-phase flow shipped — adapter conflict migration, inline memory extraction, project context population. Boot/router integration complete (step 10, precise trigger condition). test-onboard.sh shipped (25 tests, all passing). tools/test.sh now runs 7 suites.
- V3 phase 2 (remaining): memory diff — surface what changed in memory since the last session.
- V3 phase 3: auto-summarization suggestions when entries exceed size thresholds.
- V3 phase 4: programmatic index-first retrieval with scored ranking.

### When to use
Use when orienting to the current project phase or deciding what to work on next.

### Related
ml-20260430-005
ml-20260505-003
