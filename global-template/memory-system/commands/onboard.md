# ml onboard

<!-- managed by MindLayer installer — last_updated: YYYY-MM-DD -->

One-time onboarding flow for projects installed on an existing codebase. Guides the user through three phases: adapter conflict migration, inline memory extraction, and project context population. One change at a time, with reason and explicit approval before each write or edit.

## Trigger

Fire automatically on the first project-relevant turn after install when `.mindlayer/` files are all starter-only (no real content written yet). Do not fire on greeting-only turns. Do not fire more than once — once the onboard-complete flag is set, skip this command permanently.

Check `.mindlayer/index.md` for `id: ml-onboard-complete` before firing. If present, skip entirely.

## Completion Flag

When onboarding completes (or when the user explicitly stops it), write a single entry to `.mindlayer/index.md`:

```yaml
- id: ml-onboard-complete
  title: Onboarding Complete
  file: index.md
  section: Entries
  scope: project
  type: onboarding
  tags: [onboarding]
  summary: ml onboard completed. One-time flow done — this command will not fire again.
  importance: low
  status: complete
  last_updated: YYYY-MM-DD
```

Write this flag even if the user says 'stop' mid-flow, so the flow does not re-trigger.

## Phase 1 — Adapter Conflict Migration

Scan all adapter files for content that conflicts with MindLayer behavior. Read and reason about each file — do not keyword-match.

### Files to scan

**Project-level:**
- `AGENTS.md`
- `CLAUDE.md`
- `.github/copilot-instructions.md`

**Global-level:**
- `~/.claude/CLAUDE.md` (Claude global config)
- Any other global adapter files present

### What counts as a conflict

- Boot instructions that contradict MindLayer (e.g. "always load README.md", "load docs/ at startup", "never use external memory files")
- Inline memory stores — rules, decisions, preferences, context written directly in the adapter that belong in `.mindlayer/` or `~/.mindlayer/`
- Duplicate boot sequences that would run alongside MindLayer boot and cause redundant or conflicting loads
- Instructions to write memory into the adapter file itself

Harmless existing rules (project-specific coding standards, formatting preferences, tool configs) are not conflicts — leave them untouched.

### Proposal format

For each conflict found, propose one change at a time:

```text
Onboarding — adapter conflict:
File: <adapter file path>
Found: "<conflicting content>"
Conflict: <why this conflicts with MindLayer>

Proposed changes:
1. Adapter edit — remove or rephrase:
   Before: "<original line(s)>"
   After:  "<replacement or [remove]>"

2. Migrate to MindLayer — (only when content has durable value):
   Destination: <~/.mindlayer/preferences/personal.md | .mindlayer/decisions.md | etc.>
   Content: <proposed memory entry>
   Scope: global | project

Say 'apply' to make both changes, 'adapter only' to edit the adapter without saving to MindLayer, 'skip' to leave this conflict as-is, or 'stop' to end onboarding.
```

If the conflict has no durable value worth migrating (e.g. a redundant boot instruction), omit item 2 and propose only the adapter edit.

### Approval rules

- `apply`, `go`, `approved` — execute both the adapter edit and the MindLayer write.
- `adapter only` — edit the adapter, skip the MindLayer write.
- `skip` — leave this conflict untouched, move to next.
- `stop` — end onboarding, write completion flag.

Never batch multiple conflicts into one proposal. One conflict per turn.

## Phase 2 — Inline Memory Extraction

After all conflicts are resolved, scan adapter files for durable content that belongs in `.mindlayer/` but is not a conflict — content that would be useful memory even if MindLayer weren't installed.

Examples: recurring workflow preferences, engineering principles, project-specific decisions written inline.

Use the same reasoning as `ml save`. Propose each candidate:

```text
Onboarding — memory candidate:
Found in: <file>
Content: "<inline content>"
Reason: <why this belongs in MindLayer memory>

Proposed write:
- Destination: <file.md>
- Scope: global | project
- Type: preference | decision | context | principle | playbook

Say 'save' to migrate, 'skip' to leave in adapter only, or 'stop' to end onboarding.
```

Do not remove content from the adapter during this phase — extraction only. The adapter edit (if desired) is a separate follow-up.

## Phase 3 — Project Context Population

After adapter work is complete, scan existing project context for durable facts worth saving to `.mindlayer/`:

- `README.md` — project identity, goals, stack
- `docs/` — architecture, design decisions, API references
- Key source files — infer tech stack, main modules, patterns

This is the only context where `README.md` and `docs/` are valid input sources — for seeding `.mindlayer/` with real content.

Propose one entry at a time:

```text
Onboarding — project context:
Source: <README.md | docs/arch.md | ...>
Found: <summary of context>

Proposed write:
- File: .mindlayer/<target>.md
- Section: <heading>
- Content: <proposed content>
- Reason: <why this is worth saving>

Say 'save', 'skip', or 'stop'.
```

Route correctly: project identity → `project.md`, decisions → `decisions.md`, progress → `progress.md`, risks → `risks.md`, context → `context.md`, backlog ideas → `backlog.md`. Update `.mindlayer/index.md` for every approved write.

## Rules

- One proposal per turn. Never batch.
- Never write or edit without explicit approval. `apply`, `save`, `go`, `approved` count. `ok`, `sure`, `yes` do not count unless clearly approving the specific proposed change.
- Do not re-propose entries the user has skipped in this session.
- If `.mindlayer/project.md` already has non-placeholder content when this command fires, skip Phase 3 entirely — treat project context as already populated.
- Write the completion flag after all phases complete or when user says 'stop'.
