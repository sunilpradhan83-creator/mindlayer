# MindLayer Router

<!-- managed by MindLayer installer — last_updated: YYYY-MM-DD -->

Read after `boot.md`, then read project `.mindlayer/router.md`. Load triggers fire automatically, once per session, before acting.

## Always Load

- `memory-system/per-turn.md` — Token Burned core.

## Announce Loads

```text
Loaded: <file.md> — <reason>
```

## Conditional Loads

| File | Load when | Signals |
|---|---|---|
| `memory-system/commands/index.md` | Any ml command | ml init/load/retrieve/save/status/archive/session/clean/onboard |
| `memory-system/commands/init.md` | Init or boot receipt | ml init |
| `memory-system/commands/load.md` + project `.mindlayer/index-full.md` | Memory load | ml load/retrieve, load/retrieve X, what do we know about X |
| `memory-system/commands/save.md` | Save trigger | ml save, remember/save/add/capture/log/keep/preserve this |
| `memory-system/commands/status.md` | Status | ml status, mstatus, memory status, what's loaded |
| `memory-system/commands/archive.md` | Archive/clean | ml archive/clean, clean/tidy/archive/forget/remove memory |
| `memory-system/commands/session.md` | Session boundary/status | ml session, msession, how much context, start fresh, done, bye, wrapping up, end/save session, /compact |
| `memory-system/commands/onboard.md` | Onboarding incomplete | no `ml-onboard-complete` + placeholder project.md |
| `memory-system/commands/diff.md` | Boot step 11 or status | boot diff, status diff |
| `memory-system/per-turn/load-announce.md` | Any file load | boot receipt, command spec, project memory |
| `memory-system/per-turn/memory-candidate.md` | Save trigger or candidate | decision, risk, progress, context, backlog, preference, pending candidate |
| `memory-system/per-turn/retrieval.md` | Relevant unloaded memory | index match |
| `memory-system/per-turn/lateral-intent.md` | Out-of-plan work | outside Next Step/backlog, scope change |
| `memory-system/per-turn/session-warning.md` | Heavy/critical context | 60-80%, >80% |
| `memory-system/per-turn/pre-push.md` | Push | push, git push, publish |
| `memory-system/per-turn/post-write.md` | Approved memory write | post-write size check |
| `memory-system/read-write.md` | Any memory write | before writing `.mindlayer/` or reading memory |
| `memory-system/schema.md` | Structure | lifecycle, private/sessions/cache/tmp, tokens, folders |
| `preferences/personal.md` | Every session | Non-scaffold content present |
| `preferences/*.md` | On-demand memory loading | ml load targets cross-project knowledge, or current task needs it |

## Save Rules

On save triggers, load `commands/save.md`, scan current turn -> last completed task -> earlier unproposed context. Propose exact destination/content and require explicit approval. Skip facts derivable from code/git/existing memory.

## Routing

- Global preferences/workflows -> `~/.mindlayer/preferences/`.
- Project identity/progress/decisions/context/backlog/risks -> project `.mindlayer/`.
- Never mirror global memory into project memory.
- Roadmap vision -> `roadmap.md`; near-term tasks -> `backlog.md`.
- Private/session/cache/tmp/local material stays out of committed memory.
- In this repo, `.mindlayer/` is product memory; live `~/.mindlayer/` is runtime/install/test output.

## Failsafes

When in doubt, load. Never skip `per-turn.md`. Load `read-write.md` before any write. Read project router immediately after this file.
