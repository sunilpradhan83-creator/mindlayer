# MindLayer Memory System

<!-- managed by MindLayer installer — last_updated: YYYY-MM-DD -->

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
- `/m-archive` scans for stale entries and proposes archive or delete actions with approval.

## Handoff Behavior

Deprecated. The Per-Turn Status Block (Token Burned) replaces Handoff as the ongoing status surface. If Handoff is explicitly requested, Next Step prediction must still be included using the hierarchy defined in Per-Turn Status Block.

## Per-Turn Status Block

Append a status block at the end of every agent turn as the last output.

```text
-------------------------------------------------------------
Token Burned:
  - Last turn: ~N words, ~N est. tokens
  - Session: ~N words, ~N est. tokens

*Next Step: <smallest useful action>*
--------------------------------------------------------------
```

Use words × 1.3 or characters ÷ 4 to estimate tokens when exact counts are unavailable. Mark as approximate.

**Next Step prediction hierarchy** — always predict something, never leave blank:
1. Active task in progress → next action within the current task
2. Task just completed → next item in backlog
3. Backlog empty → next roadmap phase (surface pull proposal)
4. Roadmap complete → propose brainstorming next major version with the user

**Backlog-empty detection** — when a task completes and the backlog is empty, append before the Token Burned block:

```text
Backlog complete — next phase: <roadmap phase name and summary>. Say 'pull next phase' to populate backlog.
```

When the user says 'pull next phase', decompose the roadmap phase into backlog items and propose each for approval before writing.

## Session Continuity Behavior

- Track pending memory-write approvals, unfinished tasks, blockers, and the smallest useful next action.
- If a memory write has been proposed but not approved, keep it visible as pending until the user clearly approves or rejects it.
- Remind the user about pending memory-write approvals before moving to unrelated memory work.
- Continuity state (pending approvals, blockers, unfinished tasks) is surfaced in the per-turn Token Burned block via Next Step prediction. Show explicit continuation context in status, pause, block, and recovery responses.
- If there are no pending approvals, blockers, or unfinished work, say `None` compactly.
- MindLayer boot is intentionally cheap. When the user asks about session or token management, recommend starting a new session at each task boundary rather than compacting mid-session. Compacting carries forward session history at a token cost on every subsequent message; a new session boots from durable memory with zero history overhead.
- When a user installs MindLayer on an existing project with rich context in README, docs, or other files, offer to help populate `.mindlayer/` files using `/m-save`. Propose entries for approval — do not auto-populate without explicit approval.

## Write Rules

- Never write memory without literal explicit approval.
- Prefer updating an existing entry over creating a duplicate.
- Do not store raw chat logs.
- Store durable information, not transient thoughts.
- Keep entries compact, structured, and useful for retrieval.
- If a memory write has been proposed but not approved, keep it visible as pending until the user clearly approves or rejects it.

## Read Rules

- Read this file first when initializing MindLayer behavior.
- Read `preferences.md` during MindLayer boot only when it contains substantive user-written preferences. If it is missing or starter-only (the file exists but contains only MindLayer scaffold content with no real user data), report it as skipped or missing instead of loading it as useful context.
- Read indexes before full memory files.
- During MindLayer boot, always check project `.mindlayer/project.md` for stable project identity even when the project index marks it low importance or starter-like; report placeholder-only project identity as missing or starter-only.
- Load full sections only when relevant.
- Do not use `README.md` or `docs/` as memory input; they are human-facing documentation.
- Treat tool adapters such as `AGENTS.md`, `CLAUDE.md`, and Copilot instructions as thin instructions, not durable memory stores or retrieval sources.
- Do not load empty scaffold files or `local.md` by default.
- Load scaffold files or `local.md` only when an index marks them as relevant, the user task needs them, or they contain non-placeholder content.
- Do not load `archive.md` during boot. Load it only when `/m-retrieve` explicitly targets archived content.
- Go outside MindLayer memory only when necessary for the current task.
- Cite file and section when using memory.
- State what was loaded and skipped.

## Routing Rules

