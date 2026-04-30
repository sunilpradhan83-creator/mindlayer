# /m-init

Initialize this AI session with minimal useful MindLayer memory context.

## Procedure

1. Read `~/.mindlayer/memory-system.md` first if available. If missing, use project `.mindlayer/` files and note the missing global system file.
2. Read `~/.mindlayer/index.md` if available.
3. Read project `.mindlayer/index.md` if available.
4. Read project `.mindlayer/project.md` for stable project identity.
5. Read only the latest useful progress summary from project `.mindlayer/progress.md`.
6. Do not load empty scaffold files by default.
7. Do not load `.mindlayer/local.md` by default.
8. Load scaffold files or `local.md` only when an index marks them as relevant, the user task needs them, or they contain non-placeholder content.
9. Do not load full memory files unless the indexes or current task make them relevant.
10. Do not use `README.md` as memory input.

## Token Discipline

Keep token usage small. Prefer index entries, section summaries, and targeted reads. Avoid loading full files, empty scaffolds, and local notes by default.

## Report

After loading, produce a concise context report:

- Loaded:
- Skipped:
- Missing:
- Current project understanding:
- Current progress:
- Token strategy:

Clearly state what was loaded and skipped.
