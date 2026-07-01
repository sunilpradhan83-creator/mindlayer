# Per-Turn Core

<!-- managed by MindLayer installer — last_updated: YYYY-MM-DD -->

Load every session after router.md. Behavioral modules live in `memory-system/per-turn/` and load only on trigger.

End every agent turn with:

```text
-------------------------------------------------------------
Token Burned:
  - Last turn: ~N words, ~N est. tokens
  - Session: ~N words, ~N est. tokens

Next Step: <smallest useful action>

Coming Up:
  - <action>
--------------------------------------------------------------
```

Use estimates (`~`), words x 1.3 or characters / 4. `Last turn`, `Session`, and nonblank `Next Step` are required. Omit `Coming Up` unless ambiguity exists or more than two actions are pending. For ambiguity, mark the first action `(recommended)`.

Apply the first matching rule:

1. Active task in progress -> next action within current task.
2. Task complete + uncommitted changes exist -> commit.
3. Task complete + clean tree -> next backlog item.
4. Backlog empty -> next roadmap phase.
5. Roadmap complete -> brainstorm next major version.

Never skip to a lower-priority action. Coming Up may include only same-tier or lower actions.

When backlog empties, append before Token Burned:

```text
Backlog complete — next phase: <roadmap phase and summary>. Say 'pull next phase' to populate backlog.
```
