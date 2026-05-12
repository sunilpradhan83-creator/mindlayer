# Post-Write Size Module

<!-- managed by MindLayer installer — last_updated: YYYY-MM-DD -->

Load after an approved memory write to a committed MindLayer memory file.

Check the written file size against the 300-line budget:
- near limit: 240+ lines
- over limit: above the 300-line file budget (301+ lines)

When near or over limit, append before Token Burned:

```text
Memory size suggestion: <file.md> is <N> lines (<near limit|over limit>) — consider <compressing long entries|merging overlapping entries|archiving stale entries|splitting broad content if needed>.
```

Rules:
- Fire only after an approved memory write.
- Surface at most one size suggestion per turn.
- Do not fire during `ml status`.
- Prefer compression, merging, and archiving before splitting.
- Do not clean memory unless the user explicitly approves follow-up work.
