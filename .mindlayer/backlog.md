# Backlog

## Future Roadmap

id: ml-20260430-005
created: 2026-04-30
updated: 2026-05-05 (session 6)
scope: project
type: backlog
tags: [roadmap]
confidence: medium
status: active
source: manual

### Summary
Full vision lives in `ROADMAP.md`. This entry tracks the immediate V2 priorities.

### Details

**Completed (V2 phase 1):**
- Proactive Behavior system shipped: end-of-turn detection, trigger phrases, surface formats in `memory-system.md`
- `/m-session` command shipped: `prompts/m-session.md`
- AGENTS.md thinned: behavior logic consolidated into `memory-system.md`
- ROADMAP.md updated: V2 reframed as AI-driven prompt automation

**Completed (V2 phase 2):**
- Archive mode: `prompts/m-archive.md` shipped; memory-system.md (live + template), AGENTS.md, m-session.md, m-status.md updated. Trigger phrases, stale criteria by type, checkpoints, and archive/delete execution all defined. `/m-clean` alias added.

**Completed (V2 phase 3):**
- Subdirectories: `private/`, `sessions/`, `cache/`, `tmp/` — behavior rules defined in memory-system.md (live + template). Session writes AI-initiated with approval at 4 checkpoints. private/ routing added to m-save. tmp/cache lifecycle added to m-archive. tmp/ stale check added to m-status.

**Completed (V2 phase 4):**
- Token Burned per-turn status block: Handoff deprecated; per-turn block defined in memory-system.md (live + template). Next Step prediction hierarchy (task → backlog → roadmap → brainstorm) and backlog-empty detection shipped.
- Goal Hierarchy and Flow: Mermaid diagram + Next Step rules added to context.md.

**Up next (V3 — Memory Quality + Smarter Retrieval):**

V3 phase 1:
- Memory health scoring: extend `/m-status` to auto-warn when files are stale, oversized, or contain duplicate entries. Surface a health score per file.
- Dynamic Next Step queue: refine the Token Burned block so `Next Step:` stays single-action, with an optional `Coming Up:` section shown only for meaningful ambiguity or when more than 2 pending actions exist. For ambiguity, list the recommended action first and mark it `(recommended)`; for long queues only, list actions in selection-priority order without recommendation markers.
- memory-system/ folder split: replace monolithic memory-system.md with indexed folder. Boot loads index + per-turn.md only (~750 tokens). Other sections load conditionally by trigger. Target: ~66% boot cost reduction for memory-system.

V3 phase 2:
- Memory diff: on boot or `/m-status`, surface what changed in memory since the last session (new entries, updated entries, archived entries).

V3 phase 3:
- Auto-summarization suggestions: when an entry or file exceeds a size threshold, propose compression, splitting, or archiving before the file overflows.

V3 phase 4:
- Programmatic index-first retrieval: strengthen `/m-retrieve` with scored ranking by tag match, recency, and importance rather than keyword-only search.

**Deferred:**
- Existing project onboarding flow: automated way to populate `.mindlayer/` from existing README, docs, or context when installing into a mature project.
- Memory-system.md changelog: surface what changed when memory-system.md is refreshed on reinstall.
- Migration guide: document how to adopt new template files (e.g. roadmap.md) in existing installs.

### When to use
Use when planning V2 work. See `ROADMAP.md` for the full multi-version vision.

### Related
ml-20260430-003
