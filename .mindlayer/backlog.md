# Backlog

## Future Roadmap

id: ml-20260430-005
created: 2026-04-30
updated: 2026-05-05 (session 2)
scope: project
type: backlog
tags: [roadmap]
confidence: medium
status: active
source: manual

### Summary
Full vision lives in `ROADMAP.md`. This entry tracks the immediate V2 priorities.

### Details

**In progress:**
- Add "Proactive Behavior" section to `global-template/memory-system.md`: auto-detection rules, end-of-turn pattern detection, trigger phrases for all commands (m-save, m-retrieve, m-status, m-session). Update managed block in `install.sh` with thin reference. Propagates to all adapters on next install.

**Up next:**
- Update ROADMAP.md to reflect V2 direction: AI-driven prompt automation, not CLI replacement
- Archive mode: archive old entries without deleting them
- `m-clean` (m-forget + m-archive): deferred to V2
- `.mindlayer/` subdirectories: `private/`, `sessions/`, `cache/`, `tmp/` — deferred from V1, add back in V2 with real behavior behind each

**Deferred:**
- Existing project onboarding flow: automated way to populate `.mindlayer/` from existing README, docs, or context when installing into a mature project.
- Memory-system.md changelog: surface what changed when memory-system.md is refreshed on reinstall.
- Migration guide: document how to adopt new template files (e.g. roadmap.md) in existing installs.

### When to use
Use when planning V2 work. See `ROADMAP.md` for the full multi-version vision.

### Related
ml-20260430-003
