# Backlog

## Future Roadmap

id: ml-20260430-005
created: 2026-04-30
updated: 2026-05-12
scope: project
type: backlog
tags: [v4, command-runner, script, deferred]
confidence: medium
status: active
source: manual

### Summary
Near-term backlog tracks active/planned V4 work only. Full versioned vision lives in `ROADMAP.md`.

### Details

**Active V4 Phase 0 — Boot Weight Reduction:**
- Split per-turn rules into always-loaded core plus conditional modules.
- Compress project index, progress, and backlog for cheaper L0 boot.
- Save architecture decision and verify final boot word count.

**Planned V4 Foundation:**
- Standardized `ml` command runner foundation with read-only commands first: `ml boot`, `ml load`, `ml status`, `ml diff`, and `ml session`.
- Programmatic ranked loader over global/project indexes with deterministic scoring and archive handling.
- Guarded write commands: `ml save`, `ml archive`, and session writes after explicit approval.
- `ml script` lifecycle command: Signal -> Cut -> Refine -> Implement -> Prove -> Transfer.
- IDE extensions after runtime and SCRIPT flows stabilize.

**Deferred:**
- Memory-system.md changelog: surface what changed when memory-system.md is refreshed on reinstall.
- Migration guide: document how to adopt new template files (e.g. roadmap.md) in existing installs.
- `ml script` command (V4): walks any user through S→C→R→I→P→T for their project. Ships in global-template as a first-class user feature. Depends on solid Transfer (V3 ml save + memory health) being in place first.

### When to use
Use when choosing the next near-term MindLayer task. See `ROADMAP.md` for full versioned vision.

### Related
ml-20260430-003
