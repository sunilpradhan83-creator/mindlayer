# /m-status

Check MindLayer memory health and suggest fixes. Do not write without explicit approval.

## Check

Inspect:

- missing global memory files
- missing project memory files
- missing indexes
- duplicate entries
- stale entries (flag count by type)
- archived entries (count in `archive.md` if it exists)
- oversized files
- unclear routing
- conflicting memory
- invalid metadata
- ignored file rules
- adapter marker blocks
- files nearing budget limits

Use explicit thresholds when possible:

- `near limit`: at or above 80% of the file budget
- `over limit`: above the file budget

When a file is near or over budget, proactively tell the user before the next memory write becomes messy.
Include the file name, current size, risk, and 2-4 concrete cleanup options.

## Expected Project Files

```text
.mindlayer/project.md
.mindlayer/progress.md
.mindlayer/decisions.md
.mindlayer/context.md
.mindlayer/backlog.md
.mindlayer/risks.md
.mindlayer/index.md
.mindlayer/local.md
```

## Expected Git Ignore Rules

```text
.mindlayer/local.md
.mindlayer/private/
.mindlayer/sessions/
.mindlayer/cache/
.mindlayer/tmp/
```

## Subdirectory Checks

When subdirectories exist, inspect:

- `tmp/`: warn if files exist with a modification date older than the current session — stale scratch from a prior session. Suggest clearing with `/m-clean`.
- `sessions/`: report count of session files and most recent date. No action needed.
- `cache/`: report count and most recent file. Flag entries older than 7 days as potentially stale.
- `private/`: acknowledge existence only. Do not read or surface content.

## Per-File Health Score

For each committed `.mindlayer/` file, compute a health score: **OK | WARN | CRITICAL**.

Score across three dimensions — overall score equals the worst:

| Dimension | WARN | CRITICAL |
|-----------|------|----------|
| Staleness | Any entry with `last_updated` > 90 days | Majority of entries > 180 days |
| Size | ≥ 80% of line budget (240+ lines) | ≥ 100% of line budget (300+ lines) |
| Duplicates | Two entries with overlapping titles, tags, or summary | Near-identical entries |

Skip `archive.md` and `local.md`. Mark `index.md` as navigation-only (no score).

Show in Output as a compact table. When any file scores WARN or CRITICAL, append a one-line fix suggestion beneath the table.

## Output

Return:

- Per-File Health:
  ```
  <file>    <OK|WARN|CRITICAL>    (<issue summary or "clean">)
  ```
- Healthy:
- Warnings:
- Stale entries: N flagged (list titles and types) — say '/m-archive' to review
- Archived entries: N in archive.md (global: N, project: N)
- Conflicts:
- Continuity:
  - pending approvals
  - blockers
  - unfinished work
  - next useful action
- Context:
  - files loaded
  - files skipped
  - files changed
  - MindLayer context used for the current task
  - MindLayer context used in the current session
  - model tokens, when the host exposes exact usage
- Suggested fixes:
- Approval needed:

If there is a pending memory-write proposal, include its destination and action. Do not imply it is approved. If nothing is pending, say `None`.

When a file is near or over its limit, suggested fixes should prefer:

- archiving stale entries
- merging duplicate or overlapping entries
- compressing long summaries
- splitting broad files into tighter scopes only when needed

Suggest fixes clearly, but do not modify files unless the user approves.
