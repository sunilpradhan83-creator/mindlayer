# /m-init

Initialize this AI session with minimal useful MindLayer memory context.

## Procedure

1. Read `~/.mindlayer/memory-system.md` first if available. If missing, use project `.mindlayer/` files and note the missing global system file.
2. Read `~/.mindlayer/preferences.md` if available as always-on global preference context.
3. Read `~/.mindlayer/index.md` if available.
4. Read project `.mindlayer/index.md` if available.
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

## Token Discipline

Keep token usage small. Always load `preferences.md`, then prefer index entries, section summaries, and targeted reads for everything else. Avoid loading full files, empty scaffolds, local notes, human docs, and adapter files by default.

Project identity is a bootstrap exception: check `.mindlayer/project.md` during `/m-init`, but load only substantive identity content. A low-importance starter index entry is not enough reason to skip the check.

## Report

After loading, produce a concise context report:

- Loaded:
- Skipped:
- Missing:
- Current project understanding:
- Current progress:
- Token strategy:

Clearly state what was loaded and skipped.
