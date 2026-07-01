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

## V4 Phase 0 Boot Compression Architecture

id: ml-20260512-001
created: 2026-05-12
updated: 2026-05-12
scope: project
type: decision
tags: [v4, boot, compression, per-turn, index, progress, backlog]
confidence: high
status: archived
source: implementation

### Summary
V4 Phase 0 compresses instruction-only boot weight by splitting per-turn behavior into lazy modules, loading a summary-only project index at boot, and archiving completed progress/backlog history.

### Details
- `memory-system/per-turn.md` is now the always-loaded core: Token Burned format and Next Step hierarchy only.
- Conditional per-turn contracts moved to `memory-system/per-turn/`: load announcements, memory candidates, retrieval suggestions, lateral intent, session warnings, and post-write size checks.
- Boot reads `.mindlayer/index.md` as a summary-only catalog; full metadata lives in `.mindlayer/index-full.md` and loads via `ml load`.
- `progress.md` keeps only current phase state; completed V1/V2/V3 progress history is archived as `ml-progress-archive-v1v2v3`.
- `backlog.md` keeps active/planned V4 and deferred work; completed V2/V3 backlog history is archived as `ml-backlog-archive-v2v3`.
- Track A targets roughly 3,900 boot tokens. Track B, the V4 command runner, is still required for the original roughly 1,200-token goal.

### When to use
Use when changing boot sequence, per-turn modules, index loading, progress/backlog compression, or planning V4 command-runner work.

### Related
ml-20260508-001
ml-20260508-002
ml-adr-0001
ml-20260507-007

## Global-Template Sync Rule
id: ml-20260507-007
created: 2026-05-07
updated: 2026-05-07
scope: project
type: decision
tags: [global-template, sync, installer, per-turn, memory-system]
confidence: high
status: archived
source: manual
### Summary
When any file in `~/.mindlayer/memory-system/` is updated, `global-template/memory-system/` must be synced in the same session. New users only receive what ships in global-template.
### Details
- Live `~/.mindlayer/memory-system/` is runtime output; `global-template/memory-system/` is what new users install.
- Divergence creates silent regressions for new installs.
- Any memory-system change must update live + global-template, run `tools/test.sh`, and commit both together.
- Superseded as target architecture by `ml-adr-0001`; retained as a transitional rule while the current installer still depends on global runtime markdown and global-template sync.

## SCRIPT Lifecycle File Ownership and Rules
id: ml-20260514-001
created: 2026-05-14
updated: 2026-05-14
scope: project
type: decision
tags: [script, v4, lifecycle, signals, backlog, stories, archive, transfer, purge, file-ownership]
confidence: high
status: archived
source: conversation
### Summary
Settled the full file ownership, lifecycle rules, purge triggers, and folder structure for the SCRIPT queue: Signal → Cut → Refine → Implement → Prove → Transfer.
### Details
**Universal ingress: everything is a Signal**
- Bugs, risks, design flaws, decisions, assumption corrections — all enter via `signals.md`
- Nothing bypasses Signal. `decisions.md`, `risks.md`, `context.md` are Transfer *outputs*, not ingress points.
**File ownership per stage:**
- Signal → `signals.md` (flat, append-only, lightweight)
- Cut → routes to `roadmap.md` (direction change) or `backlog.md` (default, execution queue)
- Refine → reads `backlog.md`, creates files in `stories/`
- Implement + Prove → `progress.md` (active execution state); git diff is the resume checkpoint
- Transfer → `decisions.md`, `risks.md`, `context.md` (Learning Path); `archive/` (History Path)
**Cut routing rules:**
- Default → backlog: bugs, fixes, improvements within current version direction
- Exception → roadmap: user direction decisions, design flaws breaking roadmap assumptions, version reprioritization. Rare. Always carries a reason. Agent proposes, human must confirm before roadmap is touched.
- Agent never touches roadmap unilaterally. If agent detects roadmap-level issue during Implement/Prove/Transfer, it stops and creates a new Signal.
**signals.md purge rules:**
- `cut-approved` → routed to roadmap: deleted from signals.md when that roadmap version ships
- `cut-approved` → routed to backlog: deleted from signals.md when all child stories ship
- `cut-killed` → stays until current roadmap version ships, then archived
**stories/ folder:**
- One file per story. Agent-agnostic, fully refined, atomic — smallest unit executable in one agent turn.
- `stories/index.md` — manifest: id | title | status | created. Agent reads this for "show pending stories."
- Story statuses: `ready → in-progress → done`
- Resume rule: uncommitted git diff exists → agent inspects and continues; clean git state → start from beginning.
- Hard rule: stories must be git-safe and re-runnable from clean state. Irreversible side effects (API calls, deploys) must be the last step of a story, never mid-story.
- Backlog item = parent. Story = child. Backlog item closes when all child stories reach `done`.
**archive/ folder:**
- Replaces flat `archive.md`. One file per archived artifact.
- `archive/index.md` — manifest: id | title | type | archived-date | reason.
**decisions.md / risks.md / context.md:**
- Stay flat files — read-often, written-rarely, token-efficient at boot.
- Purge trigger: superseded entries marked and moved to `archive/` at Transfer time.
- Hard cap: 20 entries max each. Transfer must archive oldest before writing new if cap hit.
**Folder structure:**
```
.mindlayer/
  signals.md
  roadmap.md
  backlog.md
  stories/
    index.md
    ml-story-NNN.md
  progress.md
  decisions.md
  context.md
  risks.md
  archive/
    index.md
    ml-archived-NNN.md
  sessions/
```
### Related
ml-20260508-002
ml-20260507-001

