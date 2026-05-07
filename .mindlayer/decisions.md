# Decisions

## ml onboard One-Time Flag via Index Entry

id: ml-20260507-009
created: 2026-05-07
updated: 2026-05-07
scope: project
type: decision
tags: [onboard, ml-onboard, flag, index, architecture]
confidence: high
status: active
source: manual

### Summary
`ml onboard` completion is flagged by writing a single entry to `.mindlayer/index.md` with `id: ml-onboard-complete, type: onboarding, status: complete`. On every subsequent boot, if this entry exists, skip `ml onboard` entirely.

### Details
- Alternative considered: a separate flag file (e.g. `.mindlayer/.onboarded`). Rejected — adds a new file with no other purpose, increases install surface.
- Index entry reuses existing infrastructure — no new file, no new install step, discoverable via standard index scan at boot.
- The index entry also serves as a record of when onboarding ran.
- Boot check: scan `.mindlayer/index.md` for `id: ml-onboard-complete` before deciding whether to fire `ml onboard`.

### When to use
When implementing or modifying the `ml onboard` flow — the index entry is the single source of truth for completion state.

### Related
ml-20260507-008

## Commands Subfolder Architecture

id: ml-20260507-008
created: 2026-05-07
updated: 2026-05-07
scope: project
type: decision
tags: [commands, architecture, token-efficiency, prompts, memory-system]
confidence: high
status: active
source: manual

### Summary
All ml command specs live in `memory-system/commands/` as per-command files loaded conditionally by the router. The `prompts/` folder is deleted. Each spec loads only when its command fires (~90 tokens vs ~1,200 for all specs at once).

### Details
- `prompts/` was never loaded by the router or boot — it provided false safety (specs existed but were never guaranteed to be in context).
- Specs moved into `memory-system/commands/`: index.md (dispatch map), init.md, retrieve.md, save.md, status.md, archive.md, session.md, onboard.md.
- Router is the index for memory-system files — no separate index.md needed inside memory-system/.
- `commands/index.md` is the entry point: loaded first when any `ml *` fires, then the agent loads the specific spec file.
- `session.md` content merged into `commands/session.md`. `memory-system/session.md` deleted.
- Routing rules moved from `read-write.md` into `router.md` — they belong at trigger-time, not write-time.
- `global-template/index.md` and `~/.mindlayer/index.md` deleted — `preferences/index.md` is the global catalog.

### When to use
When adding or modifying any ml command — always add to `memory-system/commands/` with a router trigger. Never create a standalone prompts/ file.

### Related
ml-20260507-007
ml-20260506-001

## Global-Template Sync Rule

id: ml-20260507-007
created: 2026-05-07
updated: 2026-05-07
scope: project
type: decision
tags: [global-template, sync, installer, per-turn, memory-system]
confidence: high
status: active
source: manual

### Summary
When any file in `~/.mindlayer/memory-system/` is updated, `global-template/memory-system/` must be synced in the same session. New users only receive what ships in global-template.

### Details
- Live `~/.mindlayer/memory-system/` is the runtime install for the current developer. Changes there do not automatically propagate to new installs.
- `global-template/memory-system/` is the source that the installer copies to new users on `install.sh` runs.
- If they diverge, existing users have newer behavior but new users install an older version — silent regression.
- Discovered this session: per-turn.md was updated live but global-template was not synced until explicitly caught at session close.

### Sync checklist (any memory-system/ change):
1. Edit live `~/.mindlayer/memory-system/<file>`
2. Apply identical change to `global-template/memory-system/<file>`
3. Run `tools/test.sh` to confirm both pass
4. Commit both together

### When to use
Use whenever editing any file inside `~/.mindlayer/memory-system/` or `global-template/memory-system/`.

### Related
ml-20260430-003
ml-20260507-006

## Agent-Agnostic Design Principle

