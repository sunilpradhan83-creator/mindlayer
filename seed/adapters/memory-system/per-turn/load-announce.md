# Load Announcement Module

<!-- managed by MindLayer installer — last_updated: YYYY-MM-DD -->

Load when any file is loaded after boot or when boot receipt rendering needs the announcement contract.

Every file load at boot or mid-session must be visible before the response:

```text
Loaded: <file-path> — <reason>
```

Rules:
- Announce each loaded file once per session.
- Reason must be non-empty and specific.
- Load before acting on the trigger.
- Do not re-announce `boot.md`, `router.md`, or `per-turn.md` after the initial boot receipt.
- Multiple loads get one line each.
- Silence after a load is a contract violation.
