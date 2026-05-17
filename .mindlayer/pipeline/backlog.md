# Backlog

## Future Roadmap

id: ml-20260430-005
created: 2026-04-30
updated: 2026-05-14
scope: project
type: backlog
tags: [v4, command-runner, script, deferred]
confidence: medium
status: active
source: manual

### Summary
Near-term backlog tracks active/planned V4 work only. Full versioned vision lives in `ROADMAP.md`.

### Details

**Active 0.1 Planning:**
- SCRIPT v0.1 enforcement mechanisms: decide per required rule whether it should be CLI-enforced via `ml save`/future lifecycle commands, warned by `ml status --strict`, or documented as convention-only. Rules to classify: linked signal for XS direct fixes, `proof_type` enum, transfer check at story close, non-empty Cut destination, and backlog cap warnings. Priority: medium. Target: 0.1.x or 0.2 after dogfood shows which gaps actually decay. 0.1 ships the methodology and documented field conventions, not full runtime enforcement.

**Active V4 Foundation:**
- Standardized `ml` command runner foundation with read-only commands first: `ml boot`, `ml load`, `ml status`, `ml diff`, and `ml session`.
- Programmatic ranked loader over global/project indexes with deterministic scoring and archive handling.
- Guarded write commands: `ml save`, `ml clean`, and session writes after explicit approval.
- `ml script` lifecycle command: Signal -> Cut -> Refine -> Implement -> Prove -> Transfer.
- IDE extensions after runtime and SCRIPT flows stabilize.

**Next (post-security hardening):**

**Deferred:**
- Memory-system.md changelog: surface what changed when memory-system.md is refreshed on reinstall.
- Migration guide: document how to adopt new template files (e.g. roadmap.md) in existing installs.
- `ml script` command (V4): walks any user through S→C→R→I→P→T for their project. Ships in global-template as a first-class user feature. Depends on solid Transfer (V3 ml save + memory health) being in place first.

### When to use
Use when choosing the next near-term MindLayer task. See `ROADMAP.md` for full versioned vision.

### Related
ml-20260430-003