id: ml-20260507-004
created: 2026-05-07
updated: 2026-05-07
scope: project
type: decision
tags: [architecture, agent-agnostic, adapters, design]
confidence: high
status: active
source: manual

### Summary
MindLayer is designed to work across any LLM tool — Claude, Codex, Cursor, Copilot, and any future agent. No feature, rule, or mitigation should be written as tool-specific unless it is explicitly a thin adapter for that tool.

### Details
- MindLayer is a control plane over agents, not a feature of any one agent.
- Rules, mitigations, and future plans must be framed agent-agnostically. Example: "Claude Code hooks" is wrong; "/m-script command runner" is right.
- Tool-specific content belongs only inside the relevant adapter file (AGENTS.md, CLAUDE.md, .github/copilot-instructions.md) and nowhere else.
- If a tool-specific assumption is found in memory, decisions, risks, or roadmap — correct it immediately.

### When to use
Use when writing any rule, mitigation, or future plan that references a specific agent or tool. Use when reviewing decisions or risks for accidental tool lock-in.

### Related
ml-20260430-003
ml-20260507-003

## ML-999 Backlog Evaluation Decisions

id: ml-20260507-005
created: 2026-05-07
updated: 2026-05-07
scope: project
type: decision
tags: [backlog, roadmap, ml-999, prioritization, v3, v4]
confidence: high
status: active
source: manual

### Summary
Backlog evaluation (ML-999, 2026-05-07) produced activation, defer, and reject decisions for ML-101 through ML-110. These decisions should not be re-litigated without new evidence.

### Details
**Rejected permanently** (overlap with existing tools or violates core principles):
- ML-104 Event-Based Memory System — overlaps with V2 proactive detection, adds infrastructure with no marginal gain
- ML-105 Evidence-Based Routing — already implemented as the unified router (V3 phase 1)
- ML-106 Indexed Memory Layer — already the core architecture, solved by memory-system/ folder split
- ML-107 Team Mode & Governance — premature; single-user retrieval not yet reliable
- ML-109 Auto-Learning Context Engine — violates deterministic-first principle; overlaps with LLM capabilities
- ML-110 Agent Skills Layer — MindLayer is not a coding agent and must not become one

**Deferred** (not needed now, revisit with evidence):
- ML-103 Multi-Agent Adapter Layer — no evidence of adapter gaps causing real failures
- ML-108 Memory Graph System — `Related:` field is sufficient; graph adds complexity LLMs can handle natively

**Activated (partial)**:
- ML-101 Context Intelligence Upgrade — scoped to ranked retrieval (V3 phase 4) on top of existing index; no ML, no new storage. Depends on memory diff (V3 phase 2) being stable first.

**Pulled from deferred into V3 active**:
- `ml onboard` — existing project onboarding command; unblocked by V3 phase 1 infrastructure. Biggest adoption barrier for non-greenfield projects.

### When to use
Use when evaluating new backlog proposals that overlap with any ML-101 through ML-110 item, or when planning V3/V4 scope.

### Related
ml-20260430-005
ml-20260505-003

## V1 Memory Architecture Decisions

id: ml-20260430-003
created: 2026-04-30
updated: 2026-04-30
scope: project
type: decision
tags: [architecture, installer, adapters]
confidence: high
status: active
source: manual

### Summary
MindLayer V1 uses markdown files, global and project memory layers, thin tool adapters, and strict source boundaries.

### Details
- Use `~/.mindlayer/` for global memory.
- Use project `.mindlayer/` for project memory.
- Use `AGENTS.md` as the universal adapter.
- Use `CLAUDE.md` and Copilot instructions as thin adapters.
- Treat `README.md` as human-facing product documentation only, not AI memory input.
- Treat tool adapters such as `AGENTS.md`, `CLAUDE.md`, and Copilot instructions as blocked memory stores: agents should not add durable memory there or use them as retrieval sources beyond the thin MindLayer instructions.
- AI agents should rely on global `~/.mindlayer/` and project `.mindlayer/` markdown files for initialization, on-demand retrieval, and memory writes.
- Agents may go outside MindLayer memory only when necessary for the task, and should remain cautious about token usage.
- Use a symlink to global memory when possible.
- Use a pointer fallback when symlink creation fails.
- Never overwrite existing user files.
- Fail fast on required installer write errors instead of printing success after partial failure.
- `ml init` must skip scaffold-only files and `local.md` by default unless relevant or non-placeholder.
- Do not ignore the entire `.mindlayer` directory.
- Do not implement archive or cleanup in V1.

