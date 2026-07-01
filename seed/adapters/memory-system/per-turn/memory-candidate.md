# Memory Candidate Module

<!-- managed by MindLayer installer — last_updated: YYYY-MM-DD -->

Load when a save trigger fires or end-of-turn review finds durable information worth preserving.

Scan the current turn, last completed task, and earlier unproposed context. Candidate checks:

| Check | Target |
|---|---|
| Decision or rationale | `decisions.md` |
| Risk or concern | `risks.md` |
| Meaningful progress | `progress.md` |
| Project context or constraint | `context.md` |
| Backlog change | `backlog.md` |
| User preference | `preferences/` |
| Prior unsaved candidate | Re-surface it |

Surface at most one candidate, highest priority first:

```text
Memory candidate: <description> → <target.md> — say 'save' or 'skip'
```

Rules:
- Do not wait for `ml save` when a candidate is detected.
- Re-surface pending candidates until clearly saved or skipped.
- Never target adapters: `AGENTS.md`, `CLAUDE.md`, `copilot-instructions.md`, or tool rules.
- `go`, `save`, or `approved` approves only the surfaced candidate.
