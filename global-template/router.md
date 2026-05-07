# MindLayer Router

<!-- managed by MindLayer installer — last_updated: YYYY-MM-DD -->

Read this file immediately after boot.md. Then read the project router at `.mindlayer/router.md`. Then follow the load and save triggers below.

## Always Load (every session, before first response)

- `memory-system/per-turn.md` — controls Token Burned block on every response. Load immediately after this file.

## Auto-Load Behavior

Load triggers fire automatically — no approval required for reads. After loading, append a one-line notification before the response:

```text
Loaded: <file.md> — <reason>
```

Load each file at most once per session. Load before acting on the trigger, not after.

## Conditional Loads

| File | Load when | Signal variants |
|---|---|---|
| `memory-system/commands.md` | Any ml * command | ml init, ml retrieve, ml status, ml archive, ml session, ml clean |
| `memory-system/read-write.md` | Any memory write | About to write to .mindlayer/, save trigger fired, reading memory for a task |
| `memory-system/session.md` | Session boundary | done, bye, wrapping up, end session, save session, /compact invoked |
| `memory-system/schema.md` | Structural question | lifecycle statuses, private/, sessions/, cache/, tmp/, token strategy, folder structure |
| `preferences/personal.md` | Every session | Non-scaffold content present |
| `preferences/*.md` | On-demand retrieval | ml retrieve targets cross-project knowledge, or current task needs it |

## Save Triggers

When any signal below is detected, load `memory-system/read-write.md`, then scan the current conversation context for memory candidates. Propose each candidate with destination file, action (new entry or update), and content preview. Require explicit approval before writing.

**Scan criteria — evaluate each candidate against:**
1. Durability: would this matter in a future session starting cold?
2. Non-obviousness: is it derivable from code, git history, or existing memory? If yes, skip.
3. Type match: decision, context, risk, progress, backlog, or preference?
4. Duplicate check: does an existing entry already capture this? Propose an update, not a new entry.

**Scan scope:** current turn output → last completed task → earlier unproposed session context.

**Signal variants:**

| Signal |
|---|
| "ml save" |
| "anything pending to save?", "worth saving?", "should we save anything?", "what should we save?" |
| "remember this", "save this", "add to memory", "capture this", "save that", "log this" |
| "don't want to lose this", "keep this", "preserve this" |

## Failsafe Rules

- Load each file at most once per session.
- When in doubt, load. A missed rule costs more than 400 tokens.
- Never skip `memory-system/per-turn.md`. It controls the Token Burned block on every response.
- Always load `memory-system/read-write.md` BEFORE writing, not after recognizing the need.
- Read the project router (`.mindlayer/router.md`) immediately after this file.
