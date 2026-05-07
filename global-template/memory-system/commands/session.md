# ml session

<!-- managed by MindLayer installer — last_updated: YYYY-MM-DD -->

Report current session context cost and recommend whether to continue, compact, or start a new session.

## Inspect

Estimate the following from the current session:

- Conversation history: words and estimated tokens
- MindLayer memory loaded this session: which files, estimated tokens
- Total session context: combined estimate
- Approximate context window usage as a percentage

When exact token counts are unavailable, estimate as words × 1.3 or characters ÷ 4. Mark estimates as approximate.

## Thresholds

- Light (< 30%): continue, no action needed
- Moderate (30–60%): note it, no action needed
- Heavy (60–80%): suggest compact or new session
- Critical (> 80%): strongly recommend new session or compact now

## Recommendation Logic

- Mid-task and heavy or critical → recommend `/compact`
- At task boundary and heavy or critical → recommend new session (MindLayer boot is cheap, restores context with zero history overhead)
- Heavy or critical → also suggest `ml archive` to trim stale memory before next session
- Light or moderate → continue

## Output

Return:

- Session context:
  - Conversation: ~N words, ~N est. tokens
  - MindLayer memory loaded: ~N words, ~N est. tokens
  - Total: ~N est. tokens (~N% of context window)
- Status: light | moderate | heavy | critical
- Recommendation: continue | compact | new session
- Reason:
- Memory: (only when heavy or critical) suggest `ml archive` to trim stale entries before next session

## Session Continuity Behavior

- Track pending memory-write approvals, unfinished tasks, blockers, and the smallest useful next action.
- If a memory write has been proposed but not approved, keep it visible as pending until the user clearly approves or rejects it.
- Remind the user about pending memory-write approvals before moving to unrelated memory work.
- Continuity state is surfaced in the per-turn Token Burned block via Next Step prediction.
- If there are no pending approvals, blockers, or unfinished work, say `None` compactly.
- MindLayer boot is intentionally cheap. Recommend starting a new session at each task boundary rather than compacting mid-session. Compacting carries forward session history at a token cost on every subsequent message; a new session boots from durable memory with zero history overhead.

## Handoff Behavior

Deprecated. The Per-Turn Status Block (Token Burned) replaces Handoff as the ongoing status surface. If Handoff is explicitly requested, Next Step prediction must still be included using the hierarchy defined in per-turn.md.

## Backup Rules

- `~/.mindlayer/preferences/` is a git repo. Back it up by adding a remote: `git -C ~/.mindlayer/preferences remote add origin <your-private-repo>`.
- All other `~/.mindlayer/` files are outside project Git and not automatically backed up.
- Do not store secrets, tokens, raw conversations, or project-private facts in global preferences.

## Session Write

When a session write trigger fires (user says "done for today", "wrapping up", "end session", etc.), append after the main response:

```text
Session summary ready — say 'save session' to write sessions/YYYY-MM-DD.md.
```

Also fires automatically (with approval) at: pre-`/compact`, post-significant-completion, and when session context exceeds 80%.
