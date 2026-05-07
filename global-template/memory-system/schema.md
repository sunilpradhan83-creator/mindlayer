# Schema Reference

<!-- managed by MindLayer installer — last_updated: YYYY-MM-DD -->

Load this file when the user asks about lifecycle statuses, subdirectory rules, or token strategy. Reference only — not needed on every turn.

## Token Rules

- Use L0 bootstrap for boot.md, router.md, and per-turn.md only.
- Use L1 summaries and indexes for normal retrieval.
- Use L2 full sections only when the query requires detail.
- Do not load entire files by default.
- Treat placeholder scaffolds and local notes as skipped unless they are relevant or non-placeholder.
- Warn when memory files are nearing their size budget, not only after they overflow.
- When a file nears its limit, prompt for cleanup, merge, compression, or archive before adding more memory.

## Lifecycle Statuses

- `active`: current and trusted.
- `experimental`: useful but not fully proven.
- `deprecated`: superseded but retained for reference.
- `archived`: inactive history. Content lives in `archive.md` (global or project scope). Index entry remains with `status: archived` and `file: archive.md` so `ml load` can still find it. Boot skips `archive.md`.

## Subdirectory Rules

Subdirectories under `.mindlayer/` are created on first use. Never create empty placeholder directories.

### private/
- Purpose: sensitive notes that must not be committed to git (API key references, personal context, sensitive project notes).
- Write: via `ml save` when the user marks content as sensitive or private.
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
- Read: via `ml load sessions` or a date query. On boot, if a recent session file exists, read only the `## Next` section and surface as a one-line cue in the boot receipt.
- Boot: skip full load. Surface `## Next` from the most recent session file only.
- Git: gitignored.
- Lifecycle: dated snapshots — no archive or cleanup needed.

### cache/
- Purpose: derived or computed context that can be regenerated (codebase scans, analysis results, summaries of large files).
- Write: AI writes when deriving expensive context for a task.
- Read: when the same derived context is needed again for the current task.
- Boot: always skip.
- Git: gitignored.
- Lifecycle: `ml clean` can clear stale cache entries. Safe to delete and regenerate without data loss.

### tmp/
- Purpose: ephemeral scratch notes during active multi-step work within a single session.
- Write: AI writes scratch notes mid-task.
- Read: only within the same session.
- Boot: skip. Warn if `tmp/` contains content from a prior session (stale scratch — offer to clear).
- Git: gitignored.
- Lifecycle: cleared at session start when stale, or on `ml clean`.
