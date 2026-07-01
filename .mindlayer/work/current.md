# Current Work

## Current Phase

id: ml-20260505-006
created: 2026-05-05
updated: 2026-07-01
scope: project
type: progress
tags: [open-source, developer-preview, script, stage-0, correctness, adr, migration]
confidence: high
status: in-progress
source: conversation

### Summary
ADR-0001 target architecture is frozen and committed on branch `adr-0001-architecture`
(commit `c669261`; `main` untouched). Step 2a is complete and committed at `0df80fb`:
the runtime now has a dual-layout read seam for legacy `pipeline/` and ADR-0001
`work/`/top-level archive paths, plus read-only adapter status detection. Full suite was
green when Step 2a landed; focused follow-up checks for truthful session-source boot
reporting also passed. Current phase: Step 2b — consolidate `pipeline/` into
`work/current.md` with explicit migration behavior. MCP work (Steps 3-4) follows the
migration, not before.

### Details
- Completed 2026-07-01: Step 2a ADR migration foundation committed as `0df80fb`. Added
  `_layout.py` dual-layout resolvers, `_adapters.py` read-only adapter status detection,
  refactored boot/session/diff/status read paths through the seam, and added
  `tests/migration/` coverage for layout detection, legacy compatibility, fresh-install
  legacy guard, adapter detector/no-writes behavior, mixed session history, and session
  write co-location. Follow-up fix made `ml boot` report the actual latest session source
  instead of hardcoding the legacy sessions path.
- Completed 2026-07-01: committed ADR-0001 + typed-status schema (`c669261`), reviewed for consistency across index/architecture.md/schema/install.sh/lint.sh, and cleared the 13 spec-layout failures via a non-destructive live-runtime re-sync. Next work is Step 2 (ADR migration foundation), deferred to a fresh session; see `knowledge/sessions/2026-07-01.md` for the ordered 2a-2d slices.
- Completed this session: created `knowledge/decisions/script-v0.1.md`, marked `script-v4.md` superseded, updated decisions index, rewrote canonical roadmap, mirrored public ROADMAP, added SCRIPT enforcement backlog item, and wrote the 2026-05-17 session summary.
- Completed after Stage 0.0: Item 0 Day 1 - starter-content sentinel format chosen and boot truth fixes implemented so starter project/personal memory does not appear substantive.
- Completed after Item 0 Day 1: fixed fresh installs so `.mindlayer/router.md` is created from `project-template/router.md`, with local install coverage for fresh and skip-flag installs.
- Completed after project router fix: fixed `ml diff` so entries moved into `.mindlayer/pipeline/archive/` report as archived instead of new, including Git rename handling and regression coverage.
- Completed after `ml diff` fix: fixed `ml load` ranking so importance/recency metadata cannot rank entries without a real query hit, with regression coverage for unrelated high-importance preferences.
- Completed after `ml load` ranking fix: fixed `ml load` section extraction so nested summaries stay attached to their parent heading and title/heading mismatches can resolve by entry id.
- Completed after `ml load` section fix: fixed `ml status` duplicate detection so repeated standard subheadings like `### Summary` do not trigger duplicate-entry warnings, while duplicate `##` entry headings still do.
- Completed after `ml status` fix: fixed hierarchical `ml clean`, nearest-index `ml save`, README CLI/runtime drift, and README adapter drift; added regression/lint coverage.
- Stage 0.1 baseline is frozen as a 0.1 Developer Preview, not a 1.0 launch.
- Existing V4 runtime work remains shipped, but the next release focus is correctness, positioning, open-source hygiene, and rename.
- Next: start Step 2b by designing the explicit migration from `pipeline/progress.md`,
  `pipeline/backlog.md`, and `pipeline/signals.md` into `work/current.md`, including
  archive/compression of the two known W2 files during the slice.

### When to use
Use when orienting to the current project phase or deciding what to work on next.

### Related
ml-20260430-005
ml-20260505-003

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
