# /m-status

Check MindLayer memory health and suggest fixes. Do not write without explicit approval.

## Check

Inspect:

- missing global memory files
- missing project memory files
- missing indexes
- duplicate entries
- stale entries
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

## Output

Return:

- Healthy:
- Warnings:
- Conflicts:
- Suggested fixes:
- Approval needed:

When a file is near or over its limit, suggested fixes should prefer:

- archiving stale entries
- merging duplicate or overlapping entries
- compressing long summaries
- splitting broad files into tighter scopes only when needed

Suggest fixes clearly, but do not modify files unless the user approves.
