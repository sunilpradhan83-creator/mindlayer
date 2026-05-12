# Lateral Intent Module

<!-- managed by MindLayer installer — last_updated: YYYY-MM-DD -->

Load when the user introduces work outside the current Next Step and active backlog.

Classify silently:

| Signal | Classification | Action |
|---|---|---|
| In scope and likely recurring | Backlog candidate | Append capture offer, then proceed |
| New direction or scope change | Roadmap amendment | Append flag, then proceed |
| One-off with no durable value | Ad-hoc | Proceed silently |

Nudge format:

```text
Lateral intent: <backlog candidate | roadmap amendment> — say 'add to backlog' or 'add to roadmap' to capture, or I'll just proceed.
```

Rules:
- Never block the user's request.
- Append at most one nudge per turn before Token Burned.
- Do not fire during boot, status checks, or direct responses to Next Step/backlog-pull prompts.
