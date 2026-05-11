# Project Memory Index

## Entries

- id: ml-project-20260430-001
  title: MindLayer Project Identity
  file: project.md
  section: MindLayer Project Identity
  scope: project
  type: context
  tags: [mindlayer, markdown, memory]
  summary: MindLayer is a markdown-first installable memory system for AI-native developers.
  importance: high
  status: active
  last_updated: 2026-04-30

- id: ml-20260430-002
  title: Installer-First V1 Seed
  file: archive.md
  section: Installer-First V1 Seed
  scope: project
  type: progress
  tags: [v1, installer]
  summary: V1 seed is validated; automatic initialization and session continuity contracts now pass install, boot, and continuity tests.
  importance: high
  status: archived
  last_updated: 2026-05-05

- id: ml-20260430-003
  title: V1 Memory Architecture Decisions
  file: archive.md
  section: V1 Memory Architecture Decisions
  scope: project
  type: decision
  tags: [architecture, installer, adapters]
  summary: Markdown memory, global/project layers, strict source boundaries, thin adapters, non-destructive install, fail-fast errors, and scaffold-skipping boot behavior.
  importance: high
  status: archived
  last_updated: 2026-05-02

- id: ml-20260503-001
  title: MindLayer Source-of-Truth Boundaries
  file: decisions.md
  section: MindLayer Source-of-Truth Boundaries
  scope: project
  type: decision
  tags: [source-of-truth, templates, memory-routing]
  summary: In the MindLayer repo, project `.mindlayer/` is product memory, `global-template` ships default global behavior, project templates stay generic, and live `~/.mindlayer/` is runtime/test output.
  importance: high
  status: active
  last_updated: 2026-05-03

- id: ml-20260503-002
  title: Literal Approval for Memory Writes
  file: decisions.md
  section: Literal Approval for Memory Writes
  scope: project
  type: decision
  tags: [approval, memory-safety, commands]
  summary: Memory writes require exact destination/content proposal and clear approval; acknowledgments like `ok` are not approval.
  importance: high
  status: active
  last_updated: 2026-05-03

- id: ml-20260504-001
  title: MindLayer Handoff Display Boundaries
  file: archive.md
  section: MindLayer Handoff Display Boundaries
  scope: project
  type: decision
  tags: [session-continuity, handoff, status, ux]
  summary: MindLayer Handoff is a checkpoint/status artifact shown at task end, status requests, pause/block/handoff, or recovery — not after every command.
  importance: low
  status: archived
  last_updated: 2026-05-05

- id: ml-20260505-008
  title: Pre-Push Gate
  file: decisions.md
  section: Pre-Push Gate
  scope: project
  type: decision
  tags: [pre-push, testing, quality-gate, proactive]
  summary: Before every push, agent appends a one-line test confirmation — 'yes' or 'skip' both proceed immediately.
  importance: high
  status: active
  last_updated: 2026-05-05

- id: ml-20260505-007
  title: Lateral Intent Routing
  file: decisions.md
  section: Lateral Intent Routing
  scope: project
  type: decision
  tags: [lateral-intent, routing, backlog, roadmap, proactive]
  summary: When user introduces out-of-plan work, agent silently classifies it and appends a one-line non-blocking nudge (backlog candidate / roadmap amendment / ad-hoc) before proceeding.
  importance: high
  status: active
  last_updated: 2026-05-05

- id: ml-20260505-005
  title: Token Burned Per-Turn Status Block
  file: decisions.md
  section: Token Burned Per-Turn Status Block
  scope: project
  type: decision
  tags: [session-continuity, per-turn, next-step, token-tracking, handoff, goal-hierarchy]
  summary: Handoff deprecated. Every agent turn ends with Token Burned block. Next Step navigates goal hierarchy (task → backlog → roadmap → brainstorm). Backlog-empty triggers proactive roadmap phase pull proposal.
  importance: high
  status: active
  last_updated: 2026-05-05

- id: ml-20260430-004
  title: Product Design Philosophy
  file: context.md
  section: Product Design Philosophy
  scope: project
  type: context
  tags: [design, tokens, memory-quality, writing]
  summary: Token efficiency is the primary constraint; memory is curation not a chat dump; scaffold files must not be loaded as real memory.
  importance: high
  status: active
  last_updated: 2026-05-05

