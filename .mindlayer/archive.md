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
