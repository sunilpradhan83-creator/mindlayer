# MindLayer Boot

<!-- managed by MindLayer installer — last_updated: YYYY-MM-DD -->

Read this file first at every session start. Then read router.md. Then follow the load triggers.

## Boot Sequence

Run once per session, in order, before answering any request:

1. Read `~/.mindlayer/boot.md` — you are here.
2. Read `~/.mindlayer/router.md` — global load and save triggers.
3. Read `.mindlayer/router.md` — project load triggers. Skip if file does not exist.
4. Read `~/.mindlayer/memory-system/per-turn.md` — always. Controls every response you generate.
5. Read `~/.mindlayer/preferences/personal.md` — only if it contains non-scaffold content (file has real user preferences, not just the starter template).
6. Read project `.mindlayer/index.md` — summary-only boot catalog. Do not load `.mindlayer/index-full.md` at boot; it loads only through `ml load`.
7. Always check project `.mindlayer/project.md` for stable project identity even when the project index marks it low importance or starter-like; report placeholder-only identity as missing. Load even if index marks it low importance; report as missing if placeholder-only.
8. Load project progress and backlog — check `progress.md` and `backlog.md` for current phase and next action.
9. Check `sessions/` — if a recent session file exists, read only the `## Next` section and surface as a one-line cue in the boot receipt.
10. Check onboard status — scan `.mindlayer/index.md` for `id: ml-onboard-complete`. If absent AND `.mindlayer/project.md` contains only placeholder/scaffold content, load `memory-system/commands/onboard.md` and fire the onboard flow on the first project-relevant turn. Surface in boot receipt as: `Onboarding: pending — ml onboard will run on first project-relevant request.`
11. Run memory diff — load `memory-system/commands/diff.md` and compute what changed in `.mindlayer/` since the last session. Surface in boot receipt between `Current progress:` and `Context cost:`. Skip silently if no session file or git unavailable.
12. Run adapter guard — compare known frozen adapter hashes against `.mindlayer/adapters.lock` using canonical templates from `~/.mindlayer/memory-system/templates/`. Complete this guard before answering the first project-relevant request.

Do not treat a plain greeting as a project-relevant request. On the first project-relevant request — including any question about what the project is, what it does, or what is in it — run the full boot sequence and emit the boot receipt BEFORE giving your answer. Never answer a project question without booting first. Never ask the user if they want you to boot — just boot.

## Adapter Guard

Project adapters are frozen files. They are not durable memory stores and must not contain user edits.

Known frozen adapters:
- `AGENTS.md`
- `CLAUDE.md`
- `.github/copilot-instructions.md`
- `GEMINI.md`
- `.cursor/rules/mindlayer.md`
- `.windsurf/rules/mindlayer.md`

At boot, after loading memory and before answering the first project-relevant request:

1. For each known frozen adapter that exists in the project, hash the file.
2. Compare each hash with `.mindlayer/adapters.lock`. A missing lock entry means the adapter is unverified.
3. If all hashes match, proceed silently.
4. If any hash mismatches or has no lock entry, diff the current file against the canonical template in `~/.mindlayer/memory-system/templates/`.
5. If the diff contains user-added content, alert the user, show the diff, and trigger the `ml save` flow to route that content to the correct MindLayer destination. Restore the adapter only after the user approves or skips the memory write.
6. If the mismatch is pure template version drift with no user-added content, restore the canonical adapter silently.
7. After restoring an adapter, update `.mindlayer/adapters.lock` with the new SHA-256 hash.

Never discard user-added adapter content without first routing it through the `ml save` approval flow.

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

Memory changes since last session:
  New:      N entries (<file>)
  Updated:  N entries (<file>)
  Archived: N entries
(omit this block entirely when no changes detected)

Onboarding:
pending — ml onboard will run on first project-relevant request.
(omit this line entirely when ml-onboard-complete is present in the index)

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

`ml init` is a legacy/manual refresh alias for showing or rerunning the boot receipt.
