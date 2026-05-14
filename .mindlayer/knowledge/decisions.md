# Decisions

## V4 Phase 0 Boot Compression Architecture

id: ml-20260512-001
created: 2026-05-12
updated: 2026-05-12
scope: project
type: decision
tags: [v4, boot, compression, per-turn, index, progress, backlog]
confidence: high
status: active
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
ml-20260507-007

## Adapter Freeze + Auto-Detection Architecture

id: ml-20260511-002
created: 2026-05-11
updated: 2026-05-11
scope: project
type: decision
tags: [adapters, freeze, auto-detection, install, canonical]
confidence: high
status: active
source: conversation

### Summary
All adapter files are frozen whole-file canonical templates. Install auto-detects tools via system signals and existing project files. User content is never lost — routed via `ml save` before restore.

### Details
- No delimiters (`<!-- mindlayer:start/end -->`) in any adapter — whole file is the contract.
- Canonical templates live in `global-template/memory-system/templates/` (repo) and `~/.mindlayer/memory-system/templates/` (installed). Never manually edited.
- `adapters.lock` in project `.mindlayer/` stores SHA-256 hash of each installed adapter. Authority on what MindLayer last wrote.
- Install detects tools via `which <tool>` and `~/.tool/` directory signals plus existing project adapter files.
- Existing project files with user content are never overwritten silently — diffed against canonical, extra content routed via `ml save` flow, then restored.
- `update_marked_block` removed entirely. All adapters use `install_canonical_adapter`.

### When to use
Use when adding a new tool adapter, debugging install behavior, or understanding why an adapter was or was not written.

### Related
ml-20260511-001
ml-20260510-002

## Dogfood Two-Script Architecture

id: ml-20260510-002
created: 2026-05-10
updated: 2026-05-10
scope: project
type: decision
tags: [dogfood, testing, ci, open-source, security, architecture]
confidence: high
status: active
source: manual

### Summary
MindLayer dogfood testing uses two separate scripts with distinct purposes: `dogfood-boot.sh` (product gate, full isolation, API key) and `dogfood-live.sh` (personal health check, real HOME, OAuth).

### Details
- `tools/dogfood-boot.sh` — full HOME isolation + `ANTHROPIC_API_KEY`. Tests exactly what `install.sh` ships. Reproducible on any machine. CI-safe. Required before releases and on PRs touching `global-template/`.
- `tools/dogfood-live.sh` — real HOME + OAuth. Tests the contributor's actual live `~/.mindlayer/` config. Zero setup. Personal sanity check, not a product gate.
- Separation is correct because: (a) the product gate must test what ships, not personal config, (b) the live check needs zero friction for daily use.
- Docker was evaluated and rejected — security investment belongs at distribution layer (CODEOWNERS, signed releases), not dogfood layer. Docker would be security theater here.
- Runners live in `tools/dogfood-runners/`: `claude.sh` (isolated), `claude-live.sh` (live), `codex.sh` (Codex, single-turn only).

### When to use
Load when planning dogfood strategy, adding new agent runners, or evaluating CI integration.

---

## AGENTS.md Boot Trigger Root Cause

id: ml-20260510-003
created: 2026-05-10
updated: 2026-05-10
scope: project
type: decision
tags: [agents-md, boot, non-interactive, adapter, install]
confidence: high
status: active
source: manual

### Summary
In non-interactive (`-p`) mode, agents skip tool calls needed for boot unless `AGENTS.md` explicitly says to boot BEFORE answering. Ambiguous wording causes agents to answer directly from adapter files without running the boot sequence.

### Details
- Root cause: `AGENTS.md` said "run boot before answering the first project-relevant request" — agents interpreted this as optional or deferrable, and answered from `CLAUDE.md`/`AGENTS.md` context directly.
- Fix: added "Never answer a project question without booting first. Never ask the user if they want you to boot — just boot." to both `install.sh` (AGENTS.md template) and `global-template/boot.md`.
- Key insight: "boot before answering" is ambiguous. "boot BEFORE, then answer, never ask permission" is not.
- Applies to all agents in non-interactive/headless mode — not Claude-specific.
- Test fixtures in `tools/dogfood-fixtures/` give the sandbox project real identity (non-scaffold `project.md`, `index.md` with `ml-onboard-complete`) so the agent boots confidently without triggering the onboard flow.

### When to use
Load when modifying AGENTS.md boot instructions, debugging boot receipt failures, or adding new agent runners.

---

## Open Source Security Hardening Decision

id: ml-20260510-004
created: 2026-05-10
updated: 2026-05-10
scope: project
type: decision
tags: [security, open-source, governance, supply-chain]
confidence: high
status: active
source: manual

### Summary
Security investment for open source MindLayer belongs at the distribution and governance layer, not the dogfood test layer. Three distinct threat vectors, each with its own mitigation.