## SCRIPT V4 Final Structure, Story Schema, and Graphify Decision
id: ml-20260514-002
created: 2026-05-14
updated: 2026-05-14
scope: project
type: decision
tags: [script, v4, folder-structure, story-schema, graphify, tdd, pipeline, knowledge]
confidence: high
status: archived
source: conversation
### Summary
Finalized V4 repo structure, .mindlayer/ folder layout, story schema as executable agent prompt, TDD mandatory for all stories, and Graphify deferred to V5.
### Details
**Final .mindlayer/ structure — two folders only:**
```
.mindlayer/
  pipeline/              ← SCRIPT flow artifacts (emergent, grows with work)
    signals.md
    roadmap.md
    backlog.md
    progress.md
    stories/
      index.md           ← manifest: id | title | status | created | parent
      ml-story-NNN.md
    archive/
      index.md
      ml-archived-NNN.md
  knowledge/             ← permanent context + Transfer outputs (emergent)
    project.md
    principles.md
    goals.md
    decisions.md
    risks.md
    sessions/
  local.md
  adapters.lock
```
**Global ~/.mindlayer/ structure:**
```
~/.mindlayer/
  memory-system/         ← MindLayer OS, global only, never project-overridden
  knowledge/             ← user identity, preferences
  bin/
  lib/
  config.json
  adapters.lock
```
**Repo root:**
```
AGENTS.md / CLAUDE.md    ← adapter bootstrap pointers only
README.md                ← generated from .mindlayer/knowledge/project.md
ROADMAP.md               ← generated from .mindlayer/pipeline/roadmap.md
global-template/         ← ships to ~/.mindlayer/
project-template/        ← installed to .mindlayer/ on ml init/onboard
src/ tests/ tools/       ← ml runtime
```
**Folder naming rationale:**
- `pipeline/` — maps directly to SCRIPT, immediately clear
- `knowledge/` — permanent project brain, never purged unless wrong
- No `graph/` folder in V4 — Graphify deferred to V5
**Structure is emergent not static:**
- New project: ml init creates pipeline/ + local.md + adapters.lock only
- Existing project: ml onboard runs Graphify on whole repo, generates knowledge/ from graph output
- knowledge/ and pipeline/ subfolders appear only as SCRIPT generates them
**Retrieval strategy V4 — no Graphify:**
- pipeline/index.md + knowledge/index.md as lightweight manifests
- Agent reads manifest first, loads only relevant files
- Graphify becomes hard dependency at V5 (teams, SaaS, multi-project graph)
**memory-system/ is global only:**
- Never project-level override
- Project customization goes in knowledge/ as entries the memory-system reads
- Ensures consistent agent behavior across all projects
**Duplicate file elimination:**
- README.md generated from knowledge/project.md — not maintained separately
- ROADMAP.md generated from pipeline/roadmap.md — not maintained separately
- Agent reads .mindlayer/ only, never repo root duplicates
**Signal tiers:**
- auto — unambiguously within current version scope, agent routes without human confirmation
- review — roadmap-level or ambiguous, human must confirm before routing
- Agent assigns tier, human can override
- When in doubt agent picks review — safe direction of error
- Real protection is memory quality at boot, not tier system itself
**Story schema — story IS the prompt:**
- Story file = executable agent prompt, handed directly to agent
- Frontmatter: id, title, status, created, parent, agent
- Body: direct agent prompt — context, TDD instructions, acceptance criteria
- No sections to interpret — agent reads and executes immediately
- Agent-agnostic — paste file content into any agent, works
- TDD mandatory for all stories — instructions always start with writing failing tests
- Acceptance Criteria = all tests pass. No checklist, no self-certification.
- Human approves prompt before status flips to ready — Refine quality gate
**Story statuses:** ready → in-progress → done
**Resume rule:** uncommitted git diff → agent inspects and continues; clean state → start over
**Git-safe rule:** stories must be re-runnable from clean state; irreversible side effects last step only
**Story example:**
```markdown
---
id: ml-story-001
title: Create pipeline/ folder structure
status: ready
created: 2026-05-14
parent: ml-backlog-012
agent: any
---
You are implementing the pipeline/ folder structure for MindLayer V4.
Start by writing failing tests that verify:
- .mindlayer/pipeline/ exists
- .mindlayer/pipeline/signals.md exists with correct header
- .mindlayer/pipeline/stories/index.md exists
Then implement until all tests pass. Do not touch anything outside
.mindlayer/pipeline/. When done mark status: done in this file.
Acceptance: all tests pass. Nothing else.
```
**All stories are implementation stories:**
- Refine, Transfer, Research are SCRIPT stages — not story types
- They happen in conversation, not as story files
- Stories are only created at end of Refine when implementation is ready
- No story type field needed
### Related
ml-20260514-001
ml-20260514-003
ml-20260508-002
ml-20260507-001

