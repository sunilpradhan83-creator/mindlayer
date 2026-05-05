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

## MindLayer Handoff Display Boundaries

id: ml-20260504-001
created: 2026-05-04
updated: 2026-05-04
scope: project
type: decision
tags: [session-continuity, handoff, status, ux]
confidence: high
status: active
source: manual

### Summary
MindLayer Handoff is a checkpoint/status artifact, not a running commentary format.

### Details
Show the structured MindLayer Handoff only at task end, when the user explicitly asks for status or next steps, when work is paused, blocked, or handed off, and after crash or session recovery.

Do not show it before every command, after every command, during routine progress updates, while exploring files, while tests are still running, or for every small subtask.

During normal conversation or active execution, keep the user oriented with plain concise text and a proactive next-step cue when useful.

Preferred compact handoff shape:

```text
Backlog item: <larger durable goal>
Task: <current concrete work>
  - Last result: <what just happened>
  - Next step: <smallest useful action>
  - Status: active | blocked | paused | completed

Context:
  - Task: ~<N> words, ~<N> est. tokens
  - Session: ~<N> words, ~<N> est. tokens
```

### When to use
Use when designing session continuity, status reporting, adapter guidance, `/m-status`, `/m-save`, and future handoff or recovery behavior.

### Related
ml-20260503-004