### Details
- Threat 1 (malicious contributor): CODEOWNERS on `global-template/` + branch protection. Code review is the control — markdown is human-readable, malicious instructions are visible in PR diffs.
- Threat 2 (supply chain): signed releases + published checksums for `install.sh`.
- Threat 3 (developer running unreviewed local changes): document in CONTRIBUTING.md. Self-inflicted risk, not a tooling problem.
- Docker in dogfood was explicitly rejected — it protects the wrong layer and adds contributor friction without meaningful security benefit.
- Full details in `roadmap.md` entry `ml-20260510-001`.

### When to use
Load when planning the open source release, evaluating security PRs, or onboarding security contributors.

---

## Global-Template Sync Rule
id: ml-20260507-007
created: 2026-05-07
updated: 2026-05-07
scope: project
type: decision
tags: [global-template, sync, installer, per-turn, memory-system]
confidence: high
status: active
source: manual
### Summary
When any file in `~/.mindlayer/memory-system/` is updated, `global-template/memory-system/` must be synced in the same session. New users only receive what ships in global-template.
### Details
- Live `~/.mindlayer/memory-system/` is runtime output; `global-template/memory-system/` is what new users install.
- Divergence creates silent regressions for new installs.
- Any memory-system change must update live + global-template, run `tools/test.sh`, and commit both together.


## Agent-Agnostic Design Principle
id: ml-20260507-004
created: 2026-05-07
updated: 2026-05-07
scope: project
type: decision
tags: [architecture, agent-agnostic, adapters, design]
confidence: high
status: active
source: manual
### Summary
MindLayer is designed to work across any LLM tool — Claude, Codex, Cursor, Copilot, and any future agent. No feature, rule, or mitigation should be written as tool-specific unless it is explicitly a thin adapter for that tool.
### Details
- MindLayer is a control plane over agents, not a feature of one tool.
- Product rules, mitigations, and roadmap items must be agent-agnostic; tool-specific content belongs only in thin adapters.
- Correct accidental tool lock-in in memory, decisions, risks, or roadmap immediately.

## Agent-Agnostic Command Output Standard
id: ml-20260513-001
created: 2026-05-13
updated: 2026-05-13
scope: project
type: decision
tags: [agent-agnostic, commands, boot, output, runtime]
confidence: high
status: active
source: dogfood
### Summary
MindLayer command outputs, especially `ml boot`, must be standardized across Claude, Codex, Cursor, Copilot, and future agents.
### Details
- The local `ml` runtime is the authoritative output surface for command receipts and schemas.
- Agents should relay or execute runtime output without transforming it into tool-specific narration, repo analysis, skill initialization, or adapter rewrites.
- `ml boot` must emit the same receipt schema everywhere and must not trigger `init` skills or writes to tool adapters.
- Tool-specific adapters remain bootstraps only; product facts and command behavior belong in `.mindlayer/`, shipped templates, command specs, or runtime code.
### When to use
Use when changing command output schemas, boot behavior, dogfood runners, adapter behavior, or cross-agent UX.
### Related
ml-20260507-004
ml-20260511-002
ml-20260507-002
ml-20260508-001


## ML-999 Backlog Evaluation Decisions
id: ml-20260507-005
created: 2026-05-07
updated: 2026-05-07
scope: project
type: decision
tags: [backlog, roadmap, ml-999, prioritization, v3, v4]
confidence: high
status: active
source: manual
### Summary
Backlog evaluation (ML-999, 2026-05-07) produced activation, defer, and reject decisions for ML-101 through ML-110. These decisions should not be re-litigated without new evidence.
### Details
- Rejected: ML-104, ML-105, ML-106, ML-107, ML-109, ML-110 due to overlap, premature scope, or violating MindLayer's deterministic/agent-agnostic boundaries.
- Deferred: ML-103 and ML-108 until evidence shows adapter gaps or `Related:` fields are insufficient.
- Activated partial ML-101 as ranked retrieval/loading on top of the existing index; no ML or new storage.
- Pulled `ml onboard` into V3 because onboarding mature projects was the biggest adoption barrier.


## MindLayer Source-of-Truth Boundaries
id: ml-20260503-001
created: 2026-05-03
updated: 2026-05-03
scope: project
type: decision
tags: [source-of-truth, templates, memory-routing]
confidence: high
status: active
source: manual
### Summary
While working inside the MindLayer repo, product memory should be saved to project `.mindlayer/`, shipped global behavior should be implemented through `global-template`, and live `~/.mindlayer/` should not be manually edited.
### Details
- Repo `.mindlayer/` is product memory for MindLayer itself.
- Live `~/.mindlayer/` is runtime/install/test output, not product-memory source of truth.
- `project-template` is starter memory for future users; `global-template` ships default global behavior.
- Operational behavior changes must be reflected in templates/adapters/specs, not only saved as memory.


