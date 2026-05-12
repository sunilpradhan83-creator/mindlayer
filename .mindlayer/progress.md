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
V4 Phase 0 boot-weight reduction is in progress. Track A compresses the instruction-only boot path before the V4 runtime exists: per-turn core/modules split, summary-only boot index, and compact progress/backlog files.

### Details
- Completed in Phase 0 so far: boot receipt fixture harness, per-turn core/module split, and summary-only boot index.
- Next: compress backlog to active V4 items, save Phase 0 architecture decision, verify boot word count, then commit wrap.

### When to use
Use when orienting to the current project phase or deciding what to work on next.

### Related
ml-20260430-005
ml-20260505-003
