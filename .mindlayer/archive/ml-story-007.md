---
id: ml-story-007
title: Redefine cut as approved signal processing plan
status: done
proved_by: bash tools/test.sh
proved_at: 2026-05-16
started_from: fc7d351
created: 2026-05-16
parent: ml-signal-20260516-005
agent: any
---

You are changing `ml script cut` from route-first behavior into an approved signal processing plan.

Approved definition:
- Cut is the full editorial pass on raw signals before anything routes anywhere.
- Cut removes ambiguity, merges correlated signals, drops misaligned or non-urgent signals, produces a plan for what remains, makes surviving work refine-ready, and requires human approval before routing.
- No signal routes without passing through complete Cut.
- Human review happens in Plan Mode/conversation before durable memory changes. The agent must present a clear Cut proposal for review; only after explicit approval does the runtime write the approved result to backlog/roadmap and mark the signal.

Current state:
- `ml script cut --signal ... --route backlog|roadmap [--approve]` mainly proposes or appends a route.
- The command name suggests Cut, but the behavior is closer to direct routing.

Start by writing failing CLI contract tests in `tests/ml/test-script.sh` that verify:
- without `--approve`, `ml script cut` prints a clear processing proposal suitable for Plan Mode review and does not mutate files,
- approved Cut requires enough text to explain the plan/reason, not just a route,
- approved Cut marks the source signal as `cut-approved`,
- approved Cut writes a refine-ready backlog or roadmap entry containing the plan,
- roadmap routing still requires an explicit reason,
- unknown signal ids still fail clearly.

Then implement the smallest CLI/runtime change needed. Preserve deterministic plain-text output suitable for tests.

Allowed write scope:
- `src/ml`
- `src/commands/script.py`
- `tests/ml/test-script.sh`
- command help text or templates directly tied to `ml script cut`

Do not process `ml-signal-20260516-003` in this story.

Acceptance: `bash tools/test.sh` passes.
