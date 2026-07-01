# Commands Index

<!-- managed by MindLayer installer — last_updated: YYYY-MM-DD -->

Load this file when any `ml *` command fires. Read it first, then load the spec file for the specific command invoked.

## Command Map

| Command | Spec file | When to load |
|---|---|---|
| `ml boot` | `commands/init.md` | `ml boot` invoked, or boot receipt requested |
| `ml init` | `commands/init.md` | `ml init` invoked as a legacy alias |
| `ml load <query>` | `commands/load.md` | `ml load`, `ml retrieve`, "load X", "retrieve X", "what do we know about X" |
| `ml save` | `commands/save.md` | `ml save`, "remember this", "save this", "add to memory" |
| `ml status` | `commands/status.md` | `ml status`, "mstatus", "memory status", "what's loaded" |
| `ml clean` | `commands/archive.md` | `ml clean`, "clean memory", "forget X", "tidy memory" |
| `ml session` | `commands/session.md` | `ml session`, "msession", "how much context", "start fresh" |
| `ml onboard` | `commands/onboard.md` | First project-relevant turn post-install when `.mindlayer/` is empty or starter-only |
| *(internal)* | `commands/diff.md` | Boot step 11 and `ml status` — not user-invocable directly |

## Rules

- Load the spec file for the invoked command immediately after this file.
- Never load all spec files at once — load only the one needed.
- `ml clean` is the public cleanup command. Archive/delete are internal actions behind approval.
- `ml boot` is the manual boot receipt command.
- `ml init` is a legacy/manual refresh alias for `ml boot`.
