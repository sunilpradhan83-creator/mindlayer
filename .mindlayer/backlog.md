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
updated: 2026-05-04
scope: project
type: backlog
tags: [session-continuity, approval, prompts]
confidence: high
status: archived
source: manual

### Summary
Session continuity behavior is implemented so agents track pending approvals, unfinished tasks, blockers, and likely next actions.

### Details
MindLayer helps agents surface the next useful move when the user acknowledges, pauses, changes topic, or may have lost the thread, without becoming noisy after every message.

When a memory write has been proposed but not approved, agents keep it visible as pending and remind the user before moving on to unrelated memory work.

This behavior is now operationalized in adapter guidance, shipped global memory-system behavior, `/m-save`, `/m-status`, install tests, lint, and the deterministic continuity contract test.

Optional future configuration for quiet, balanced, and proactive continuity modes remains later product exploration rather than V1 scope.

### When to use
Use for historical context when improving `/m-save`, command prompts, adapter instructions, or product behavior around unfinished work and pending approvals.

### Related
ml-20260503-002

## Automatic Session Initialization

id: ml-20260503-005
created: 2026-05-03
updated: 2026-05-04
scope: project
type: backlog
tags: [init, onboarding, token-transparency]
confidence: high
status: archived
source: manual

### Summary
Automatic session initialization is implemented and validated with a transparent context receipt instead of requiring users to remember `/m-init`.

### Details
MindLayer adapters and prompts now make boot-first behavior available so an AI companion initializes minimal useful memory at session start or tool preflight when supported, or before the first project-relevant request as a fallback.

The visible boot receipt contract includes loaded memory roots and files, skipped files, missing files, current understanding, current progress, rough word and estimated token cost, approximate context share by source, and token strategy.

`/m-init` remains as a legacy/manual refresh alias, but ordinary project work should not require users to invoke it.

Validated by `bash tests/agent-behavior/test-boot.sh`, `bash tools/lint.sh`, and `bash tools/test.sh` on 2026-05-04.

### When to use
Use for historical context when changing install behavior, adapters, `/m-init`, onboarding, or token-transparency reporting.

### Related
ml-20260503-004