## Literal Approval for Memory Writes
id: ml-20260503-002
created: 2026-05-03
updated: 2026-05-03
scope: project
type: decision
tags: [approval, memory-safety, commands]
confidence: high
status: active
source: manual
### Summary
Memory writes require literal explicit approval before editing durable memory.
### Details
Acknowledgments like `ok`, `got it`, or `we need to save this` are not approval. The agent must propose exact destination/content and wait for clear approval (`approve`, `go ahead`, etc.) before editing durable memory or behavior templates.


## Skill Approval Gate
id: ml-20260507-002
created: 2026-05-07
updated: 2026-05-07
scope: project
type: decision
tags: [approval, skills, ml-init, adapter-safety, memory-safety]
confidence: high
status: active
source: manual
### Summary
Skills that write files (such as the `init` skill triggered by `ml init`) must not execute autonomously in the MindLayer repo. The agent must read the target file, explain what the skill would do, and wait for explicit approval before any write.
### Details
- Skills/slash commands that write files, including `ml init`-triggered adapter rewrites, require the same literal approval as memory writes.
- If a skill writes without approval, revert and explain. MindLayer product learnings belong in MindLayer memory, not tool-native memory.


## Lateral Intent Routing
id: ml-20260505-007
created: 2026-05-05
updated: 2026-05-05
scope: project
type: decision
tags: [lateral-intent, routing, backlog, roadmap, proactive]
confidence: high
status: active
source: manual
### Summary
When a user introduces work outside the current Next Step or backlog, the agent classifies it silently and appends a one-line non-blocking nudge before proceeding.
### Details
- Classify out-of-plan work as backlog candidate, roadmap amendment, or ad-hoc.
- Append at most one non-blocking nudge before Token Burned; do not fire during boot/status or direct Next Step/backlog-pull responses.
- Capture only on explicit user response; approval rules still apply.


## Token Burned Per-Turn Status Block
id: ml-20260505-005
created: 2026-05-05
updated: 2026-05-06
scope: project
type: decision
tags: [session-continuity, per-turn, next-step, token-tracking, handoff, goal-hierarchy, coming-up, priority]
confidence: high
status: active
source: manual
### Summary
Handoff is deprecated. Every agent turn ends with a Token Burned block. Next Step is always a single plain-text action. Optional Coming Up: surfaces for ambiguity or long queues. Priority hierarchy is strictly enforced.
### Details
- Every turn ends with Token Burned, Session estimate, and nonblank `Next Step`; optional `Coming Up` appears only for ambiguity or long queues.
- Next Step hierarchy: active task → commit uncommitted changes → next backlog item → next roadmap phase → brainstorm next major version.
- `Coming Up` lists only lower-priority follow-ups; uncommitted changes always outrank new backlog work.


## SCRIPT Product Engine Architecture
id: ml-20260508-002
created: 2026-05-08
updated: 2026-05-08
scope: project
type: decision
tags: [script, v4, product-engine, lifecycle, roadmap, backlog, agent-stories, transfer]
confidence: high
status: active
source: conversation
### Summary
V4 reframes MindLayer as a SCRIPT-driven product development engine, not just a memory helper. Signal is the universal ingress point; Roadmap → Backlog → Agent Stories → Progress is the artifact queue; Transfer splits into Learning Path and History Path.
### Details
- SCRIPT remains the process flow: Signal → Cut → Refine → Implement → Prove → Transfer.
- Signal is detected by the agent but remains pending until human-approved routing; no `signals.md` durable queue is planned for V4.
- Approved Signals route to roadmap for product/version direction, backlog for near-term work, Agent Stories when already refined, progress for active execution state, or learning memory when the content is durable knowledge only.
- Roadmap, backlog, Agent Stories, and progress are artifact buckets in a queue. Ideas should be promoted through the queue rather than duplicated across files.
- Refine produces one or more Agent Stories with human in the loop; Agent Stories replace durable user stories/tasks/actions as the post-planning work unit an agent can execute.
- Transfer has two paths: Learning Path (`.mindlayer/learnings/` typed files for project, decisions, context, risks) and History Path (`.mindlayer/history/` version archives plus archive index for completed or inactive flow artifacts).
- V4 should be spec-first, then implemented by a local Python `ml` runtime. IDE integrations come after the lifecycle runtime is stable.
- **SUPERSEDED by ml-20260514-001** — signals.md durable queue is now confirmed for V4; routing rules and file ownership defined.


## SCRIPT Lifecycle File Ownership and Rules

id: ml-20260514-001
created: 2026-05-14
updated: 2026-05-14
scope: project
type: decision
tags: [script, v4, lifecycle, signals, backlog, stories, archive, transfer, purge, file-ownership]
confidence: high
status: active
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
status: active
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
status: active
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
status: active
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
