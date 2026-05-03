# Backlog

## Future Roadmap

id: ml-20260430-005
created: 2026-04-30
updated: 2026-04-30
scope: project
type: backlog
tags: [roadmap]
confidence: medium
status: active
source: manual

### Summary
Future work belongs after the simple V1 seed.

### Details
- CLI in V2.
- VS Code extension later.
- Archive mode later.
- Optional vector search later.
- SaaS/product exploration later.

### When to use
Use when planning post-V1 work.

### Related
ml-20260430-003

## Deploy Readiness Test Harness

id: ml-20260502-001
created: 2026-05-02
updated: 2026-05-02
scope: project
type: backlog
tags: [testing, installer, deploy-readiness]
confidence: high
status: active
source: manual

### Summary
Add a sandboxed local readiness test suite that validates whether MindLayer is ready to deploy.

### Details
The suite should install MindLayer into both fresh and existing projects, exercise important installer and memory-contract edge cases, and report a clear deploy verdict. It should evolve with future feature changes and commits so it becomes a maintained deploy gate rather than a one-off installer check.

### When to use
Use when planning release validation, installer changes, or test coverage for new MindLayer features.

### Related
ml-20260430-006

## Session Continuity Tracking

id: ml-20260503-004
created: 2026-05-03
updated: 2026-05-03
scope: project
type: backlog
tags: [session-continuity, approval, prompts]
confidence: high
status: active
source: manual

### Summary
Add session continuity behavior so agents track pending approvals, unfinished tasks, blockers, and likely next actions.

### Details
MindLayer should help agents surface the next useful move when the user acknowledges, pauses, changes topic, or may have lost the thread, without becoming noisy after every message.

When a memory write has been proposed but not approved, agents should keep it visible as pending and remind the user before moving on to unrelated next steps.

This behavior likely belongs in prompts/adapters first, with optional future configuration for quiet, balanced, and proactive modes.

### When to use
Use when improving `/m-save`, command prompts, adapter instructions, or product behavior around unfinished work and pending approvals.

### Related
ml-20260503-002

## Automatic Session Initialization

id: ml-20260503-005
created: 2026-05-03
updated: 2026-05-03
scope: project
type: backlog
tags: [init, onboarding, token-transparency]
confidence: high
status: active
source: manual

### Summary
Move MindLayer toward automatic session initialization with a transparent context receipt instead of requiring users to remember `/m-init`.

### Details
During install, MindLayer should make adapter and prompt instructions available so an AI companion can initialize minimal useful memory on the first interaction in a project.

The first interaction should show a compact MindLayer welcome or context receipt: loaded memory roots, loaded files, skipped files, rough token or word cost, and percentage or share of context by source when available.

`/m-init` may remain as a manual refresh or current initialization receipt command, but it should not be the required startup path once automatic initialization is reliable.

### When to use
Use when changing install behavior, adapters, `/m-init`, onboarding, or token-transparency reporting.

### Related
ml-20260503-004