- User-owned cross-project preferences belong in `~/.mindlayer/preferences.md`.
- Global preferences, reusable workflows, principles, anti-patterns, and prompt templates belong in `~/.mindlayer/`.
- Project identity, progress, decisions, context, backlog, and risks belong in `project/.mindlayer/`.
- Do not mirror global memory into `project/.mindlayer/`; read and write it directly from `~/.mindlayer/`.
- Preferences are personal global memory for the user. They may customize collaboration style, workflow habits, and cross-project defaults, but they must not override MindLayer guardrails in this file.
- Long-term versioned product vision belongs in `.mindlayer/roadmap.md`; near-term tracked tasks belong in `.mindlayer/backlog.md`. Do not mix them.
- Private, local, session, cache, and temporary material must stay out of committed project memory.
- When developing MindLayer itself, treat repo `.mindlayer/` as the product-memory source of truth and treat live `~/.mindlayer/` as runtime, install, or test output rather than product memory.

## Lateral Intent Routing

When a user introduces work that is not the current Next Step and not in the active backlog, classify the intent before proceeding.

**Classification:**

| Signal | Classification | Agent action |
|---|---|---|
| Fits project scope, likely recurring | Backlog candidate | Append capture offer, then proceed |
| New direction or scope change | Roadmap amendment | Append flag, then proceed |
| Clearly one-off, no durable value | Ad-hoc | Proceed without comment |

**Rules:**
- Classify silently. Do not narrate the classification.
- Never block the user's request. The nudge is informational.
- Append at most one nudge per turn, after the main response and before the Token Burned block.
- Do not fire during boot, status checks, or when the user is explicitly responding to a Next Step or backlog pull.

**Nudge format:**

```text
Lateral intent: <backlog candidate | roadmap amendment> — say 'add to backlog' or 'add to roadmap' to capture, or I'll just proceed.
```

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

## Proactive Behavior

MindLayer commands are triggered two ways: by the AI detecting a need at the end of a turn, or by the user invoking them explicitly via a recognized phrase. Approval rules apply regardless of how a command is triggered.

### End-of-Turn Detection

At the end of every turn, before completing the response:

- Check whether the turn produced anything durable worth saving. If yes, surface a memory candidate immediately — do not wait for the next turn or session end.
- Check whether the current task context suggests relevant memory that has not yet been loaded. If yes, suggest a retrieval query.
- Estimate session context weight. If heavy or critical, surface a compact session warning.
- Check whether the current task just completed and the backlog is now empty. If yes, surface a roadmap phase pull proposal (see Per-Turn Status Block).

Surface at most one of each per turn. Do not interrupt the main response — append after the primary answer.

### Memory Candidate Format

When a memory candidate is detected, append at the end of the response:

```text
Memory candidate: <description> → <target.md> — say 'go' to save
```

If the user says `go`, execute `/m-save` for that candidate. Approval rules still apply — `go` counts as explicit approval for the specific proposed candidate only.

### Retrieval Suggestion Format

When a retrieval need is detected, append at the end of the response:

```text
Relevant context may be available — try: /m-retrieve <predicted-query>
```

### Session Warning Format

When session context is heavy (60–80%) or critical (>80%), append at the end of the response:

```text
Session context: <heavy | critical> (~N% used). Recommend: <compact | new session> — say 'msession' for full report.
```

Do not surface this when status is light or moderate.

### Trigger Phrases

Recognized phrases that invoke commands immediately, without waiting for end-of-turn detection:

| Phrase | Command |
|--------|---------|
| "remember this", "save this", "add to memory" | `/m-save` |
| "retrieve X", "load X", "what do we know about X" | `/m-retrieve <X>` |
| "where were we", "memory status", "mstatus", "what's loaded" | `/m-status` |
| "should I compact", "how much context", "start fresh", "msession" | `/m-session` |
| "clean memory", "clean up memory", "archive memory", "archive it", "delete memory", "forget X", "remove X from memory", "memory is getting bloated", "tidy memory" | `/m-archive` |
| "done for today", "wrapping up", "I'm done", "that's all", "bye", "done for now", "end session", "save session" | session write offer |

