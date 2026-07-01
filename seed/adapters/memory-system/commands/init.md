# ml boot

<!-- managed by MindLayer installer — last_updated: YYYY-MM-DD -->

`ml boot` shows or reruns the MindLayer boot receipt. The executable command is the bootstrap authority; automatic session-start or tool-preflight boot should delegate to it when possible.

`ml init` is a legacy/manual refresh alias for `ml boot`.

## Procedure

1. Run executable `ml boot` when available and treat its receipt as authoritative.
2. If the executable is unavailable, fall back to direct project `.mindlayer/` reads.
3. Read project `.mindlayer/index.md` if available.
4. Read `.mindlayer/router.md` if available for project load triggers.
5. Check `~/.mindlayer/preferences/personal.md` if available. Load only when it contains substantive user-written preferences; if missing or starter-only, report as skipped.
6. Always check project `.mindlayer/knowledge/project.md` for stable project identity, even when the project index marks it low importance or starter-like.
7. If `.mindlayer/knowledge/project.md` contains only scaffold or placeholder content, report that project identity is missing or still starter-only.
8. Read only the latest useful progress summary from project `.mindlayer/work/current.md`; if absent, fall back to legacy progress/backlog paths.
9. Do not load empty scaffold files by default.
10. Do not load `.mindlayer/local.md` by default.
11. Do not use `README.md` or `docs/` as memory input.
12. Treat tool adapters as thin instructions only — not memory stores.
13. Go outside MindLayer memory only when necessary for the current task.

## Source Boundaries

When initializing inside the MindLayer repo:

- Treat repo `.mindlayer/` as the source of truth for MindLayer product improvement memory.
- Treat live `~/.mindlayer/` as runtime/install/test output; load it only as needed for current context.
- Treat `seed/project` files as starter placeholders for future users, not product memory.
- Treat `seed/adapters` as the source for shipped default global behavior.

## Token Discipline

Keep token usage small. Prefer executable `ml boot`. During direct fallback, prefer index entries, section summaries, and targeted project reads. Avoid loading global runtime markdown, full files, empty scaffolds, starter-only preferences, local notes, human docs, and adapter files by default.

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

MindLayer-aware adapters should trigger executable `ml boot` at session start or tool preflight when possible. If a host cannot run preflight hooks, run it before the first project-relevant request. If the executable is unavailable, use the direct `.mindlayer/` fallback above. A plain greeting is not project-relevant.

`ml boot` is the manual command for showing or rerunning the boot receipt. `ml init` is a legacy alias.
