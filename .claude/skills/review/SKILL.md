---
name: review
description: Use when the user asks Claude to review a diff, plan, or completed implementation for correctness, regressions, security, test coverage, and overengineering.
---

# Review

Use this workflow to review a diff, plan, or completed change independently. Read-only; do not edit.

## Workflow

1. Establish what the change is supposed to do from the plan, ADR, issue, or request.
2. Inspect the diff and the surrounding code it touches.
3. For a large or high-risk change, spawn the review agent; otherwise review in the main thread.
4. Rank findings by severity, with file and line references when available.

## Agents

- Skeptical, independent review of a diff, plan, or implementation: `code-reviewer`

## Output

- Findings ordered by severity, each with file and line when available
- "No serious findings" stated clearly when true
- Residual risk and test gaps

## Token Rules

- Prefer a single reviewer over multiple overlapping passes.
- Do not spawn an agent for a trivial or single-line diff; review it inline.
- Report real defects first; do not pad with style nits.