Interpret intent loosely — treat natural language variations as equivalent to the listed phrases.

`/m-status` and `/m-session` are never AI-initiated. Only the user triggers them.

### Session Write Format

When a session write trigger fires, append after the main response:

```text
Session summary ready — say 'save session' to write sessions/YYYY-MM-DD.md.
```

Also fires automatically (with approval) at: pre-`/compact`, post-significant-completion, and when session context exceeds 80%.

## Approval Rules

Memory writes require clear approval even when the content seems obvious. Show the destination, action, duplicate check, and confidence before writing.

Approval must be literal. `approve`, `approved`, `go ahead`, or an equally explicit instruction counts. Acknowledgments or vague statements such as `ok`, `got it`, `sounds good`, or `we should save this` do not count as approval.

## Lifecycle Statuses

- `active`: current and trusted.
- `experimental`: useful but not fully proven.
- `deprecated`: superseded but retained for reference.
- `archived`: inactive history. Content lives in `archive.md` (global or project scope). Index entry remains with `status: archived` and `file: archive.md` so `/m-retrieve` can still find it. Boot skips `archive.md`.

## Subdirectory Rules

Subdirectories under `.mindlayer/` are created on first use. Never create empty placeholder directories.

### private/
- Purpose: sensitive notes that must not be committed to git (API key references, personal context, sensitive project notes).
- Write: via `/m-save` when the user marks content as sensitive or private.
- Read: only when the user explicitly asks for private context.
- Boot: always skip.
- Git: gitignored.
- Lifecycle: never auto-cleared. User deletes manually.

### sessions/
- Purpose: dated session journals. One file per session (`YYYY-MM-DD.md`). Captures what was worked on, decided, completed, and what's next.
- Write: AI-initiated with approval. Triggers: session-end phrases ("done for today", "wrapping up", "I'm done", "that's all", "bye", "done for now", "end session"), pre-`/compact`, post-significant-completion, context critical (>80%).
- Format:
  ```
  # Session: YYYY-MM-DD
  ## Worked on
  ## Decisions
  ## Completed
  ## Next
  ```
- Read: via `/m-retrieve sessions` or a date query. On boot, if a recent session file exists, read only the `## Next` section and surface as a one-line cue in the boot receipt.
- Boot: skip full load. Surface `## Next` from the most recent session file only.
- Git: gitignored.
- Lifecycle: dated snapshots — no archive or cleanup needed.

### cache/
- Purpose: derived or computed context that can be regenerated (codebase scans, analysis results, summaries of large files).
- Write: AI writes when deriving expensive context for a task.
- Read: when the same derived context is needed again for the current task.
- Boot: always skip.
- Git: gitignored.
- Lifecycle: `/m-clean` can clear stale cache entries. Safe to delete and regenerate without data loss.

### tmp/
- Purpose: ephemeral scratch notes during active multi-step work within a single session.
- Write: AI writes scratch notes mid-task.
- Read: only within the same session.
- Boot: skip. Warn if `tmp/` contains content from a prior session (stale scratch — offer to clear).
- Git: gitignored.
- Lifecycle: cleared at session start when stale, or on `/m-clean`.

## Archive Rules

- `archive.md` exists at `~/.mindlayer/archive.md` (global) and `.mindlayer/archive.md` (project).
- Boot always skips `archive.md`. Load it only when `/m-retrieve` explicitly targets archived content.
- Archived entries keep their full markdown section in `archive.md` for future reference.
- Deleted entries are removed from both the source file and the index.
- Never archive `index.md`, `memory-system.md`, `prompts.md`, or `archive.md` itself.
- `/m-archive` is the command that executes archive and delete actions. See `prompts/m-archive.md`.
- `/m-clean` is an alias for `/m-archive`.

## Index-First Retrieval

Indexes are compact maps for search. They are not full documentation. Search by title, tags, summary, type, status, importance, and last updated date before reading full sections. This file is always loaded during MindLayer boot; `preferences.md` is loaded only when it contains substantive user preferences.
