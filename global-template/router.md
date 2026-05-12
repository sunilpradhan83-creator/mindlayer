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
| `memory-system/commands/index.md` | Any ml * command fires | ml init, ml load, ml retrieve, ml save, ml status, ml archive, ml session, ml clean, ml onboard |
| `memory-system/commands/init.md` | ml init invoked or boot receipt requested | ml init |
| `memory-system/commands/load.md` + project `.mindlayer/index-full.md` | ml load invoked | ml load, ml retrieve, "load X", "retrieve X", "what do we know about X" |
| `memory-system/commands/save.md` | ml save invoked or save trigger fires | ml save, "remember this", "save this", "add to memory", "capture this" |
| `memory-system/commands/status.md` | ml status invoked | ml status, "mstatus", "memory status", "what's loaded" |
| `memory-system/commands/archive.md` | ml archive invoked | ml archive, ml clean, "clean memory", "forget X", "tidy memory", "archive memory" |
| `memory-system/commands/session.md` | ml session invoked or session boundary | ml session, "msession", "how much context", "start fresh", "done", "bye", "wrapping up", "end session", "save session", /compact invoked |
| `memory-system/commands/onboard.md` | First project-relevant turn when onboard not yet complete | `.mindlayer/index.md` does NOT contain `id: ml-onboard-complete` AND `.mindlayer/project.md` contains only placeholder/scaffold content (no real user-written entries) |
| `memory-system/commands/diff.md` | Boot step 11, or ml status invoked | Always at boot after sessions/ check; also when `ml status` fires |
| `memory-system/per-turn/load-announce.md` | Any file load this session | boot receipt rendering, conditional memory load, command spec load, project memory load |
| `memory-system/per-turn/memory-candidate.md` | Save trigger or durable end-of-turn candidate detected | decision made, risk identified, progress completed, context learned, backlog changed, preference observed, pending candidate |
| `memory-system/per-turn/retrieval.md` | Relevant unloaded index entry found | index scan match, "relevant memory not loaded", task topic matches unloaded memory |
| `memory-system/per-turn/lateral-intent.md` | Out-of-plan work introduced | outside current Next Step, outside active backlog, new recurring task, scope change |
| `memory-system/per-turn/session-warning.md` | Context heavy or critical | 60-80% context, >80% context, heavy session, critical session |
| `memory-system/per-turn/pre-push.md` | Push surfaced or requested | push, git push, publish changes, Next Step is push |
| `memory-system/per-turn/post-write.md` | Approved memory write completed | memory write completed, post-write size check, written file near limit, written file over limit |
| `memory-system/read-write.md` | Any memory write | About to write to .mindlayer/, save trigger fired, reading memory for a task |
| `memory-system/schema.md` | Structural question | lifecycle statuses, private/, sessions/, cache/, tmp/, token strategy, folder structure |
| `preferences/personal.md` | Every session | Non-scaffold content present |
| `preferences/*.md` | On-demand memory loading | ml load targets cross-project knowledge, or current task needs it |

## Save Triggers

When any signal below is detected, load `memory-system/commands/save.md`, then scan the current conversation context for memory candidates. Propose each candidate with destination file, action (new entry or update), and content preview. Require explicit approval before writing.

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

## Routing Rules

- User-owned cross-project preferences belong in `~/.mindlayer/preferences/personal.md`.
- Cross-project workflows, principles, anti-patterns, and prompt templates belong in `~/.mindlayer/preferences/`.
- Project identity, progress, decisions, context, backlog, and risks belong in `project/.mindlayer/`.
- Do not mirror global memory into `project/.mindlayer/`; read and write it directly from `~/.mindlayer/`.
- Preferences may customize collaboration style, workflow habits, and cross-project defaults, but must not override MindLayer guardrails in the `memory-system/` rules.
- Long-term versioned product vision belongs in `.mindlayer/roadmap.md`; near-term tracked tasks belong in `.mindlayer/backlog.md`. Do not mix them.
- Private, local, session, cache, and temporary material must stay out of committed project memory.
- When developing MindLayer itself, treat repo `.mindlayer/` as the product-memory source of truth and treat live `~/.mindlayer/` as runtime, install, or test output rather than product memory.
- When a user installs MindLayer on an existing project with rich context in README, docs, or other files, auto-trigger `ml onboard` on the first project-relevant turn.

## Failsafe Rules

- Load each file at most once per session.
- When in doubt, load. A missed rule costs more than 400 tokens.
- Never skip `memory-system/per-turn.md`. It controls the Token Burned block on every response.
- Always load `memory-system/read-write.md` BEFORE writing, not after recognizing the need.
- Read the project router (`.mindlayer/router.md`) immediately after this file.
