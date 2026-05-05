# Decisions

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
- `/m-init` must skip scaffold-only files and `local.md` by default unless relevant or non-placeholder.
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
Use during `/m-save`, memory routing, template updates, prompt changes, or any workflow that edits durable memory behavior.

### Related
ml-20260503-001

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
updated: 2026-05-05
scope: project
type: decision
tags: [session-continuity, per-turn, next-step, token-tracking, handoff, goal-hierarchy]
confidence: high
status: active
source: manual

### Summary
Handoff is deprecated. Every agent turn ends with a Token Burned block. Next Step prediction navigates a defined goal hierarchy to always surface a useful next action.

### Details
Every agent turn ends with:

```text
-------------------------------------------------------------
Token Burned:
  - Last turn: ~N words, ~N est. tokens
  - Session: ~N words, ~N est. tokens

Next Step: <smallest useful action>
--------------------------------------------------------------
```

Next Step prediction hierarchy (never blank):
1. Active task → next action within task
2. Task complete → next backlog item
3. Backlog empty → next roadmap phase (surface pull proposal)
4. Roadmap complete → propose brainstorming next major version with user

When backlog empties after task completion, the agent proactively surfaces a roadmap phase pull proposal. Human approves → agent decomposes phase into backlog items and proposes each for approval.

When roadmap is complete, agent proposes a brainstorming session to plan the next major version.

### When to use
Use when implementing per-turn status behavior, Next Step prediction, backlog-to-roadmap navigation, and goal hierarchy.

### Related
ml-20260504-001
ml-20260505-003
ml-20260430-005
ml-20260505-004

