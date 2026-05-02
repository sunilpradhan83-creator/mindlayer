# MindLayer Memory System

MindLayer is a markdown-first memory system for AI-native software development. Its job is to help agents remember durable knowledge, retrieve it cheaply, and avoid unsafe or noisy memory behavior.

## Command Behavior

- `/m-init` loads the minimum useful context for the current session.
- `/m-retrieve <query>` searches indexes first and loads only relevant sections.
- `/m-save` proposes memory writes from durable learnings and waits for approval.
- `/m-status` checks memory health and suggests fixes without writing.

## Write Rules

- Never write memory without explicit approval.
- Prefer updating an existing entry over creating a duplicate.
- Do not store raw chat logs.
- Store durable information, not transient thoughts.
- Keep entries compact, structured, and useful for retrieval.

## Read Rules

- Read this file first when initializing MindLayer behavior.
- Read `preferences.md` during `/m-init` as always-on global preference context.
- Read indexes before full memory files.
- During `/m-init`, always check project `.mindlayer/project.md` for stable project identity even when the project index marks it low importance or starter-like; report placeholder-only project identity as missing or starter-only.
- Load full sections only when relevant.
- Do not use `README.md` or `docs/` as memory input; they are human-facing documentation.
- Treat tool adapters such as `AGENTS.md`, `CLAUDE.md`, and Copilot instructions as thin instructions, not durable memory stores or retrieval sources.
- Do not load empty scaffold files or `local.md` by default.
- Load scaffold files or `local.md` only when an index marks them as relevant, the user task needs them, or they contain non-placeholder content.
- Go outside MindLayer memory only when necessary for the current task.
- Cite file and section when using memory.
- State what was loaded and skipped.

## Routing Rules

- Always-loaded cross-project user preferences belong in `~/.mindlayer/preferences.md`.
- Global preferences, reusable workflows, principles, anti-patterns, and prompt templates belong in `~/.mindlayer/`.
- Project identity, progress, decisions, context, backlog, and risks belong in `project/.mindlayer/`.
- Do not mirror global memory into `project/.mindlayer/`; read and write it directly from `~/.mindlayer/`.
- Private, local, session, cache, and temporary material must stay out of committed project memory.

## Token Rules

- Use L0 bootstrap for command behavior and essential indexes.
- Use L1 summaries and indexes for normal retrieval.
- Use L2 full sections only when the query requires detail.
- Do not load entire files by default.
- Treat placeholder scaffolds and local notes as skipped unless they are relevant or non-placeholder.
- Warn when memory files are nearing their size budget, not only after they overflow.
- When a file nears its limit, prompt for cleanup, merge, compression, or archive before adding more memory.

## Approval Rules

Memory writes require approval even when the content seems obvious. Show the destination, action, duplicate check, and confidence before writing.

## Lifecycle Statuses

- `active`: current and trusted.
- `experimental`: useful but not fully proven.
- `deprecated`: superseded but retained for reference.
- `archived`: inactive history.

V1 does not implement archive or cleanup automation, but it does require proactive warning when files become stale, oversized, or close to their budget.

## Index-First Retrieval

Indexes are compact maps for search. They are not full documentation. Search by title, tags, summary, type, status, importance, and last updated date before reading full sections, except for `preferences.md`, which is always loaded during `/m-init`.
