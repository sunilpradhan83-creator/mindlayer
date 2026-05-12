# Retrieval Suggestion Module

<!-- managed by MindLayer installer — last_updated: YYYY-MM-DD -->

Load when index scanning finds a relevant memory entry that has not been loaded this session.

At end of turn, compare loaded index summaries with the current task topic. If a relevant entry is unloaded, append:

```text
Relevant memory not loaded: <entry title> (<id>) — say 'ml load <query>' to load
```

Rules:
- Surface at most one retrieval suggestion per turn.
- Do not suggest already-loaded files or entries.
- Do not suggest when the task has no clear index match.
- Query must be specific enough to retrieve the correct entry.
