# MindLayer Boot

Initialize this AI session with minimal useful MindLayer memory context and report a transparent context receipt when visible to the user.

`/m-init` is a legacy/manual refresh alias for this boot procedure. The primary path is automatic session-start or tool-preflight boot when the host supports it, with first project-relevant request boot as the fallback.

## Procedure

1. Read `~/.mindlayer/boot.md` first if available. If missing, fall back to project `.mindlayer/` files and note the missing global boot file.
2. Read `~/.mindlayer/router.md` and follow its load triggers for the current session.
3. Read `~/.mindlayer/memory-system/per-turn.md` — always load, controls every response.
4. Read `~/.mindlayer/index.md` if available.
5. Read project `.mindlayer/index.md` if available.
6. Check `~/.mindlayer/preferences/personal.md` if available. Load it only when it contains substantive user-written preferences; if it is missing or starter-only, report it as skipped.
7. Always check project `.mindlayer/project.md` for stable project identity, even when the project index marks it low importance or starter-like.
8. If `.mindlayer/project.md` contains only scaffold or placeholder content, report that project identity is missing or still starter-only.
9. Read only the latest useful progress summary from project `.mindlayer/progress.md`.
10. Do not load empty scaffold files by default.
11. Do not load `.mindlayer/local.md` by default.
12. Do not use `README.md` or `docs/` as memory input.
13. Treat tool adapters as thin instructions only — not memory stores.
14. Go outside MindLayer memory only when necessary for the current task.

## Source Boundaries

When initializing inside the MindLayer repo:

- Treat repo `.mindlayer/` as the source of truth for MindLayer product improvement memory.
- Treat live `~/.mindlayer/` as runtime/install/test output; load it only as needed for current context.
- Treat `project-template` files as starter placeholders for future users, not product memory.
- Treat `global-template` as the source for shipped default global behavior.

## Token Discipline

Keep token usage small. Always load `~/.mindlayer/boot.md` and `router.md` first (~350 tokens), then `memory-system/per-turn.md` (~600 tokens). Prefer index entries, section summaries, and targeted reads for everything else. Avoid loading full files, empty scaffolds, starter-only preferences, local notes, human docs, and adapter files by default.

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

When exact host usage is unavailable, estimate tokens as words multiplied by roughly 1.3 or characters divided by roughly 4.

## Automatic Boot Contract

MindLayer-aware adapters should trigger this procedure at session start or tool preflight when possible. If a host cannot run preflight hooks, run it before the first project-relevant request. A plain greeting is not project-relevant.

`/m-init` is a legacy/manual refresh alias for showing or rerunning the boot receipt.