- id: ml-20260506-001
  title: Memory System Self-Reference Problem
  file: archive.md
  section: Memory System Self-Reference Problem
  scope: project
  type: context
  tags: [memory-system, token-efficiency, architecture, v3]
  summary: Resolved. memory-system/ folder split shipped in V3 phase 1 — boot cost reduced from ~3,500 to ~1,200 tokens typical.
  importance: low
  status: archived
  last_updated: 2026-05-07

- id: ml-20260505-004
  title: Goal Hierarchy and Flow
  file: context.md
  section: Goal Hierarchy and Flow
  scope: project
  type: context
  tags: [goal-hierarchy, roadmap, backlog, next-step, flow, token-burned]
  summary: Product goal flow from project identity → roadmap → backlog → progress → sessions → per-turn Next Step, with Mermaid flow diagram and backlog-empty/roadmap-complete rules.
  importance: high
  status: active
  last_updated: 2026-05-05

- id: ml-20260430-006
  title: V1 Trust and Quality Risks
  file: risks.md
  section: V1 Trust and Quality Risks
  scope: project
  type: risk
  tags: [trust, tokens, installer, onboarding]
  summary: Token bloat, wrong routing, installer safety, scaffold false confidence, adapter drift, undiscoverable memory, onboarding gap, and silent behavior change on reinstall.
  importance: high
  status: active
  last_updated: 2026-05-05

- id: ml-20260430-005
  title: Future Roadmap
  file: backlog.md
  section: Future Roadmap
  scope: project
  type: backlog
  tags: [roadmap]
  summary: V2 complete. V3 phases 1–4 complete as markdown-first, agent-executed behavior. V4 command runner foundation is next. See ROADMAP.md for full vision.
  importance: medium
  status: active
  last_updated: 2026-05-07

- id: ml-20260505-006
  title: Current Phase — V3 Memory Quality + Smarter Retrieval
  file: progress.md
  section: Current Phase
  scope: project
  type: progress
  tags: [v3, memory-quality, retrieval, per-turn, contracts, commands, onboard]
  summary: V3 phase 4 complete as agent-executed ranked-load contract. Programmatic command runner/ranked loader moved to V4 foundation. 10 test suites, 243 checks passing.
  importance: high
  status: active
  last_updated: 2026-05-07

- id: ml-20260505-003
  title: MindLayer Product Roadmap
  file: roadmap.md
  section: MindLayer Product Roadmap
  scope: project
  type: roadmap
  tags: [roadmap, v2, v3, v4, script, cli]
  summary: V1, V2, and V3 shipped. V4 targets a SCRIPT product engine and lifecycle runtime first: Signal routing, Roadmap → Backlog → Agent Stories → Progress artifact queue, Transfer to Learning/History paths, then IDE integrations.
  importance: medium
  status: active
  last_updated: 2026-05-08

- id: ml-20260506-002
  title: Project Router
  file: router.md
  section: Project Router
  scope: project
  type: decision
  tags: [router, auto-load, triggers, memory-routing, v3]
  summary: Project-level router defining conditional load triggers for decisions, context, risks, roadmap, and sessions. Loads automatically at boot after global router.
  importance: high
  status: active
  last_updated: 2026-05-06

- id: ml-20260507-007
  title: Global-Template Sync Rule
  file: decisions.md
  section: Global-Template Sync Rule
  scope: project
  type: decision
  tags: [global-template, sync, installer, per-turn, memory-system]
  summary: When ~/.mindlayer/memory-system/ is updated, global-template/memory-system/ must be synced in the same session. Divergence means new users install older behavior silently. Sync checklist defined.
  importance: high
  status: active
  last_updated: 2026-05-07

- id: ml-20260507-006
  title: Per-Turn Behavioral Contract Compliance Risk
  file: risks.md
  section: Per-Turn Behavioral Contract Compliance
  scope: project
  type: risk
  tags: [per-turn, enforcement, agent-behavior, load-announcement, memory-candidate, retrieval, trust]
  summary: Load announcement, memory candidate surfacing, and retrieval suggestions are instruction-based not runtime-enforced. Silent failures possible. Mitigated by per-turn.md contract rules and 61-test test-per-turn.sh suite. Future fix via /m-script (V4).
  importance: high
  status: active
  last_updated: 2026-05-07

