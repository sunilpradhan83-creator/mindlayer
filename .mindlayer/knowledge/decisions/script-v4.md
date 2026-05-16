# SCRIPT V4 Decisions
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
