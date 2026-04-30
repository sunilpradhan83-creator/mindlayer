# /m-status

Check MindLayer memory health and suggest fixes. Do not write without explicit approval.

## Check

Inspect:

- missing global memory files
- missing project memory files
- missing indexes
- duplicate entries
- stale entries
- broken `.mindlayer/memory.md` symlink or pointer
- oversized files
- unclear routing
- conflicting memory
- invalid metadata
- ignored file rules
- adapter marker blocks

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
.mindlayer/memory.md
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

Suggest fixes clearly, but do not modify files unless the user approves.