- id: ml-20260507-003
  title: Router Enforcement Gap
  file: risks.md
  section: Router Enforcement Gap
  scope: project
  type: risk
  tags: [router, enforcement, agent-behavior, trust, skills]
  summary: The MindLayer router is a memory document, not an execution engine. All trigger rules are soft contracts — the agent decides whether to fire them. No runtime process enforces them. Current mitigations are best-effort. Hard enforcement planned via /m-script command runner in V4.
  importance: high
  status: active
  last_updated: 2026-05-07

- id: ml-20260507-005
  title: ML-999 Backlog Evaluation Decisions
  file: decisions.md
  section: ML-999 Backlog Evaluation Decisions
  scope: project
  type: decision
  tags: [backlog, roadmap, ml-999, prioritization, v3, v4]
  summary: ML-101–110 evaluation (2026-05-07). Rejected ML-104/105/106/107/109/110. Deferred ML-103/108. Activated ML-101 partial (ranked retrieval, after V3 diff). Pulled ml onboard into V3 active. Do not re-litigate without new evidence.
  importance: high
  status: active
  last_updated: 2026-05-07

- id: ml-20260507-010
  title: ml onboard Three-Phase Migration Flow
  file: archive.md
  section: ml onboard Three-Phase Migration Flow
  scope: project
  type: decision
  tags: [onboard, migration, adapters, ml-save, conflict-detection]
  summary: ml onboard runs three phases — adapter conflict migration, inline memory extraction, project context population. Agent reads and reasons per file (like ml save). One proposal per turn, explicit approval. Phase 1 covers project + global adapters including ~/.claude/CLAUDE.md.
  importance: high
  status: archived
  last_updated: 2026-05-07

- id: ml-20260507-009
  title: ml onboard One-Time Flag via Index Entry
  file: archive.md
  section: ml onboard One-Time Flag via Index Entry
  scope: project
  type: decision
  tags: [onboard, ml-onboard, flag, index, architecture]
  summary: ml onboard completion flagged by index entry id:ml-onboard-complete. Boot checks for this entry and skips onboard if present. Chosen over a separate flag file — reuses existing infrastructure, no new file needed.
  importance: high
  status: archived
  last_updated: 2026-05-07

- id: ml-20260507-008
  title: Commands Subfolder Architecture
  file: archive.md
  section: Commands Subfolder Architecture
  scope: project
  type: decision
  tags: [commands, architecture, token-efficiency, prompts, memory-system]
  summary: All ml command specs live in memory-system/commands/ as per-command files loaded conditionally by router. prompts/ deleted. Each spec loads only when its command fires (~90 tokens vs ~1,200). Router is the index for memory-system files.
  importance: high
  status: archived
  last_updated: 2026-05-07

- id: ml-20260510-002
  title: Dogfood Two-Script Architecture
  file: decisions.md
  section: Dogfood Two-Script Architecture
  scope: project
  type: decision
  tags: [dogfood, testing, ci, open-source, architecture]
  summary: dogfood-boot.sh is the product gate (full isolation, API key); dogfood-live.sh is the personal health check (real HOME, OAuth). Docker rejected. Runners in tools/dogfood-runners/.
  importance: high
  status: active
  last_updated: 2026-05-10

- id: ml-20260510-003
  title: AGENTS.md Boot Trigger Root Cause
  file: decisions.md
  section: AGENTS.md Boot Trigger Root Cause
  scope: project
  type: decision
  tags: [agents-md, boot, non-interactive, adapter, install]
  summary: In -p mode agents skip boot unless AGENTS.md says boot BEFORE answering with no permission ask. Fixed in install.sh template and global-template/boot.md.
  importance: high
  status: active
  last_updated: 2026-05-10

- id: ml-20260510-004
  title: Open Source Security Hardening Decision
  file: decisions.md
  section: Open Source Security Hardening Decision
  scope: project
  type: decision
  tags: [security, open-source, governance, supply-chain]
  summary: Security belongs at distribution layer (CODEOWNERS, signed releases) not dogfood layer. Docker rejected. Three threat vectors each with distinct mitigation.
  importance: high
  status: active
  last_updated: 2026-05-10

