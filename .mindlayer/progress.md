# Progress

## Current Phase

id: ml-20260505-006
created: 2026-05-05
updated: 2026-05-10 (session 16)
scope: project
type: progress
tags: [v3, memory-quality, retrieval, per-turn, contracts, commands, onboard]
confidence: high
status: active
source: manual

### Summary
V3 phase 4 complete as agent-executed ranked-load contract. Programmatic command runner moved to V4 foundation. 10 test suites, 243 checks passing.

### Details
- V1 complete: installer, prompt commands, thin adapters, boot/continuity contracts.
- V2 complete: proactive behavior, archive mode, ml session, subdirectories (private/sessions/cache/tmp), Token Burned per-turn block, goal hierarchy.
- V3 phase 1 complete: memory-system/ folder split. Dynamic Next Step queue. Unified router system. Per-file health scoring in ml status.
- V3 phase 2 (partial): per-turn behavioral contracts shipped — load announcement contract, memory candidate scan checklist, index-driven retrieval check. `test-per-turn.sh` shipped (61 tests, all passing). Router.md simplified — announcement format owned by per-turn.md.
- V3 phase 2 (session 9): commands restructured into memory-system/commands/ (8 per-command files). prompts/ deleted. Router updated. Routing rules consolidated. boot.md fixed. All renamed m-* → ml *. 94 tests passing.
- V3 phase 2 (session 10): ml onboard three-phase flow shipped — adapter conflict migration, inline memory extraction, project context population. Boot/router integration complete (step 10, precise trigger condition). test-onboard.sh shipped (25 tests, all passing). tools/test.sh now runs 7 suites.
- V3 phase 2 (session 11): memory diff shipped — surfaces new/updated/archived entries since last session at boot and ml status. diff.md spec in memory-system/commands/ (live + global-template). Boot step 11 added. Router, status.md, commands/index.md updated. test-diff.sh shipped (22 tests, all passing). tools/test.sh now runs 8 suites, 213 checks.
- V3 phase 3 (session 12): auto-summarization suggestions shipped — post-write size checks in per-turn.md, detailed cleanup suggestions in status.md, live/global-template sync, test-autosummarize.sh added (16 checks). tools/test.sh now runs 9 suites, 229 checks.
- V3 phase 4 (session 13): `ml load` primary command shipped — `ml retrieve` alias retained, command spec renamed to load.md, ranked-load behavior specified, archive handling specified, test-load.sh added (14 contract checks). This is a contract/spec and naming change, not a programmatic ranking engine.
- V3 phase 4 scope decision (session 15): programmatic ranked loader moved to V4 command-runner foundation. V3 remains markdown-first and agent-executed.
- Dogfood refactor (session 16, 2026-05-10): `dogfood-codex-boot.sh` replaced with agent-agnostic two-script architecture. `dogfood-boot.sh` (product gate, full isolation, API key) + `dogfood-live.sh` (personal health check, OAuth). Five real multi-turn scenarios verified passing with Claude runner. Root cause of boot receipt failure found and fixed in `install.sh` AGENTS.md template and `global-template/boot.md` — ambiguous boot trigger wording. Test fixtures added in `tools/dogfood-fixtures/`. Open source security hardening roadmap item saved (`ml-20260510-001`).
- V4 next: standardized `ml` command runner foundation, then `ml script` command and IDE extensions.

### When to use
Use when orienting to the current project phase or deciding what to work on next.

### Related
ml-20260430-005
ml-20260505-003
