# MindLayer Memory System

MindLayer is a markdown-first memory system for AI-native software development. Its job is to help agents remember durable knowledge, retrieve it cheaply, and avoid unsafe or noisy memory behavior.

## Command Behavior

- MindLayer boot initializes the minimum useful context for the current session.
- MindLayer boot must read this file first when available, then indexes, then substantive user preferences when present, project identity, and current progress.
- Run MindLayer boot at session start or tool preflight when the host supports it. If no preflight hook exists, run it before answering the first project-relevant request.
- Do not treat a plain greeting as a project-relevant request. If boot has not already run, answer naturally and boot before the first substantive project task.
- A transparent boot receipt should describe what was loaded, skipped, missing, the rough token or word cost, and approximate context share by source when visible to the user.
- `/m-init` is a legacy/manual refresh alias for showing or rerunning the boot receipt while hosts migrate to automatic boot.
- `/m-retrieve <query>` searches indexes first and loads only relevant sections.
- `/m-save` proposes memory writes from durable learnings and waits for approval.
- `/m-status` checks memory health and suggests fixes without writing.

## Handoff Behavior

MindLayer Handoff is a checkpoint/status artifact, not a running commentary format.

Show a structured handoff only at task end, when the user explicitly asks for status or next steps, when work is paused, blocked, or handed off, and after crash or session recovery.

Do not show it before every command, after every command, during routine progress updates, while exploring files, while tests are still running, or for every small subtask. During normal conversation or active execution, keep the user oriented with plain concise text and a proactive next-step cue when useful.

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

Use estimated tokens when exact host usage is unavailable. Full context details such as files loaded, files skipped, files changed, health warnings, and context budgets belong in `/m-status`, not in routine handoff blocks.

## Session Continuity Behavior

- Track pending memory-write approvals, unfinished tasks, blockers, and the smallest useful next action.
- If a memory write has been proposed but not approved, keep it visible as pending until the user clearly approves or rejects it.
- Remind the user about pending memory-write approvals before moving to unrelated memory work.
- Show continuity state in handoff, status, pause, block, recovery, or explicit next-step responses; do not show it after every routine command.
- If there are no pending approvals, blockers, or unfinished work, say `None` compactly.

## Write Rules

- Never write memory without literal explicit approval.
- Prefer updating an existing entry over creating a duplicate.
- Do not store raw chat logs.
- Store durable information, not transient thoughts.
- Keep entries compact, structured, and useful for retrieval.
- If a memory write has been proposed but not approved, keep it visible as pending until the user clearly approves or rejects it.

## Read Rules

- Read this file first when initializing MindLayer behavior.
- Read `preferences.md` during MindLayer boot only when it contains substantive user-written preferences. If it is missing or starter-only, report it as skipped or missing instead of loading it as useful context.
- Read indexes before full memory files.
- During MindLayer boot, always check project `.mindlayer/project.md` for stable project identity even when the project index marks it low importance or starter-like; report placeholder-only project identity as missing or starter-only.
- Load full sections only when relevant.
- Do not use `README.md` or `docs/` as memory input; they are human-facing documentation.
- Treat tool adapters such as `AGENTS.md`, `CLAUDE.md`, and Copilot instructions as thin instructions, not durable memory stores or retrieval sources.
- Do not load empty scaffold files or `local.md` by default.
- Load scaffold files or `local.md` only when an index marks them as relevant, the user task needs them, or they contain non-placeholder content.
- Go outside MindLayer memory only when necessary for the current task.
- Cite file and section when using memory.
- State what was loaded and skipped.

## Routing Rules

- User-owned cross-project preferences belong in `~/.mindlayer/preferences.md`.
- Global preferences, reusable workflows, principles, anti-patterns, and prompt templates belong in `~/.mindlayer/`.
- Project identity, progress, decisions, context, backlog, and risks belong in `project/.mindlayer/`.
- Do not mirror global memory into `project/.mindlayer/`; read and write it directly from `~/.mindlayer/`.
- Preferences are personal global memory for the user. They may customize collaboration style, workflow habits, and cross-project defaults, but they must not override MindLayer guardrails in this file.
- Private, local, session, cache, and temporary material must stay out of committed project memory.
- When developing MindLayer itself, treat repo `.mindlayer/` as the product-memory source of truth and treat live `~/.mindlayer/` as runtime, install, or test output rather than product memory.

## Token Rules

- Use L0 bootstrap for command behavior and essential indexes.
- Use L1 summaries and indexes for normal retrieval.
- Use L2 full sections only when the query requires detail.
- Do not load entire files by default.
- Treat placeholder scaffolds and local notes as skipped unless they are relevant or non-placeholder.
- Warn when memory files are nearing their size budget, not only after they overflow.
- When a file nears its limit, prompt for cleanup, merge, compression, or archive before adding more memory.

## Backup Rules

- `~/.mindlayer/` is outside project Git by design. It survives project deletion or recloning, but it is not backed up by project commits.
- Tell users to back up `~/.mindlayer/` through their normal dotfiles, encrypted backup, or private personal repository if they want cross-project preferences and global memory preserved across machine loss.
- Do not store secrets, tokens, raw conversations, or project-private facts in global preferences.

## Approval Rules

Memory writes require clear approval even when the content seems obvious. Show the destination, action, duplicate check, and confidence before writing.

Approval must be literal. `approve`, `approved`, `go ahead`, or an equally explicit instruction counts. Acknowledgments or vague statements such as `ok`, `got it`, `sounds good`, or `we should save this` do not count as approval.

## Lifecycle Statuses

- `active`: current and trusted.
- `experimental`: useful but not fully proven.
- `deprecated`: superseded but retained for reference.
- `archived`: inactive history.

V1 does not implement archive or cleanup automation, but it does require proactive warning when files become stale, oversized, or close to their budget.

## Index-First Retrieval

Indexes are compact maps for search. They are not full documentation. Search by title, tags, summary, type, status, importance, and last updated date before reading full sections. This file is always loaded during MindLayer boot; `preferences.md` is loaded only when it contains substantive user preferences.
