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
  file: progress.md
  section: Installer-First V1 Seed
  scope: project
  type: progress
  tags: [v1, installer]
  summary: V1 seed is validated; automatic initialization and session continuity contracts now pass install, boot, and continuity tests.
  importance: high
  status: active
  last_updated: 2026-05-04

- id: ml-20260430-003
  title: V1 Memory Architecture Decisions
  file: decisions.md
  section: V1 Memory Architecture Decisions
  scope: project
  type: decision
  tags: [architecture, installer, adapters]
  summary: Markdown memory, global/project layers, strict source boundaries, thin adapters, non-destructive install, fail-fast errors, and scaffold-skipping /m-init behavior.
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
  summary: Memory writes require exact destination/content proposal and clear approval such as `approve` or `go ahead`; acknowledgments like `ok` are not approval.
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
  summary: MindLayer Handoff is a checkpoint/status artifact shown at task end, explicit status/next-step requests, pause/block/handoff, or recovery; routine progress updates stay plain and concise.
  importance: high
  status: active
  last_updated: 2026-05-04

- id: ml-20260430-005
  title: Future Roadmap
  file: backlog.md
  section: Future Roadmap
  scope: project
  type: backlog
  tags: [roadmap]
  summary: CLI, archive mode, and /m-session command are concrete V2 items.
  importance: medium
  status: active
  last_updated: 2026-05-05

- id: ml-20260505-002
  title: Product Design Principles
  file: decisions.md
  section: Product Design Principles
  scope: project
  type: decision
  tags: [design, tokens, memory-quality]
  summary: Token efficiency is the primary constraint; memory must be curated, indexed, and written for AI retrieval — not a chat dump.
  importance: high
  status: active
  last_updated: 2026-05-05

