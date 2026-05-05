# Backlog

## Future Roadmap

id: ml-20260430-005
created: 2026-04-30
updated: 2026-05-05
scope: project
type: backlog
tags: [roadmap]
confidence: medium
status: active
source: manual

### Summary
Concrete V2 items after V1 is stable.

### Details
- CLI in V2: makes commands reliable and host-agnostic instead of relying on prompt files.
- Archive mode: when memory files grow, users need a way to archive old entries without deleting them.
- `/m-session` command: shows current session context cost and recommends new session vs compact based on thresholds.
- `.mindlayer/` subdirectories: `private/` for sensitive notes, `sessions/` for session handoff snapshots, `cache/` for generated output, `tmp/` for throwaway scratch. Removed from V1 installer because no V1 behavior writes to them. Add back in V2 when real purpose exists behind each one.

### When to use
Use when planning post-V1 work.

### Related
ml-20260430-003
