# MindLayer Boot

Initialize this AI session with minimal useful MindLayer memory context and report a transparent context receipt when visible to the user.

`/m-init` is a legacy/manual refresh alias for this boot procedure while hosts migrate to automatic session-start or preflight boot.

## Procedure

1. Read `~/.mindlayer/memory-system.md` first if available. If missing, use project `.mindlayer/` files and note the missing global system file.
2. Read `~/.mindlayer/index.md` if available and confirm it references `file: memory-system.md`. If the file exists but is unindexed, report the index issue.
3. Read project `.mindlayer/index.md` if available.
4. Check `~/.mindlayer/preferences.md` if available. Load it only when it contains substantive user-written preferences; if it is missing or starter-only, report it as missing or skipped.
5. Always check project `.mindlayer/project.md` for stable project identity, even when the project index marks it low importance or starter-like.
6. If `.mindlayer/project.md` contains only scaffold or placeholder content, do not treat it as substantive memory; report that project identity is missing or still starter-only.
7. If `.mindlayer/project.md` contains substantive project identity, load the relevant identity section and summarize it.
8. Read only the latest useful progress summary from project `.mindlayer/progress.md`.
9. Do not load empty scaffold files by default.
10. Do not load `.mindlayer/local.md` by default.
11. Load scaffold files or `local.md` only when an index marks them as relevant, the user task needs them, or they contain non-placeholder content.
12. Do not load full memory files unless the indexes or current task make them relevant.
13. Do not use `README.md` or `docs/` as memory input.
14. Treat tool adapters such as `AGENTS.md`, `CLAUDE.md`, and Copilot instructions as blocked memory stores; use them only as thin instructions that point to MindLayer.
15. Go outside MindLayer memory only when necessary for the current task.

## Source Boundaries

When initializing inside the MindLayer repo:

- Treat repo `.mindlayer/` as the source of truth for MindLayer product improvement memory.
- Treat live `~/.mindlayer/` as runtime/install/test output; load it only as needed for command rules or current context, and do not treat it as product source of truth.
- Treat `project-template` files as starter placeholders for future users, not product memory.
- Treat `global-template` as the source for shipped default global behavior.

## Token Discipline

Keep token usage small. Always load `~/.mindlayer/memory-system.md`, then prefer index entries, section summaries, substantive preferences, and targeted reads for everything else. Avoid loading full files, empty scaffolds, starter-only preferences, local notes, human docs, and adapter files by default.

Project identity is a bootstrap exception: check `.mindlayer/project.md` during MindLayer boot, but load only substantive identity content. A low-importance starter index entry is not enough reason to skip the check.

## Context Receipt

After loading, produce a concise context receipt:

- Loaded:
- Skipped:
- Missing:
- Current project understanding:
- Current progress:
- Token or word estimate:
- Approximate context share by source when available:
- Token strategy:

Clearly state what was loaded and skipped. Include rough word counts or token estimates when exact token counts are unavailable.

## Future Direction

MindLayer should move toward automatic session-start or tool-preflight boot. Until that path is reliable across hosts, `/m-init` remains a legacy/manual way to refresh or show the current boot receipt.
