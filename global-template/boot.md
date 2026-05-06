# MindLayer Boot

<!-- managed by MindLayer installer — last_updated: YYYY-MM-DD -->

Read this file first at every session start. Then read router.md. Then follow the load triggers.

## Boot Sequence

Run once per session, in order, before answering any request:

1. Read `~/.mindlayer/boot.md` — you are here.
2. Read `~/.mindlayer/router.md` — global load and save triggers.
3. Read `.mindlayer/router.md` — project load triggers. Skip if file does not exist.
4. Read `~/.mindlayer/memory-system/per-turn.md` — always. Controls every response you generate.
4. Read `~/.mindlayer/preferences/personal.md` — only if it contains non-scaffold content (file has real user preferences, not just the starter template).
5. Read project `.mindlayer/index.md` — catalog of project memory.
6. Always check project `.mindlayer/project.md` for stable project identity even when the project index marks it low importance or starter-like; report placeholder-only identity as missing. Load even if index marks it low importance; report as missing if placeholder-only.
7. Load project progress and backlog — check `progress.md` and `backlog.md` for current phase and next action.
8. Check `sessions/` — if a recent session file exists, read only the `## Next` section and surface as a one-line cue in the boot receipt.

Do not treat a plain greeting as a project-relevant request. If boot has not run, answer naturally and boot before the first project-relevant request.

## Boot Receipt Format

When boot is visible to the user, output this exact format:

```text
MindLayer context loaded.

Loaded:
- ...

Skipped:
- ...

Missing:
- ...

Current understanding:
...

Current progress:
...

Context cost:
Approx. N words loaded (~N est. tokens).

Context share (approximate context share by source):
- Global memory: ~N%
- Project memory: ~N%
- Other sources: 0% (README.md, docs/, and adapters skipped)

Token strategy:
L0 boot: boot.md, router.md, per-turn.md, indexes, project identity, and latest progress only.

Ready.
What would you like to work on?
```

`/m-init` is a legacy/manual refresh alias for showing or rerunning the boot receipt.
