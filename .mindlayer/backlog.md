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

V3 phase 1: ✅ complete
- ✅ Memory health scoring: /m-status now scores each file OK|WARN|CRITICAL across staleness, size, and duplicates. Lint checks added.
- ✅ Dynamic Next Step queue: `Next Step:` single-action plain text; optional `Coming Up:` for ambiguity or >2 pending. Ambiguity: recommended first, marked `(recommended)`. Long queue: priority order, no markers.
- ✅ memory-system/ folder split: replace monolithic memory-system.md with indexed folder. Boot loads index + per-turn.md only (~750 tokens). Other sections load conditionally by trigger. Target: ~66% boot cost reduction for memory-system.

**Up next (V3 phase 2):**
- Memory diff: on boot or `/m-status`, surface what changed in memory since the last session (new entries, updated entries, archived entries).
- Per-turn behavioral contracts: load announcement, memory candidate scan checklist, index-driven retrieval check — defined in `per-turn.md`. Verified by `tests/agent-behavior/test-per-turn.sh` (61 contract tests, all passing). Global `~/.mindlayer/memory-system/per-turn.md` updated. Router.md simplified — announcement format now owned by per-turn.md.

V3 phase 3:
- Auto-summarization suggestions: when an entry or file exceeds a size threshold, propose compression, splitting, or archiving before the file overflows.

V3 phase 4:
- Programmatic index-first retrieval: strengthen `/m-retrieve` with scored ranking by tag match, recency, and importance rather than keyword-only search.

**Deferred:**
- Existing project onboarding flow: automated way to populate `.mindlayer/` from existing README, docs, or context when installing into a mature project.
- Memory-system.md changelog: surface what changed when memory-system.md is refreshed on reinstall.
- Migration guide: document how to adopt new template files (e.g. roadmap.md) in existing installs.
- `/m-script` command (V4): walks any user through S→C→R→I→P→T for their project. Ships in global-template as a first-class user feature. Depends on solid Transfer (V3 /m-save + memory health) being in place first.

### When to use
Use when planning V2 work. See `ROADMAP.md` for the full multi-version vision.

### Related
ml-20260430-003
