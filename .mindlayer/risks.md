# Risks

Known risks, blockers, fragile areas, and trust concerns.

## V1 Trust and Quality Risks

id: ml-20260430-006
created: 2026-04-30
updated: 2026-05-05
scope: project
type: risk
tags: [trust, tokens, installer, onboarding]
confidence: high
status: active
source: manual

### Summary
MindLayer must stay safe, compact, and trustworthy across all install scenarios.

### Details
- Token bloat: too much memory loaded at boot hurts efficiency. Keep L0 minimal.
- Wrong routing: agents writing durable memory to adapters instead of `.mindlayer/` files breaks the source boundary.
- Installer safety: destructive behavior on reinstall would destroy user work.
- Scaffold false confidence: placeholder files treated as real memory waste tokens and mislead agents.
- Adapter drift: duplicated memory in tool-specific files gets out of sync over time.
- Undiscoverable memory: files that exist but lack index entries are effectively unavailable.
- Existing project onboarding gap: no automated way to populate `.mindlayer/` from existing project knowledge on first install into a mature project. Users must populate manually or with agent assistance.
- Silent behavior change: `memory-system.md` refreshes on reinstall silently change agent behavior without user awareness.

### When to use
Use when changing prompts, installer behavior, adapter content, or planning new install scenarios.

### Related
ml-20260430-003

## Router Enforcement Gap

id: ml-20260507-003
created: 2026-05-07
updated: 2026-05-07
scope: project
type: risk
tags: [router, enforcement, agent-behavior, trust, skills]
confidence: high
status: active
source: manual

### Summary
The MindLayer router is a memory document, not an execution engine. All trigger-based rules depend on the agent recognizing a signal and choosing to act — there is no runtime process enforcing them.

### Details
- When an `ml *` command or skill fires, no external process loads `decisions.md` or any other file. The agent decides, based on what it remembers from boot.
- If boot context has drifted, the session is long, or a new session did not boot correctly, router rules may silently fail to fire.
- The Skill Approval Gate (ml-20260507-002) is particularly vulnerable: by the time the agent recognizes `ml init` as a trigger, the skill may already be executing.
- The `commands.md` pointer and project router trigger are soft contracts — instructions to the agent, not hard guards.

### Mitigation (current)
- `memory-system/commands.md` carries a one-line pointer to the Skill Approval Gate at the exact moment `ml *` commands are recognized.
- Project router now lists all `ml *` commands as triggers for `decisions.md`.
- Both are best-effort — they improve reliability but do not guarantee enforcement.

### Mitigation (future)
- `ml script` command (V4): structured command runner with approval gates built into the execution flow, agent-agnostic. Works across Claude, Codex, Cursor, Copilot, and any LLM tool.

### When to use
Use when evaluating trust guarantees of router-based rules, planning hook-based enforcement, or assessing whether a new rule needs hard enforcement vs soft instruction.

### Related
ml-20260507-002
ml-20260430-006

## Per-Turn Behavioral Contract Compliance

id: ml-20260507-006
created: 2026-05-07
updated: 2026-05-07
scope: project
type: risk
tags: [per-turn, enforcement, agent-behavior, load-announcement, memory-candidate, retrieval, trust]
confidence: high
status: active
source: manual

### Summary
The three core per-turn contracts — load announcement, memory candidate surfacing, and index-driven retrieval suggestions — are instruction-based, not runtime-enforced. An agent that boots correctly may still fail to execute them mid-session.

### Details
- **Load announcement failure**: agent loads a file mid-session without announcing it. User cannot tell what context is active. Memory decisions are made on invisible context.
- **Memory candidate miss**: durable content produced during a turn is not surfaced. User must explicitly invoke `ml save` at session end, by which point earlier candidates may be forgotten or imprecise.
- **Retrieval miss**: relevant indexed memory exists but is never suggested. Agent operates on incomplete context without the user knowing.
- All three failures are silent — no error, no warning. The user simply doesn't know they happened.
- Root cause: per-turn rules are behavioral instructions, not executable contracts. Agent attention drift, long sessions, and noisy context all increase failure probability.

### Mitigation (current)
- `per-turn.md` now owns all three contracts as explicit rules with formats and checklists (not vague guidance).
- `tests/agent-behavior/test-per-turn.sh` — 61 deterministic contract tests covering happy paths, violations, and edge cases. Run via `tools/test.sh`.
- Router.md simplified — announcement format ownership consolidated into per-turn.md to eliminate rule fragmentation.

### Mitigation (future)
- Live dogfood runs: periodically run a real agent session against the test scenarios and verify output manually.
- `ml script` (V4): structured command runner with gates that enforce per-turn contracts as execution steps, not just instructions.

### When to use
Use when evaluating whether a per-turn behavioral change is actually working, planning dogfood sessions, or deciding whether a new rule needs stronger enforcement than per-turn.md can provide.

### Related
ml-20260507-003
ml-20260430-006

## Instruction-Only Architecture Ceiling

id: ml-20260508-001
created: 2026-05-08
updated: 2026-05-08
scope: project
type: risk
tags: [architecture, v4, command-runner, enforcement, markdown, runtime]
confidence: high
status: active
source: conversation

### Summary
MindLayer has reached the architectural ceiling of instruction-only contracts. V4 should prioritize a deterministic local `ml` command runner while keeping markdown as the durable memory store.

### Details
- Current boot, router, load, save, status, and per-turn behavior are mostly markdown instructions interpreted by agents.
- Contract tests validate expected transcript shapes and specs, but they do not enforce actual agent execution paths.
- This was a good V1-V3 bootstrap, but it leaves trust-critical behavior dependent on agent compliance.
- The preferred next architecture is: markdown files as storage, indexes as discoverability, a local `ml` runtime as deterministic control plane, adapters as thin bootstrappers, and agents as reasoning layer.
- Start V4 with read-only commands (`ml boot`, `ml load`, `ml status`, `ml diff`, `ml session`) before guarded write flows.

### When to use
Use when prioritizing V4 work, evaluating whether a behavior belongs in instructions or runtime, or deciding whether a new trust-critical contract needs executable enforcement.

### Related
ml-20260507-003
ml-20260507-006
ml-20260505-003

## Adapter Boot Wording Drift

id: ml-20260511-001
created: 2026-05-11
updated: 2026-05-11
scope: project
type: risk
tags: [adapters, boot, non-interactive, trust, drift]
confidence: high
status: archived
source: conversation

### Summary
Shipped adapter wording may still be softer than the recorded non-interactive boot fix requires, allowing agents to answer project questions before running MindLayer boot.

### Details
- `AGENTS.md` currently says to run boot before answering the first project-relevant request, but the recorded root-cause fix requires harder wording: never answer a project question without booting first, never ask permission, just boot.
- This matters most in headless or non-interactive agent runs where ambiguous instructions can be treated as optional or deferrable.
- `CLAUDE.md` correctly delegates to `AGENTS.md`, so ambiguity in `AGENTS.md` propagates to tool-specific adapters.
- Recommended mitigation: tighten the adapter template wording and add a contract test that asserts the hard boot language is present in installed adapters.

### When to use
Use when editing adapter templates, debugging boot receipt failures, or adding tests for non-interactive agent behavior.

### Related
ml-20260510-003
ml-20260430-006
ml-20260507-003
