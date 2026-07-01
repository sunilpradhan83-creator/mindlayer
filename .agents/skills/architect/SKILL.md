---
name: architect
description: Use when the user asks Codex to design, architect, plan, create an ADR, evaluate architecture, choose an approach, or research best practices before implementation.
---

# Architect

Use this workflow for architecture and planning requests. Design only; do not implement.

## Workflow

1. Decide whether parallel agents are worth the cost.
   - Use a single pass for small, local, or obvious decisions.
   - Spawn agents only when codebase exploration and external research can happen independently.
2. For non-trivial design work, spawn the mapped agents below, then synthesize once their summaries land.
3. Return a compact ADR and execution plan.

## Agents

- Research current external facts, docs, ecosystem practice, and tradeoffs: `best-practice-researcher`
- Read-only codebase exploration: built-in `explorer`
- Synthesize the decision after research and exploration summaries are available: `principal-architect`

## Output

- ADR title
- Status: proposed
- Context
- Decision
- Options considered
- Tradeoffs and risks
- Rejected overengineering
- Independent implementation slices
- Verification plan

## Token Rules

- Default to no more than three spawned agents.
- Ask spawned agents for compact summaries, not long reports.
- Do not spawn subagents for tasks that touch one file, have no meaningful design choice, or are mostly sequential.
