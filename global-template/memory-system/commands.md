# Commands

<!-- managed by MindLayer installer — last_updated: YYYY-MM-DD -->

Load this file when the user invokes any ml * command. Then load the spec file for the specific command from `memory-system/commands/`. See `memory-system/commands/index.md` for the full command map.

## Command Behavior

- MindLayer boot initializes the minimum useful context for the current session.
- Run MindLayer boot at session start or tool preflight when the host supports it. If no preflight hook exists, run it before answering the first project-relevant request.
- Do not treat a plain greeting as a project-relevant request. If boot has not already run, answer naturally and boot before the first substantive project task.
- A transparent boot receipt should describe what was loaded, skipped, missing, the rough token or word cost, and approximate context share by source when visible to the user.
- `ml init` is a legacy/manual refresh alias for showing or rerunning the boot receipt.
- `ml retrieve <query>` searches indexes first and loads only relevant sections.
- `ml save` proposes memory writes from durable learnings and waits for approval.
- `ml status` checks memory health and suggests fixes without writing.
- `ml archive` scans for stale entries and proposes archive or delete actions with approval.
- `ml session` reports session context cost and recommends compact or new session.
- `ml onboard` runs once post-install on existing projects to populate `.mindlayer/` from existing context.

## Archive Rules

- `archive.md` exists at `~/.mindlayer/archive.md` (global) and `.mindlayer/archive.md` (project).
- Boot always skips `archive.md`. Load it only when `ml retrieve` explicitly targets archived content.
- Archived entries keep their full markdown section in `archive.md` for future reference.
- Deleted entries are removed from both the source file and the index.
- Never archive `index.md`, `boot.md`, `router.md`, or `archive.md` itself.
- `ml archive` is the command that executes archive and delete actions. Full spec in `memory-system/commands/archive.md`.
- `ml clean` is an alias for `ml archive`.

## Index-First Retrieval

Indexes are compact maps for search. They are not full documentation. Search by title, tags, summary, type, status, importance, and last updated date before reading full sections.

On boot, read project `.mindlayer/index.md` and `preferences/index.md` as catalogs. Load full files only when content is needed for the current task.