- id: ml-20260507-004
  title: Agent-Agnostic Design Principle
  file: decisions.md
  section: Agent-Agnostic Design Principle
  scope: project
  type: decision
  tags: [architecture, agent-agnostic, adapters, design]
  summary: MindLayer works across any LLM tool. No rule, feature, or mitigation should be tool-specific unless it is explicitly a thin adapter. Correct violations immediately.
  importance: high
  status: active
  last_updated: 2026-05-07

- id: ml-20260507-002
  title: Skill Approval Gate
  file: decisions.md
  section: Skill Approval Gate
  scope: project
  type: decision
  tags: [approval, skills, ml-init, adapter-safety, memory-safety]
  summary: Skills and slash commands that write files must not execute autonomously in MindLayer. Agent must explain and wait for approval. MindLayer product memory belongs in ~/.mindlayer/ or .mindlayer/, never in Claude's own memory system.
  importance: high
  status: active
  last_updated: 2026-05-07

- id: ml-20260507-011
  title: Memory Diff Design Decisions
  file: archive.md
  section: Memory Diff Design Decisions
  scope: project
  type: decision
  tags: [memory-diff, boot, status, git, session-continuity, v3]
  summary: Memory diff uses git SHA from latest session file as baseline, parses entry-level changes (new/updated/archived), outputs counts + file names grouped by category, fires at boot (step 11) and ml status, skips silently on fallback.
  importance: high
  status: archived
  last_updated: 2026-05-07

- id: ml-20260507-012
  title: ml load Primary Command and Ranked Loading
  file: archive.md
  section: ml load Primary Command and Ranked Loading
  scope: project
  type: decision
  tags: [ml-load, retrieval, commands, ranking, v3]
  summary: ml load is the primary memory-loading command; ml retrieve remains an alias. Ranked loading uses deterministic index scoring by title, tags, summary, type/status, importance, recency, and archive intent. No ML or new storage.
  importance: high
  status: archived
  last_updated: 2026-05-07

- id: ml-20260507-001
  title: SCRIPT Development Philosophy
  file: context.md
  section: SCRIPT Development Philosophy
  scope: project
  type: context
  tags: [script, philosophy, development-cycle, agile, v4, users]
  summary: Six-step human+AI development cycle — Signal, Cut, Refine, Implement, Prove, Transfer. Wraps Agile, adds pre-backlog validation and persistent memory transfer. Full definition in ROADMAP.md. Planned /m-script command in V4.
  importance: high
  status: active
  last_updated: 2026-05-07

- id: ml-20260508-001
  title: Instruction-Only Architecture Ceiling
  file: risks.md
  section: Instruction-Only Architecture Ceiling
  scope: project
  type: risk
  tags: [architecture, v4, command-runner, enforcement, markdown, runtime]
  summary: MindLayer has reached the ceiling of instruction-only contracts. V4 should prioritize a deterministic local ml command runner while keeping markdown as durable memory storage.
  importance: high
  status: active
  last_updated: 2026-05-08

- id: ml-20260508-002
  title: SCRIPT Product Engine Architecture
  file: decisions.md
  section: SCRIPT Product Engine Architecture
  scope: project
  type: decision
  tags: [script, v4, product-engine, lifecycle, roadmap, backlog, agent-stories, transfer]
  summary: V4 reframes MindLayer as a SCRIPT product engine. Signal is universal ingress; Roadmap → Backlog → Agent Stories → Progress is the artifact queue; Transfer splits into Learning Path and History Path.
  importance: high
  status: active
  last_updated: 2026-05-08

- id: ml-20260511-001
  title: Adapter Boot Wording Drift
  file: risks.md
  section: Adapter Boot Wording Drift
  scope: project
  type: risk
  tags: [adapters, boot, non-interactive, trust, drift]
  summary: Resolved — hard boot wording locked in adapter templates and enforced by lint and install tests.
  importance: high
  status: archived
  last_updated: 2026-05-11

- id: ml-20260511-002
  title: Adapter Freeze + Auto-Detection Architecture
  file: decisions.md
  section: Adapter Freeze + Auto-Detection Architecture
  scope: project
  type: decision
  tags: [adapters, freeze, auto-detection, install, canonical]
  summary: All adapters are frozen whole-file canonical templates. Install auto-detects tools. User content never lost — routed via ml save before restore. adapters.lock is the authority.
  importance: high
  status: active
  last_updated: 2026-05-11