### When to use
Use when evaluating feature scope, installer behavior, documentation boundaries, adapter behavior, or AI memory retrieval rules.

### Related
ml-project-20260430-001

## MindLayer Source-of-Truth Boundaries

id: ml-20260503-001
created: 2026-05-03
updated: 2026-05-03
scope: project
type: decision
tags: [source-of-truth, templates, memory-routing]
confidence: high
status: active
source: manual

### Summary
While working inside the MindLayer repo, product memory should be saved to project `.mindlayer/`, shipped global behavior should be implemented through `global-template`, and live `~/.mindlayer/` should not be manually edited.

### Details
MindLayer separates source-of-truth memory from generated or installed memory output.

During MindLayer repo development:
- Do not write product learnings to the live `~/.mindlayer/` folder. It is runtime/install/test output and may be regenerated during installs, manual tests, or releases.
- Do not write product learnings into `project-template` placeholders. Those files are starter memory for future MindLayer users.
- Use repo `.mindlayer/` for MindLayer product improvement memory: context, decisions, risks, progress, and backlog.
- Use `global-template` when intentionally changing default global memory behavior that should ship to MindLayer users.
- Update prompts/adapters when a saved product rule must become operational command behavior.

### When to use
Use when routing memory writes, changing templates, testing installs, preparing releases, or deciding where durable MindLayer product behavior belongs.

### Related
ml-20260430-003

## Literal Approval for Memory Writes

id: ml-20260503-002
created: 2026-05-03
updated: 2026-05-03
scope: project
type: decision
tags: [approval, memory-safety, commands]
confidence: high
status: active
source: manual

### Summary
Memory writes require literal explicit approval before editing durable memory.

### Details
Acknowledgments or vague instructions such as `ok`, `got it`, or `we need to save this` are not approval. The agent must propose the exact destination and content, then wait for clear approval such as `approve` or `go ahead` before writing memory.

This rule applies to project `.mindlayer/`, global-template changes, prompt/adapters that encode memory behavior, and any other durable MindLayer memory source.

### When to use
Use during `ml save`, memory routing, template updates, prompt changes, or any workflow that edits durable memory behavior.

### Related
ml-20260503-001

## Skill Approval Gate

id: ml-20260507-002
created: 2026-05-07
updated: 2026-05-07
scope: project
type: decision
tags: [approval, skills, ml-init, adapter-safety, memory-safety]
confidence: high
status: active
source: manual

### Summary
Skills that write files (such as the `init` skill triggered by `ml init`) must not execute autonomously in the MindLayer repo. The agent must read the target file, explain what the skill would do, and wait for explicit approval before any write.

### Details
- `ml init` in this repo triggers the `init` skill, which is designed to write or rewrite `CLAUDE.md`. In MindLayer, `CLAUDE.md` is a managed adapter file with a deliberate thin design — it must not be overwritten without approval.
- If a skill writes without approval, revert immediately and explain what happened.
- The literal approval rule (ml-20260503-002) applies to all file writes, including those initiated by skills and slash commands — not just `ml save`.
- MindLayer product learnings must be saved to `~/.mindlayer/` (global) or `.mindlayer/` (project), never to Claude's own memory system.

### When to use
Use when any skill, slash command, or automated tool attempts to write to files in the MindLayer repo.

### Related
ml-20260503-002

## Pre-Push Gate

