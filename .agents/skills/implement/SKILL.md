---
name: implement
description: Use when the user asks Codex to implement an ADR, execution plan, design, multi-step feature, or large change and wants parallel senior developer agents where useful.
---

# Implement

Use this workflow for implementation requests based on a plan, ADR, issue, or design.

## Workflow

1. Read the requested plan and inspect the current worktree.
2. Split the work into slices.
3. Decide which slices can safely run in parallel.
   - Parallelize only when slices touch separate modules, files, packages, tests, or docs.
   - Keep sequential work in the main thread.
4. Spawn the mapped implementation agents for independent slices.
5. Integrate results in the main thread.
6. Run the smallest useful verification that proves the integrated behavior.
7. Spawn the review agent for one final pass when the change is non-trivial.

## Agents

- Implement one clearly scoped, independent slice: `senior-worker`
- Final review pass on a non-trivial change: `reviewer`

## Output

- Slices chosen
- Which slices were parallelized and why
- Files changed
- Verification run
- Review findings or "no serious findings"
- Residual risks

## Token Rules

- Default to one to three workers.
- Use four workers only when the work is clearly independent.
- Do not spawn workers for same-file edits, ambiguous requirements, or changes that require constant coordination.
- Prefer fewer agents plus stronger verification over more agents plus weaker review.
