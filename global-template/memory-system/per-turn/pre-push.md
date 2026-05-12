# Pre-Push Module

<!-- managed by MindLayer installer — last_updated: YYYY-MM-DD -->

Load before surfacing push as Next Step or when the user requests a push.

Append:

```text
Pre-push: tests added and run for this change? Say 'yes' to push or 'skip' to push without testing.
```

Rules:
- Fire once per push action.
- `yes` and `skip` both proceed immediately.
- Do not fire during boot, status checks, or non-push turns.
