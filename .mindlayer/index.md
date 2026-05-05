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
  file: decisions.md
  section: V1 Memory Architecture Decisions
  scope: project
  type: decision
  tags: [architecture, installer, adapters]
  summary: Markdown memory, global/project layers, strict source boundaries, thin adapters, non-destructive install, fail-fast errors, and scaffold-skipping boot behavior.
  importance: high
  status: active
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
  file: decisions.md
  section: MindLayer Handoff Display Boundaries
  scope: project
  type: decision
  tags: [session-continuity, handoff, status, ux]
  summary: MindLayer Handoff is a checkpoint/status artifact shown at task end, status requests, pause/block/handoff, or recovery — not after every command.
  importance: low
  status: deprecated
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

- id: ml-20260505-004
  title: Goal Hierarchy and Flow
  file: context.md
  section: Goal Hierarchy and Flow
  scope: project
  type: context
  tags: [goal-hierarchy, roadmap, backlog, next-step, flow, token-burned]
  summary: Three-level goal hierarchy (roadmap → backlog → sessions) with Mermaid flow diagram and Next Step prediction rules. Defines backlog-empty and roadmap-complete behaviors.
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
  summary: V2 complete (phases 1–4). Up next: V3 Memory Quality + Smarter Retrieval (health scoring, memory diff, auto-summarization, ranked retrieval). See ROADMAP.md for full vision.
  importance: medium
  status: active
  last_updated: 2026-05-05

- id: ml-20260505-003
  title: MindLayer Product Roadmap
  file: roadmap.md
  section: MindLayer Product Roadmap
  scope: project
  type: roadmap
  tags: [roadmap, v2, cli]
  summary: V1 shipped. V2 targets CLI, archive mode, /m-session. Full vision in ROADMAP.md.
  importance: medium
  status: active
  last_updated: 2026-05-05
