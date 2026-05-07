# Commands Index

<!-- managed by MindLayer installer — last_updated: YYYY-MM-DD -->

Load this file when any `ml *` command fires. Read it first, then load the spec file for the specific command invoked.

## Command Map

| Command | Spec file | When to load |
|---|---|---|
| `ml init` | `commands/init.md` | `ml init` invoked, or boot receipt requested |
| `ml retrieve <query>` | `commands/retrieve.md` | `ml retrieve`, "load X", "what do we know about X" |
| `ml save` | `commands/save.md` | `ml save`, "remember this", "save this", "add to memory" |
| `ml status` | `commands/status.md` | `ml status`, "mstatus", "memory status", "what's loaded" |
| `ml archive` | `commands/archive.md` | `ml archive`, `ml clean`, "clean memory", "forget X", "tidy memory" |
| `ml session` | `commands/session.md` | `ml session`, "msession", "how much context", "start fresh" |
| `ml onboard` | `commands/onboard.md` | First project-relevant turn post-install when `.mindlayer/` is empty or starter-only |
| *(internal)* | `commands/diff.md` | Boot step 11 and `ml status` — not user-invocable directly |

## Rules

- Load the spec file for the invoked command immediately after this file.
- Never load all spec files at once — load only the one needed.
- `ml clean` is an alias for `ml archive`.
- `ml init` is a legacy/manual refresh alias for running the boot receipt.
