# Commands

<!-- managed by MindLayer installer — last_updated: YYYY-MM-DD -->

Load this file when the user invokes any /m-* command. Defines command behavior, archive execution, and retrieval strategy.

## Command Behavior

- MindLayer boot initializes the minimum useful context for the current session.
- Run MindLayer boot at session start or tool preflight when the host supports it. If no preflight hook exists, run it before answering the first project-relevant request.
- Do not treat a plain greeting as a project-relevant request. If boot has not already run, answer naturally and boot before the first substantive project task.
- A transparent boot receipt should describe what was loaded, skipped, missing, the rough token or word cost, and approximate context share by source when visible to the user.
- `/m-init` is a legacy/manual refresh alias for showing or rerunning the boot receipt while hosts migrate to automatic boot.
- `/m-retrieve <query>` searches indexes first and loads only relevant sections.
- `/m-save` proposes memory writes from durable learnings and waits for approval.
- `/m-status` checks memory health and suggests fixes without writing.
- `/m-archive` scans for stale entries and proposes archive or delete actions with approval.

## Archive Rules

- `archive.md` exists at `~/.mindlayer/archive.md` (global) and `.mindlayer/archive.md` (project).
- Boot always skips `archive.md`. Load it only when `/m-retrieve` explicitly targets archived content.
- Archived entries keep their full markdown section in `archive.md` for future reference.
- Deleted entries are removed from both the source file and the index.
- Never archive `index.md`, `boot.md`, `router.md`, or `archive.md` itself.
- `/m-archive` is the command that executes archive and delete actions. See `prompts/m-archive.md`.
- `/m-clean` is an alias for `/m-archive`.

## Index-First Retrieval

Indexes are compact maps for search. They are not full documentation. Search by title, tags, summary, type, status, importance, and last updated date before reading full sections.

On boot, read `index.md` and `preferences/index.md` as catalogs. Load full files only when content is needed for the current task.
