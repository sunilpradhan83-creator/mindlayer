# MindLayer Router

<!-- managed by MindLayer installer — last_updated: YYYY-MM-DD -->

Read this file immediately after boot.md. Then follow the load table below.

## Always Load (every session, before first response)

- `memory-system/per-turn.md` — controls Token Burned block on every response. Load immediately after this file.

## Conditional Loads

Load each file at most once per session. Load before acting on the trigger — not after.

| File | Load before | Exact signal |
|---|---|---|
| `memory-system/commands.md` | Executing any command | User message contains: /m-init /m-save /m-retrieve /m-status /m-archive /m-session /m-clean |
| `memory-system/read-write.md` | Any memory operation | About to write to .mindlayer/, proposing /m-save, or reading memory for a task |
| `memory-system/session.md` | Session boundary action | User says: done / bye / wrapping up / end session / save session — or /compact invoked |
| `memory-system/schema.md` | Structural question | User asks about: lifecycle statuses, private/ sessions/ cache/ tmp/, or token strategy |
| `preferences/personal.md` | Every session | Non-scaffold content present (file contains real user preferences) |
| `preferences/*.md` | On-demand retrieval | /m-retrieve targets cross-project knowledge, or current task clearly needs it |

## Failsafe Rules

- Load each file at most once per session.
- When in doubt, load. A missed rule costs more than 400 tokens.
- Never skip `memory-system/per-turn.md`. It controls the Token Burned block on every response.
- Always load `memory-system/read-write.md` BEFORE writing, not after recognizing the need.
