# Archive

## Installer-First V1 Seed

id: ml-20260430-002
created: 2026-04-30
updated: 2026-05-05
scope: project
type: progress
tags: [v1, installer]
confidence: high
status: archived
source: manual

### Summary
Current phase: V1 polish complete. Installer, boot, continuity, and deploy-readiness contracts are all validated and passing.

### Details
- Completed: automatic session initialization and session continuity contracts implemented and validated across adapters, prompts, templates, and tests.
- Completed: V1 polish — fixed embedded memory-system fallback drift, aligned ml init phrasing, fixed Copilot adapter terminology, defined "starter-only" inline, removed perl dependency from tests, removed docs/ folder.
- Completed: `bash tools/test.sh` passes with `READY TO DEPLOY`, `BOOT CONTRACT READY`, and `CONTINUITY CONTRACT READY`.
- Next step: choose next track — simplify memory model for humans, start CLI planning, start VS Code extension planning, or explore product/SaaS direction.

### When to use
Historical reference for V1 completion state.

### Related
ml-project-20260430-001

## Memory System Self-Reference Problem

id: ml-20260506-001
created: 2026-05-06
updated: 2026-05-07
scope: project
type: context
tags: [memory-system, token-efficiency, architecture, v3]
confidence: high
status: archived
source: manual

### Summary
`memory-system.md` had a chicken-and-egg problem: rules for what to load were embedded inside the file that had to be fully loaded first (~3,500 tokens) just to learn what not to load. Fixed in V3 phase 1 by splitting into `memory-system/` folder with index-driven conditional loading (~1,200 tokens typical boot cost).

### When to use
Historical reference. Problem resolved — memory-system/ folder split shipped in V3 phase 1.

### Related
ml-20260505-006

## MindLayer Handoff Display Boundaries

id: ml-20260504-001
created: 2026-05-04
updated: 2026-05-05
scope: project
type: decision
tags: [session-continuity, handoff, status, ux]
confidence: high
status: archived
source: manual

### Summary
MindLayer Handoff is a checkpoint/status artifact, not a running commentary format. Deprecated; superseded by Token Burned Per-Turn Status Block (ml-20260505-005).

### Details
Show the structured MindLayer Handoff only at task end, when the user explicitly asks for status or next steps, when work is paused, blocked, or handed off, and after crash or session recovery.

Do not show it before every command, after every command, during routine progress updates, while exploring files, while tests are still running, or for every small subtask.

During normal conversation or active execution, keep the user oriented with plain concise text and a proactive next-step cue when useful.

Preferred compact handoff shape:

```text
Backlog item: <larger durable goal>
Task: <current concrete work>
  - Last result: <what just happened>
  - Next step: <smallest useful action>
  - Status: active | blocked | paused | completed

Context:
  - Task: ~<N> words, ~<N> est. tokens
  - Session: ~<N> words, ~<N> est. tokens
```

### When to use
Historical reference only. Superseded by Token Burned Per-Turn Status Block.

### Related
ml-20260505-005

## ml load Primary Command and Ranked Loading
id: ml-20260507-012
created: 2026-05-07
updated: 2026-05-07
scope: project
type: decision
tags: [ml-load, retrieval, commands, ranking, v3]
confidence: high
status: archived
source: manual
### Summary
`ml load <query>` is the primary memory-loading command. `ml retrieve <query>` remains a backward-compatible alias. V3 phase 4 ranked loading uses deterministic index scoring, not ML or new storage.
### Details
- Primary command is `ml load <query>`; `ml retrieve <query>` remains an alias.
- Spec moved to `commands/load.md`; ranked loading is deterministic over title/tags/summary/type/status/importance/recency/archive intent.
- No ML, embeddings, background indexer, or new storage layer in V3 phase 4.

