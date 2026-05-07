# Read and Write Rules

<!-- managed by MindLayer installer — last_updated: YYYY-MM-DD -->

Load this file before any memory read or write operation — before proposing ml save, writing to .mindlayer/, or reading memory for a task.

## Write Rules

- Never write memory without literal explicit approval.
- Prefer updating an existing entry over creating a duplicate.
- Do not store raw chat logs.
- Store durable information, not transient thoughts.
- Keep entries compact, structured, and useful for retrieval.
- If a memory write has been proposed but not approved, keep it visible as pending until the user clearly approves or rejects it.

## Read Rules

- Read `~/.mindlayer/boot.md` first when initializing MindLayer behavior, then `router.md`, then follow load triggers.
- Read `preferences/personal.md` during MindLayer boot only when it contains substantive user-written preferences. If it is missing or starter-only (the file exists but contains only MindLayer scaffold content with no real user data), report it as skipped or missing instead of loading it as useful context.
- Read indexes before full memory files.
- During MindLayer boot, always check project `.mindlayer/project.md` for stable project identity even when the project index marks it low importance or starter-like; report placeholder-only project identity as missing or starter-only.
- Load full sections only when relevant.
- Do not use `README.md` or `docs/` as memory input; they are human-facing documentation.
- Treat tool adapters such as `AGENTS.md`, `CLAUDE.md`, and Copilot instructions as thin instructions, not durable memory stores or retrieval sources.
- Do not load empty scaffold files or `local.md` by default.
- Load scaffold files or `local.md` only when an index marks them as relevant, the user task needs them, or they contain non-placeholder content.
- Do not load `archive.md` during boot. Load it only when `ml load` explicitly targets archived content.
- Go outside MindLayer memory only when necessary for the current task.
- Cite file and section when using memory.
- State what was loaded and skipped.

## Approval Rules

Memory writes require clear approval even when the content seems obvious. Show the destination, action, duplicate check, and confidence before writing.

Approval must be literal. `approve`, `approved`, `go ahead`, or an equally explicit instruction counts. Acknowledgments or vague statements such as `ok`, `got it`, `sounds good`, or `we should save this` do not count as approval.
