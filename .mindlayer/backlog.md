# Backlog

## Future Roadmap

id: ml-20260430-005
created: 2026-04-30
updated: 2026-05-05 (session 5)
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

**Up next:**
- Nothing currently tracked. See ROADMAP.md for longer-horizon items.

**Deferred:**
- Existing project onboarding flow: automated way to populate `.mindlayer/` from existing README, docs, or context when installing into a mature project.
- Memory-system.md changelog: surface what changed when memory-system.md is refreshed on reinstall.
- Migration guide: document how to adopt new template files (e.g. roadmap.md) in existing installs.

### When to use
Use when planning V2 work. See `ROADMAP.md` for the full multi-version vision.

### Related
ml-20260430-003
