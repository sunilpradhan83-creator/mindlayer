# Lifecycle

Memory has a lifecycle so old information does not keep steering new work incorrectly.

## Statuses

- `active`: current and trusted.
- `experimental`: useful but not fully proven.
- `deprecated`: superseded but retained for reference.
- `archived`: inactive history.

## V1 Behavior

V1 does not implement cleanup or archive automation. Agents may identify stale, conflicting, or oversized memory during `/m-status`, but they must ask for approval before changing anything.

## Active Maintenance

MindLayer should actively warn before memory files become bloated.

- Treat file budgets as an early warning system, not only a hard stop.
- When a file nears its budget, agents should say so explicitly and recommend cleanup before the next write.
- Warnings should include the file, the current size, why it matters for token usage, and specific next steps.
- Recommended actions should prefer archive, merge, compress, and only then split.

Archive and cleanup workflows are planned for V2, but proactive warning and user prompting are part of V1 maintenance behavior.