id: ml-20260505-008
created: 2026-05-05
updated: 2026-05-05
scope: project
type: decision
tags: [pre-push, testing, quality-gate, proactive]
confidence: high
status: active
source: manual

### Summary
Before every push, the agent appends a one-line test confirmation. `yes` or `skip` both proceed immediately.

### Details
- Fires once per push action — before suggesting push as Next Step or when user requests push.
- Format: `Pre-push: tests added and run for this change? Say 'yes' to push or 'skip' to push without testing.`
- `yes` = tested and ready. `skip` = escape hatch, no further prompts.
- Does not fire during boot, status checks, or non-push turns.

### When to use
Use when implementing or evaluating pre-push quality gate behavior.

### Related
ml-20260505-005

## Lateral Intent Routing

id: ml-20260505-007
created: 2026-05-05
updated: 2026-05-05
scope: project
type: decision
tags: [lateral-intent, routing, backlog, roadmap, proactive]
confidence: high
status: active
source: manual

### Summary
When a user introduces work outside the current Next Step or backlog, the agent classifies it silently and appends a one-line non-blocking nudge before proceeding.

### Details
- Three classifications: backlog candidate (fits scope, recurring), roadmap amendment (scope change), ad-hoc (one-off, no capture needed).
- Agent never blocks the user. Nudge is append-only, one per turn, placed after main response and before Token Burned block.
- Does not fire during boot, status checks, or when user is responding to a Next Step or backlog pull.
- Nudge format: `Lateral intent: <type> — say 'add to backlog' or 'add to roadmap' to capture, or I'll just proceed.`
- Capture only happens if user explicitly responds — approval rules still apply.

### When to use
Use when implementing or evaluating proactive intent detection, backlog hygiene, and mid-session routing behavior.

### Related
ml-20260505-005
ml-20260430-005

## Token Burned Per-Turn Status Block

id: ml-20260505-005
created: 2026-05-05
updated: 2026-05-06
scope: project
type: decision
tags: [session-continuity, per-turn, next-step, token-tracking, handoff, goal-hierarchy, coming-up, priority]
confidence: high
status: active
source: manual

### Summary
Handoff is deprecated. Every agent turn ends with a Token Burned block. Next Step is always a single plain-text action. Optional Coming Up: surfaces for ambiguity or long queues. Priority hierarchy is strictly enforced.

### Details
Every agent turn ends with:

```text
-------------------------------------------------------------
Token Burned:
  - Last turn: ~N words, ~N est. tokens
  - Session: ~N words, ~N est. tokens

Next Step: <smallest useful action>

Coming Up:            ← omit when not needed
  - <action>
  - <action>
--------------------------------------------------------------
```

Next Step prediction hierarchy (never blank):
1. Active task → next action within task
2. Task complete + uncommitted changes → commit
3. Task complete + clean tree → next backlog item
4. Backlog empty → next roadmap phase (surface pull proposal)
5. Roadmap complete → propose brainstorming next major version with user

Coming Up rules:
- Show only when meaningful ambiguity exists between two equally valid next actions, OR more than 2 pending actions exist.
- For ambiguity: list recommended action first, marked `(recommended)`. Do not mark others.
- For long queues (>2 pending): list in selection-priority order. No `(recommended)` markers.
- Omit entirely when Next Step is clear and queue has ≤ 2 items.

Priority enforcement:
- Next Step is always the highest-priority action from the hierarchy. Apply the lowest-numbered rule that applies — never skip to a more interesting rule.
- Coming Up may only list actions lower in priority than Next Step. Never list an action in Coming Up that should have been Next Step.
- Uncommitted changes (rule 2) always outrank next backlog item (rule 3).

### When to use
Use when implementing per-turn status behavior, Next Step prediction, Coming Up: queue, backlog-to-roadmap navigation, and goal hierarchy.

### Related
ml-20260504-001
ml-20260505-003
ml-20260430-005
ml-20260505-004