## Memory Diff Design Decisions
id: ml-20260507-011
created: 2026-05-07
updated: 2026-05-07
scope: project
type: decision
tags: [memory-diff, boot, status, git, session-continuity, v3]
confidence: high
status: archived
source: manual
### Summary
Memory diff surfaces what changed in `.mindlayer/` since the last session — new entries, updated entries, archived entries — at boot and during `ml status`.
### Details
- Baseline is the git SHA from the latest dated session file's `## Commit` section.
- Diff project `.mindlayer/` only; exclude sessions/cache/tmp/private/local/archive.
- Output counts + file names for New / Updated / Archived entries; omit zero-count lines and omit the whole block when empty.
- Place in boot receipt after `Current progress:` and in `ml status` Context.
- Skip silently on missing session/SHA/git errors. Spec lives in `memory-system/commands/diff.md`.

## ml onboard Three-Phase Migration Flow
id: ml-20260507-010
created: 2026-05-07
updated: 2026-05-07
scope: project
type: decision
tags: [onboard, migration, adapters, ml-save, conflict-detection]
confidence: high
status: archived
source: manual
### Summary
`ml onboard` runs a three-phase migration flow: (1) adapter conflict detection and migration, (2) inline memory extraction, (3) project context population. Agent reads and reasons about each file — same as `ml save`. One proposal per turn, explicit approval required.
### Details
- Phase 1 scans project/global adapters for conflicts and proposes adapter edit + optional MindLayer write together.
- Phase 2 extracts durable non-conflict adapter content using `ml save` proposal rules; extraction does not remove adapter text.
- Phase 3 scans README/docs/source only for onboarding context and proposes one `.mindlayer/` entry at a time.
- Conflicts include contradictory boot instructions, inline memory stores, duplicate boot sequences, or adapter-as-memory instructions. Coding standards are not conflicts.
- Completion is recorded by index entry `ml-onboard-complete`, even on early stop.

## ml onboard One-Time Flag via Index Entry
id: ml-20260507-009
created: 2026-05-07
updated: 2026-05-07
scope: project
type: decision
tags: [onboard, ml-onboard, flag, index, architecture]
confidence: high
status: archived
source: manual
### Summary
`ml onboard` completion is flagged by writing a single entry to `.mindlayer/index.md` with `id: ml-onboard-complete, type: onboarding, status: complete`. On every subsequent boot, if this entry exists, skip `ml onboard` entirely.
### Details
- Completion uses index entry `ml-onboard-complete`, not a separate flag file, to avoid new install surface and keep the state discoverable.
- Boot checks `.mindlayer/index.md` for that id before firing `ml onboard`.

## Commands Subfolder Architecture
id: ml-20260507-008
created: 2026-05-07
updated: 2026-05-07
scope: project
type: decision
tags: [commands, architecture, token-efficiency, prompts, memory-system]
confidence: high
status: archived
source: manual
### Summary
All ml command specs live in `memory-system/commands/` as per-command files loaded conditionally by the router. The `prompts/` folder is deleted. Each spec loads only when its command fires (~90 tokens vs ~1,200 for all specs at once).
### Details
- `prompts/` deleted because router/boot never guaranteed those specs were loaded.
- Command specs live in `memory-system/commands/` with `commands/index.md` as dispatch map.
- Router owns trigger rules; `read-write.md` owns read/write safety only.
- `memory-system/session.md`, `global-template/index.md`, and `~/.mindlayer/index.md` were removed; `preferences/index.md` is the global catalog.

## V1 Memory Architecture Decisions
id: ml-20260430-003
created: 2026-04-30
updated: 2026-04-30
scope: project
type: decision
tags: [architecture, installer, adapters]
confidence: high
status: archived
source: manual
### Summary
MindLayer V1 uses markdown files, global and project memory layers, thin tool adapters, and strict source boundaries.
### Details
- Global memory lives in `~/.mindlayer/`; project memory lives in `.mindlayer/`.
- Adapters (`AGENTS.md`, `CLAUDE.md`, Copilot) are thin instructions, not durable memory stores.
- README/docs are human documentation, not default AI memory input.
- Installer is non-destructive: prefer symlink to global memory, pointer fallback if needed, never overwrite user files, fail fast on required write errors.
- `ml init` skips scaffold-only files and `local.md` by default. V1 intentionally excluded archive/cleanup.

