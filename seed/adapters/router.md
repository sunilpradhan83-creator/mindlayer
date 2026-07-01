# MindLayer Router

<!-- managed by MindLayer installer — last_updated: YYYY-MM-DD -->

Compatibility routing hints for hosts that cannot delegate to executable `ml` commands. Prefer `ml boot`, `ml load`, `ml save`, `ml status`, `ml session`, and `ml clean`; use this file only as fallback guidance.

## Always Load

- Project `.mindlayer/index.md`, project identity, and current work during fallback boot.

## Announce Loads

```text
Loaded: <file.md> — <reason>
```

## Conditional Loads

| Executable command | Use when | Signals |
|---|---|---|
| `ml boot` / `ml init` | Init or boot receipt | ml boot, ml init, first project-relevant request |
| `ml load` / `ml retrieve` + project `.mindlayer/index.md` tree | Memory load | ml load/retrieve, load/retrieve X, what do we know about X |
| `ml save` | Save trigger | ml save, remember/save/add/capture/log/keep/preserve this |
| `ml status` | Status | ml status, mstatus, memory status, what's loaded |
| `ml clean` | Memory cleanup | ml clean, clean/tidy/forget/remove memory |
| `ml session` | Session boundary/status | ml session, msession, how much context, start fresh, done, bye, wrapping up, end/save session, /compact |
| `ml onboard` | Onboarding incomplete | no `ml-onboard-complete` + placeholder project.md |
| `preferences/personal.md` | Every session | Non-scaffold content present |
| `preferences/*.md` | On-demand memory loading | ml load targets cross-project knowledge, or current task needs it |

## Save Rules

On save triggers, prefer executable `ml save`. If unavailable, scan current turn -> last completed task -> earlier unproposed context. Propose exact destination/content and require explicit approval. Skip facts derivable from code/git/existing memory.

## Routing

- Global preferences/workflows -> `~/.mindlayer/preferences/`.
- Project identity/progress/decisions/context/backlog/risks -> project `.mindlayer/`.
- Never mirror global memory into project memory.
- Roadmap vision -> `roadmap.md`; near-term tasks -> `backlog.md`.
- Private/session/cache/tmp/local material stays out of committed memory.
- In this repo, `.mindlayer/` is product memory; live `~/.mindlayer/` is runtime/install/test output.

## Failsafes

When in doubt, use the executable `ml` command. If no executable is available, load the smallest relevant `.mindlayer/` project memory and require explicit approval before any memory write.
