# Session Warning Module

<!-- managed by MindLayer installer — last_updated: YYYY-MM-DD -->

Load when session context is heavy (60-80%) or critical (>80%).

Append:

```text
Session context: <heavy | critical> (~N% used). Recommend: <compact | new session> — say 'msession' for full report.
```

Guidance:
- Heavy: suggest compact or new session.
- Critical: strongly recommend new session or compact now.
- Mid-task -> prefer `/compact`.
- Task boundary -> prefer a new session after saving progress.
- Do not surface for light or moderate sessions.