## SCRIPT Transfer Rules and ml script CLI
id: ml-20260514-003
created: 2026-05-14
updated: 2026-05-14
scope: project
type: decision
tags: [script, v4, transfer, cli, ml-script, lifecycle, agent-executed]
confidence: high
status: archived
source: conversation
### Summary
Finalized Transfer rules and the `ml script` CLI namespace — the agent-executed determinism layer for the SCRIPT lifecycle.
### Details
**Transfer rules:**
- Trigger: last child story of a backlog item hits `done`.
- Agent asks one question: "What did we learn that future agents need to know?"
- Bar for proposing a Transfer write: "If I didn't write this, a future agent would make the same mistake or miss the same constraint." If no — skip Transfer.
- Three possible outcomes:
  - Nothing durable learned → no Transfer write, just archive stories + close backlog item
  - Lesson learned → `knowledge/decisions.md` or `knowledge/risks.md`
  - Project context shift → `knowledge/project.md` or `knowledge/goals.md`
- Agent proposes, human approves before any `knowledge/` write — same gate as every other write.
- At Transfer: all stories move to `pipeline/archive/`, backlog item closed in `pipeline/backlog.md`.
**ml script CLI — the SCRIPT lifecycle namespace:**
- Agent-executed, not human-executed. Human talks in natural language; agent translates intent into `ml script` commands.
- The CLI is the determinism boundary: fuzzy conversation above it, exact validated file operations below it.
- One namespace mirrors SCRIPT (one named thing, six stages). Sits alongside memory utilities (`ml save`, `ml load`, `ml clean`, `ml status`) as a separate clean family.
- `ml script --help` shows the whole lifecycle in one place.
Commands:
```
ml script signal "..."          ← create signal entry, agent-assigned tier
ml script cut <signal-id>       ← route signal (auto: routes; review: presents to human)
ml script refine <backlog-id>   ← scaffold story prompt files for human approval
ml script story <id> --start    ← ready → in-progress, update index
ml script story <id> --done     ← in-progress → done, update index, trigger Transfer check
ml script status                ← where we are in the flow
```
Rationale for single `ml script` namespace over flat verbs (`ml signal`, `ml story done`):
- Mirrors SCRIPT — lifecycle legible in every command
- Namespace clarity — `ml script *` is the engine; `ml save/load/clean/status` are memory utilities
- Discoverability — whole flow under one `--help`; V5 additions slot in cleanly
### Related
ml-20260514-001
ml-20260514-002
ml-20260514-004
ml-20260508-002

