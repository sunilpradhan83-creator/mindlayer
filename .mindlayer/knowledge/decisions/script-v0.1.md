# SCRIPT v0.1 Decision

## Simplified SCRIPT Lifecycle for 0.1 Developer Preview
id: ml-20260517-001
created: 2026-05-17
updated: 2026-05-17
scope: project
type: decision
tags: [script, v0.1, lifecycle, signals, cut, stories, transfer, open-source]
confidence: high
status: active
source: conversation

### Summary
SCRIPT v0.1 is the human-first lifecycle for MindLayer 0.1 Developer Preview: Signal -> Cut -> Refine -> Implement -> Prove -> Transfer. It keeps roadmap and backlog lightweight, makes Signal the universal intake, and keeps every durable write approval-gated.

### Human Model
The simple mental model is: notice something, decide its size, shape the work, build it, prove it, then save what was learned.

- Signal: capture raw input before deciding what to do.
- Cut: decide size, priority, and route.
- Refine: turn approved work into a lean executable story.
- Implement: do the work.
- Prove: show evidence that it works or explain why proof is not applicable.
- Transfer: decide whether any durable learning should be saved.

### Signal Sources
Signals can come from humans, agents, tests, dogfood, market/research changes, docs drift, security concerns, implementation discoveries, and code review. Agents may suggest signal candidates from these sources, but durable signal writes still require human approval.

### Cut Routes
Cut is the prioritization point. Every cut records size, route, priority, reason, and target.

- XS -> direct fix.
- S -> story.
- M -> backlog.
- L/XL -> roadmap.
- monitor -> watch/revisit later.
- merge -> combine with an existing signal/work item.
- kill -> drop/archive with reason.

Roadmap and backlog are optional destinations, not mandatory stages. A small cosmetic bug can become a direct fix; a medium item can wait in backlog; a direction-changing signal belongs in roadmap.

### Artifact Rules
- Pending signals may be "fat" enough to hold context, debate, options, and suggested cut.
- After Cut, the signal becomes read-only provenance. New debate belongs in the routed story/backlog/roadmap item or in a new signal.
- Signal stays alive until its routed target reaches a terminal state: completed, killed, merged, or superseded.
- If a signal fans out to multiple targets, it closes only when all routed targets are terminal.
- In 0.1, stale or dormant lifecycle items should be flagged for humans, not silently archived.
- Stories stay lean: intent, scope, guardrails, and proof. They are work orders, not project plans.
- Roadmap answers where the project is going and why. Backlog answers what approved work is next.

### Transfer Rule
Transfer check is mandatory at story close. Transfer write is optional and approval-gated.

The agent should propose any durable lesson from the signal plus the story/progress evidence. The human may approve as-is, edit/add context, or skip. Skips are allowed; future enforcement may log skip reasons so methodology drift is visible.

### Field Conventions
0.1 ships the SCRIPT v0.1 methodology and documented field conventions. Runtime/schema enforcement is deferred.

Recommended fields for future enforcement:
- `source_signal`
- `cut_route`
- `size`
- `priority`
- `proof_type`
- `transfer_status`
- `lifecycle_state`

Allowed proof types should remain practical: test, lint, manual, docs-review, install, dogfood, or n-a-with-reason.

### Enforcement Gap
The lifecycle is canonical now, but not every rule is runtime-enforced in 0.1. A backlog item tracks which rules should become CLI-enforced, `ml status --strict` warnings, or convention-only after dogfood shows where decay actually happens.

### Supersedes
Supersedes `script-v4.md` as the active methodology. `script-v4.md` remains historical context.

### Related
ml-20260514-001
ml-20260514-002
ml-20260514-003
ml-20260514-004
