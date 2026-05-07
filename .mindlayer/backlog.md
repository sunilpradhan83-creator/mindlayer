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
- `ml session` command shipped: `prompts/ml-session.md`
- AGENTS.md thinned: behavior logic consolidated into `memory-system.md`
- ROADMAP.md updated: V2 reframed as AI-driven prompt automation

**Completed (V2 phase 2):**
- Archive mode: `prompts/ml-archive.md` shipped; memory-system.md (live + template), AGENTS.md, ml-session.md, ml-status.md updated. Trigger phrases, stale criteria by type, checkpoints, and archive/delete execution all defined. `ml clean` alias added.

**Completed (V2 phase 3):**
- Subdirectories: `private/`, `sessions/`, `cache/`, `tmp/` — behavior rules defined in memory-system.md (live + template). Session writes AI-initiated with approval at 4 checkpoints. private/ routing added to ml save. tmp/cache lifecycle added to ml archive. tmp/ stale check added to ml status.

**Completed (V2 phase 4):**
- Token Burned per-turn status block: Handoff deprecated; per-turn block defined in memory-system.md (live + template). Next Step prediction hierarchy (task → backlog → roadmap → brainstorm) and backlog-empty detection shipped.
- Goal Hierarchy and Flow: Mermaid diagram + Next Step rules added to context.md.

**Up next (V3 — Memory Quality + Smarter Retrieval):**

V3 phase 1: ✅ complete
- ✅ Memory health scoring: ml status now scores each file OK|WARN|CRITICAL across staleness, size, and duplicates. Lint checks added.
- ✅ Dynamic Next Step queue: `Next Step:` single-action plain text; optional `Coming Up:` for ambiguity or >2 pending. Ambiguity: recommended first, marked `(recommended)`. Long queue: priority order, no markers.
- ✅ memory-system/ folder split: replace monolithic memory-system.md with indexed folder. Boot loads index + per-turn.md only (~750 tokens). Other sections load conditionally by trigger. Target: ~66% boot cost reduction for memory-system.

**Completed (V3 phase 2):**
- ✅ Per-turn behavioral contracts: load announcement, memory candidate scan checklist, index-driven retrieval check — shipped in per-turn.md. 61 tests passing.
- ✅ ml onboard: three-phase adapter migration + project context flow — spec, boot/router wiring, 25 contract tests shipped. tools/test.sh now 7 suites.
- ✅ Memory diff: on boot or `ml status`, surface what changed in memory since the last session (new entries, updated entries, archived entries). 22 contract tests shipped. tools/test.sh now 8 suites.

V3 phase 3: ✅ complete
- ✅ Define size thresholds — reused status.md line-budget boundaries: near limit at 240+ lines, over limit above 300 lines.
- ✅ Per-turn size check — after approved memory writes, per-turn.md surfaces one memory size suggestion before Token Burned.
- ✅ ml status integration — status.md now suggests concrete cleanup targets/options for near/over-limit files.
- ✅ Contract tests — test-autosummarize.sh verifies thresholds, output format, duplicate-warning avoidance, and live/template sync.
- ✅ Global-template sync — live ~/.mindlayer and global-template per-turn/status specs synced in the same session.

V3 phase 4: ✅ complete
- ✅ Command rename: `ml load` is now primary and `ml retrieve` remains an alias.
- ✅ Ranked-load contract: load.md specifies deterministic scoring by title, tags, summary, type/status, importance, recency, and archive intent.
- ✅ Contract tests: test-load.sh verifies command naming, ranked output shape, scoring precedence examples, archive behavior, and live/template sync.

**Backlog empty — next roadmap phase: V4**
- Standardized `ml` command runner foundation: start with read-only deterministic commands (`ml load`, `ml status`, `ml diff`, `ml session`) to reduce agent drift and support future IDE integrations.
- Programmatic ranked loader: parse global/project indexes, compute deterministic scores, sort matches, skip/down-rank archived entries appropriately, and load only relevant sections.
- `ml script` command: walk users through Signal → Cut → Refine → Implement → Prove → Transfer.
- IDE extensions: bring MindLayer workflows into editor surfaces.

**Deferred:**
- Memory-system.md changelog: surface what changed when memory-system.md is refreshed on reinstall.
- Migration guide: document how to adopt new template files (e.g. roadmap.md) in existing installs.
- `ml script` command (V4): walks any user through S→C→R→I→P→T for their project. Ships in global-template as a first-class user feature. Depends on solid Transfer (V3 ml save + memory health) being in place first.

### When to use
Use when planning V2 work. See `ROADMAP.md` for the full multi-version vision.

### Related
ml-20260430-003
