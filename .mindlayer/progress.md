# Progress

## Current Phase

id: ml-20260505-006
created: 2026-05-05
updated: 2026-05-06
scope: project
type: progress
tags: [v3, memory-quality, retrieval]
confidence: high
status: active
source: manual

### Summary
V3 Memory Quality + Smarter Retrieval — phase 1 in progress.

### Details
- V1 complete: installer, prompt commands, thin adapters, boot/continuity contracts.
- V2 complete: proactive behavior, archive mode, /m-session, subdirectories (private/sessions/cache/tmp), Token Burned per-turn block, goal hierarchy.
- V3 phase 1 in progress: memory-system/ folder split complete (00373e4). Dynamic Next Step queue complete (4e17d2f, 3a2ad04) — Coming Up: section, plain-text Next Step, priority enforcement. Boot cost reduced from ~3,500 to ~950 tokens typical. Next: extend `/m-status` with per-file memory health scoring — stale, oversized, duplicate detection with a health score per file.
- V3 phase 2: memory diff — surface what changed in memory since the last session.
- V3 phase 3: auto-summarization suggestions when entries exceed size thresholds.
- V3 phase 4: programmatic index-first retrieval with scored ranking.

### When to use
Use when orienting to the current project phase or deciding what to work on next.

### Related
ml-20260430-005
ml-20260505-003