## SCRIPT V4 Review-Driven Refinements
id: ml-20260514-004
created: 2026-05-14
updated: 2026-05-14
scope: project
type: decision
tags: [script, v4, design-review, signal, resume, story-validation, refine, index-freshness, determinism]
confidence: high
status: archived
source: conversation
### Summary
An external design review of the SCRIPT V4 lifecycle (ml-20260514-001/002/003) returned a "design mostly holds" verdict plus five concrete fixes to apply before implementation. All five tighten the same principle the design rests on: the CLI is the determinism boundary — fuzzy human/agent conversation above it, exact validated file operations below it. This record captures the accepted refinements; it refines the three prior records, does not reverse them.
### Details
**1. Signal ingress rule reworded**
- From "Everything is a Signal" to "Every durable product-change input is a Signal."
- Taken literally the original turns normal interaction into queue spam.
- Bypass Cut entirely (NOT Signals): read-only retrieval ("what do we know about X?"), status/orientation queries, direct command ops (`ml load`, `ml status`, `ml clean`), session open/close mechanics, generated artifacts from already-approved work, ephemeral implementation observations resolved inside the same story that teach no future lesson.
- Preserves the single-provenance-trail principle without the noise.
**2. Resume mechanism — git status --porcelain + diff + runtime metadata**
- "Git diff as checkpoint" (ml-20260514-001/002) stays but is insufficient alone — misses untracked files, staged/unstaged distinction, and which story an in-progress diff belongs to.
- No `paused` status, no checkpoint/diary field — that becomes agent diary sludge.
- Add minimal runtime metadata to story frontmatter: `started_from` (start commit SHA); branch name optional.
- CLI resume reads `git status --porcelain`, not diff alone, and attributes work via the in-progress story's `started_from`.
**3. ml script refine --check — readiness validation gate**
- Story body stays freeform prompt. Readiness (`status: ready`) is gated by a deterministic linter-style CLI check PLUS human approval.
- Minimum validation: required frontmatter present; `parent` backlog id exists; status transition is legal; prompt starts with failing tests (TDD contract); allowed write scope is explicit; acceptance is test-based; no irreversible side effects or they are the last step only; no hidden dependency on one specific agent/tool.
**4. Refine approval granularity — single + batch only**
- Refine (not Cut or Transfer) is the likely scale bottleneck — it runs for every backlog item.
- V4 supports: approving a single story's prompt, or approving a generated story-set as a batch.
- V4 does NOT support template approval ("approve once, review deltas") — a reused template becomes a partially-unreviewed code path, the exact thing the determinism boundary exists to prevent. Revisit in V5 only if Refine demonstrably bottlenecks at real volume.
- Roadmap-level Cut stays human-confirmed — that friction is correct. Auto-tier signals route without blocking but surface in `ml script status`.
**5. Index freshness is a CLI responsibility**
- Graphify stays deferred to V5 — V4's main risk is behavioral determinism, not graph retrieval. Manifests hold until knowledge/ grows past ~20-30 durable entries or cross-project/team recall is needed.
- A stale manifest is worse than no manifest — it creates false confidence.
- Every `ml script` command that writes must update the relevant `index.md` atomically as part of the same operation.
**Consistency cleanup (note, not a blocker)**
- Older roadmap memory still references Transfer paths as `learnings/` and `history/`. The ml-20260514-* decisions settle on `knowledge/` and `pipeline/archive/`. Implementation follows the newer decisions; stale wording gets corrected during a future Transfer/archive pass.
### Related
ml-20260514-001
ml-20260514-002
ml-20260514-003
ml-20260508-001
