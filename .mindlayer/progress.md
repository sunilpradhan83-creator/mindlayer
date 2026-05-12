# Progress

## Current Phase

id: ml-20260505-006
created: 2026-05-05
updated: 2026-05-12
scope: project
type: progress
tags: [v4, phase-0, boot-weight, compression]
confidence: high
status: active
source: manual

### Summary
V4 Phase 0 boot-weight reduction shipped. Track A compressed instruction-only boot by splitting per-turn modules, loading a summary-only boot index, and trimming progress/backlog to current state.

### Details
- Shipped: boot receipt fixture harness, per-turn core/module split, summary-only boot index, current-only progress, active-only backlog, archived V1/V2/V3 history, and Phase 0 architecture decision.
- Next: V4 command runner foundation with read-only commands first (`ml boot`, `ml load`, `ml status`, `ml diff`, `ml session`).

### When to use
Use when orienting to the current project phase or deciding what to work on next.

### Related
ml-20260430-005
ml-20260505-003
