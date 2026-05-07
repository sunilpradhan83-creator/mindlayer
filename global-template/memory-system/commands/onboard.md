# ml onboard

<!-- managed by MindLayer installer — last_updated: YYYY-MM-DD -->

One-time onboarding flow for projects installed on an existing codebase. Guides the user through populating `.mindlayer/` from existing project context — one change at a time, with reason and explicit approval before each write.

## Trigger

Fire automatically on the first project-relevant turn after install when `.mindlayer/` files are all starter-only (no real content written yet). Do not fire on greeting-only turns. Do not fire more than once — once the onboard-complete flag is set, skip this command permanently.

## Completion Flag

When onboarding completes (or when the user explicitly skips it), write a single entry to `.mindlayer/index.md`:

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

On every subsequent boot, if this entry exists in `.mindlayer/index.md`, skip `ml onboard` entirely.

## Procedure

1. Scan for existing project context:
   - `README.md` — project identity, goals, stack
   - `docs/` — architecture, design decisions, API references
   - Key source files — infer tech stack, main modules, patterns
   - Existing commits and changelogs — infer recent progress

2. For each piece of durable context found, propose one memory write at a time:

```text
Onboarding: I found context worth saving.

Proposed write:
- File: .mindlayer/<target>.md
- Section: <heading>
- Content: <proposed content>
- Reason: <why this is worth saving>

Say 'save' to write, 'skip' to skip this entry, or 'stop' to end onboarding.
```

3. Wait for explicit approval before writing each entry. Never batch-write without approval.

4. After each approved write, propose the next candidate. Continue until:
   - No more candidates remain, OR
   - User says 'stop' or 'done'

5. Write the onboard-complete flag entry to `.mindlayer/index.md` and report:

```text
Onboarding complete. N entries saved.
Your .mindlayer/ is now populated with project context.
```

## Rules

- One proposal at a time. Never dump multiple proposals in a single turn.
- Never write without explicit approval. `save`, `go`, `approved` count. `ok`, `sure`, `yes` do not count unless clearly approving the specific proposed write.
- Do not re-propose entries the user has skipped in this session.
- Route correctly: project identity → `project.md`, decisions → `decisions.md`, progress → `progress.md`, risks → `risks.md`, context → `context.md`, backlog ideas → `backlog.md`.
- Do not read `README.md` or `docs/` as memory input outside this command. This is the one context where those files are valid sources — for seeding `.mindlayer/` with real content.
- Update `.mindlayer/index.md` for every approved write.
- If the user says 'stop' mid-flow, write the onboard-complete flag anyway so the flow does not re-trigger.

## Skip Condition

If `.mindlayer/project.md` already has non-placeholder content when this command fires, treat onboarding as already done — write the complete flag and return without proposing any writes.