## Completed Progress History — V1/V2/V3
id: ml-progress-archive-v1v2v3
created: 2026-05-12
updated: 2026-05-12
scope: project
type: progress
tags: [v1, v2, v3, dogfood, adapters, history]
confidence: high
status: archived
source: manual
### Summary
Completed phase history moved out of `progress.md` during V4 Phase 0 boot compression.
### Details
- V1 shipped installer, prompt commands, thin adapters, boot/continuity contracts.
- V2 shipped proactive behavior, archive mode, `ml session`, private/session/cache/tmp directories, Token Burned block, and goal hierarchy.
- V3 phase 1 shipped memory-system folder split, dynamic Next Step queue, unified router, and per-file health scoring.
- V3 phase 2 shipped per-turn behavioral contracts, command spec restructuring, `ml onboard`, and memory diff.
- V3 phase 3 shipped post-write size suggestions, status cleanup suggestions, global-template sync checks, and autosummarization tests.
- V3 phase 4 shipped `ml load` as primary command, deterministic ranked-load contract, archive handling, and test-load.sh.
- Dogfood refactor replaced `dogfood-codex-boot.sh` with `dogfood-boot.sh` and `dogfood-live.sh`.
- Dogfood fix review addressed validation false negatives, source-boundary checks, continuity skipping, and memory write hash snapshots.
- Adapter freeze made adapters delimiter-free whole-file canonical templates with adapter lock hashes and boot-time guard behavior.
- Strict Token Burned contract requires every host agent turn to include last-turn/session estimates and nonblank Next Step.
- Adapter consolidation froze all tool adapters, added auto-detection, fixed detection bugs, and removed marked-block updates.

## Completed Backlog History — V2/V3
id: ml-backlog-archive-v2v3
created: 2026-05-12
updated: 2026-05-12
scope: project
type: backlog
tags: [v2, v3, completed, history]
confidence: high
status: archived
source: manual
### Summary
Completed V2 and V3 backlog phase lists moved out of `backlog.md` during V4 Phase 0 boot compression.
### Details
- V2 phase 1 shipped proactive behavior, `ml session`, thinner adapters, and V2 roadmap reframing.
- V2 phase 2 shipped archive mode, stale criteria, archive/delete checkpoints, and `ml clean`.
- V2 phase 3 shipped private/session/cache/tmp directories plus lifecycle routing.
- V2 phase 4 shipped Token Burned per-turn status, Next Step hierarchy, and goal flow.
- V3 phase 1 shipped memory health scoring, dynamic Next Step queue, and memory-system folder split.
- V3 phase 2 shipped per-turn behavioral contracts, `ml onboard`, and memory diff.
- V3 phase 3 shipped size thresholds, post-write size suggestions, status cleanup suggestions, and autosummarization tests.
- V3 phase 4 shipped `ml load` as primary command and ranked-load/archive behavior contract tests.

## Adapter Boot Wording Drift
id: ml-20260511-001
created: 2026-05-11
updated: 2026-05-11
scope: project
type: risk
tags: [adapters, boot, non-interactive, trust, drift]
confidence: high
status: archived
source: conversation
### Summary
Shipped adapter wording may still be softer than the recorded non-interactive boot fix requires, allowing agents to answer project questions before running MindLayer boot.
### Details
- `AGENTS.md` currently says to run boot before answering the first project-relevant request, but the recorded root-cause fix requires harder wording: never answer a project question without booting first, never ask permission, just boot.
- This matters most in headless or non-interactive agent runs where ambiguous instructions can be treated as optional or deferrable.
- `CLAUDE.md` correctly delegates to `AGENTS.md`, so ambiguity in `AGENTS.md` propagates to tool-specific adapters.
- Recommended mitigation: tighten the adapter template wording and add a contract test that asserts the hard boot language is present in installed adapters.
### When to use
Use when editing adapter templates, debugging boot receipt failures, or adding tests for non-interactive agent behavior.
### Related
ml-20260510-003
ml-20260430-006
ml-20260507-003
