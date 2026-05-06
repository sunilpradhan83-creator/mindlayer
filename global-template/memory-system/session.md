# Session Rules

<!-- managed by MindLayer installer — last_updated: YYYY-MM-DD -->

Load this file at session boundaries: boot, /m-session, and when session-end phrases fire.

## Session Continuity Behavior

- Track pending memory-write approvals, unfinished tasks, blockers, and the smallest useful next action.
- If a memory write has been proposed but not approved, keep it visible as pending until the user clearly approves or rejects it.
- Remind the user about pending memory-write approvals before moving to unrelated memory work.
- Continuity state (pending approvals, blockers, unfinished tasks) is surfaced in the per-turn Token Burned block via Next Step prediction. Show explicit continuation context in status, pause, block, and recovery responses.
- If there are no pending approvals, blockers, or unfinished work, say `None` compactly.
- MindLayer boot is intentionally cheap. When the user asks about session or token management, recommend starting a new session at each task boundary rather than compacting mid-session. Compacting carries forward session history at a token cost on every subsequent message; a new session boots from durable memory with zero history overhead.

## Handoff Behavior

Deprecated. The Per-Turn Status Block (Token Burned) replaces Handoff as the ongoing status surface. If Handoff is explicitly requested, Next Step prediction must still be included using the hierarchy defined in per-turn.md.

## Backup Rules

- `~/.mindlayer/preferences/` is a git repo. Back it up by adding a remote: `git -C ~/.mindlayer/preferences remote add origin <your-private-repo>`.
- All other `~/.mindlayer/` files are outside project Git and not automatically backed up.
- Do not store secrets, tokens, raw conversations, or project-private facts in global preferences.
