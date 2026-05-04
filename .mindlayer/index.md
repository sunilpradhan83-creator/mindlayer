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

- id: ml-20260430-004
  title: Memory as Intelligence Context
  file: context.md
  section: Memory as Intelligence Context
  scope: project
  type: context
  tags: [memory, retrieval, lifecycle]
  summary: Memory is curation, routing, retrieval, and lifecycle; initialization separates structural presence from semantic value and keeps AI context token-efficient inside MindLayer boundaries.
  importance: high
  status: active
  last_updated: 2026-05-02

- id: ml-20260503-003
  title: AI-Efficient Memory Language
  file: context.md
  section: AI-Efficient Memory Language
  scope: project
  type: context
  tags: [ai-context, tokens, writing]
  summary: MindLayer memory should use clear, compact language AI companions can understand with minimal ambiguity and token waste.
  importance: high
  status: active
  last_updated: 2026-05-03

- id: ml-20260430-005
  title: Future Roadmap
  file: backlog.md
  section: Future Roadmap
  scope: project
  type: backlog
  tags: [roadmap]
  summary: CLI, VS Code extension, archive mode, optional vector search, and product exploration are later.
  importance: medium
  status: active
  last_updated: 2026-04-30

- id: ml-20260430-006
  title: V1 Trust Risks
  file: risks.md
  section: V1 Trust Risks
  scope: project
  type: risk
  tags: [trust, tokens, installer]
  summary: Token bloat, scaffold false confidence, wrong routing, installer safety regressions, adapter drift, and undiscoverable memory are key risks.
  importance: high
  status: active
  last_updated: 2026-05-02

- id: ml-20260503-004
  title: Session Continuity Tracking
  file: backlog.md
  section: Session Continuity Tracking
  scope: project
  type: backlog
  tags: [session-continuity, approval, prompts]
  summary: Session continuity behavior is implemented for pending approvals, blockers, unfinished work, and next actions without noisy routine handoffs.
  importance: high
  status: archived
  last_updated: 2026-05-04

- id: ml-20260503-005
  title: Automatic Session Initialization
  file: backlog.md
  section: Automatic Session Initialization
  scope: project
  type: backlog
  tags: [init, onboarding, token-transparency]
  summary: Automatic session initialization is implemented and validated with loaded/skipped/missing sources, context cost/share, token strategy, and `/m-init` as manual refresh.
  importance: high
  status: archived
  last_updated: 2026-05-04

- id: ml-20260502-001
  title: Deploy Readiness Test Harness
  file: backlog.md
  section: Deploy Readiness Test Harness
  scope: project
  type: backlog
  tags: [testing, installer, deploy-readiness]
  summary: Add a sandboxed local readiness test suite that validates fresh and existing installs, edge cases, memory contracts, and deploy readiness.
  importance: high
  status: active
  last_updated: 2026-05-02
