# Backlog

## Future Roadmap

id: ml-20260430-005
created: 2026-04-30
updated: 2026-05-05
scope: project
type: backlog
tags: [roadmap]
confidence: medium
status: active
source: manual

### Summary
Full vision lives in `ROADMAP.md`. This entry tracks the immediate V2 priorities.

### Details
- CLI: `m install`, `m save`, `m retrieve`, `m status`, `m session`
- Archive mode: archive old entries without deleting them
- `/m-session` command: session context cost and new-session vs compact recommendation
- `.mindlayer/` subdirectories: `private/`, `sessions/`, `cache/`, `tmp/` — deferred from V1, add back in V2 with real behavior behind each

- Existing project onboarding flow: automated way to populate `.mindlayer/` from existing README, docs, or context when installing into a mature project. V2 CLI feature.
- Memory-system.md changelog: surface what changed when memory-system.md is refreshed on reinstall so users know their agent behavior updated.
- Migration guide: document how to adopt new template files (e.g. roadmap.md) in existing installs.

### When to use
Use when planning V2 work. See `ROADMAP.md` for the full multi-version vision.

### Related
ml-20260430-003
