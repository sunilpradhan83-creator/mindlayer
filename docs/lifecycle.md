# Lifecycle

Memory has a lifecycle so old information does not keep steering new work incorrectly.

## Statuses

- `active`: current and trusted.
- `experimental`: useful but not fully proven.
- `deprecated`: superseded but retained for reference.
- `archived`: inactive history.

## V1 Behavior

V1 does not implement cleanup or archive automation. Agents may identify stale or conflicting memory during `/m-status`, but they must ask for approval before changing anything.

Archive and cleanup workflows are planned for V2.

