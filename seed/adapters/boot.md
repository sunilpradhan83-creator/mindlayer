# MindLayer Boot

<!-- managed by MindLayer installer — last_updated: YYYY-MM-DD -->

Compatibility bootstrap for hosts that cannot run `ml boot` directly. The executable `ml boot` / `ml init` command is the bootstrap authority; this markdown exists only as fallback guidance for adapter-driven hosts.

## Boot Sequence

Run once per session before answering the first project-relevant request:

1. Run executable `ml boot` when available. Treat its receipt as authoritative.
2. If `ml boot` is unavailable, fall back to project `.mindlayer/`: read `.mindlayer/index.md` — pointer-only boot catalog. Follow only the first-level subfolder pointers needed for the task; `index-full.md` is deprecated.
3. Read `.mindlayer/router.md` when present for project load triggers.
4. Always check project `.mindlayer/knowledge/project.md` for stable project identity even when the project index marks it low importance or starter-like; report placeholder-only identity as missing. Load even if index marks it low importance; report as missing if placeholder-only.
5. Load current project progress from `.mindlayer/work/current.md`; if absent, fall back to legacy progress/backlog locations.
6. Check `.mindlayer/work/sessions/` — if a recent session file exists, read only the `## Next` section and surface as a one-line cue in the boot receipt.
7. Check `~/.mindlayer/preferences/personal.md` only if it exists and contains non-scaffold user preferences.
8. Check onboard status — scan `.mindlayer/index.md` for `id: ml-onboard-complete`. If absent AND `.mindlayer/knowledge/project.md` contains only placeholder/scaffold content, run `ml onboard` or follow the onboard flow on the first project-relevant turn. Surface in boot receipt as: `Onboarding: pending — ml onboard will run on first project-relevant request.`
9. Run memory diff through `ml diff` / executable boot behavior when available; otherwise compute what changed in `.mindlayer/` since the last session and surface it between `Current progress:` and `Context cost:`. Skip silently if no session file or git unavailable.
10. Run adapter guard through executable runtime when available. If unavailable, compare known frozen adapter hashes against `.mindlayer/adapters.lock` using installed canonical adapter templates. Complete this guard before answering the first project-relevant request.

Do not treat a plain greeting as a project-relevant request. On the first project-relevant request — including any question about what the project is, what it does, or what is in it — run this bootstrap and emit the boot receipt BEFORE giving your answer. Never answer a project question without booting first. Never ask the user if they want you to boot — just boot.

Legacy global `~/.mindlayer/boot.md`, `~/.mindlayer/router.md`, and `~/.mindlayer/memory-system/` files may be encountered from older installs. They are non-canonical migration artifacts and installs prune them because executable `ml` runtime is authoritative.

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
4. If any hash mismatches or has no lock entry, diff the current file against the installed canonical adapter template.
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
Executable boot: project index, project identity, current work, substantive preferences, and latest session cue only.

Ready.
What would you like to work on?
```
