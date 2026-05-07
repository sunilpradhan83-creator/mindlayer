# Per-Turn Rules

<!-- managed by MindLayer installer — last_updated: YYYY-MM-DD -->

Load this file at the start of every session, immediately after router.md. Rules here fire on every agent turn.

## Per-Turn Status Block

Append a status block at the end of every agent turn as the last output.

```text
-------------------------------------------------------------
Token Burned:
  - Last turn: ~N words, ~N est. tokens
  - Session: ~N words, ~N est. tokens

Next Step: <smallest useful action>

Coming Up:            ← omit this section when not needed
  - <action>
  - <action>
--------------------------------------------------------------
```

Use words × 1.3 or characters ÷ 4 to estimate tokens when exact counts are unavailable. Mark as approximate.

**Next Step** — always a single action, never a list. Always predict something, never leave blank.

**Coming Up** — optional. Show only when:
- Meaningful ambiguity exists between two equally valid next actions, OR
- More than 2 pending actions exist in the queue

For **ambiguity**: list the recommended action first, marked `(recommended)`. Do not mark others.
For **long queues** (>2 pending): list in selection-priority order. No `(recommended)` markers.
Omit entirely when Next Step is clear and the queue has ≤ 2 items.

**Next Step prediction hierarchy** — use to populate both Next Step and Coming Up:
1. Active task in progress → next action within the current task
2. Task complete + uncommitted changes exist → commit
3. Task complete + clean working tree → next item in backlog
4. Backlog empty → next roadmap phase (surface pull proposal)
5. Roadmap complete → propose brainstorming next major version with the user

**Priority enforcement rules:**
- Next Step is always the highest-priority action from the hierarchy. Apply the lowest-numbered rule that currently applies — never skip a rule to reach a more interesting one.
- Coming Up lists only actions that follow Next Step in the same or lower priority tier. Never list an action in Coming Up that ranks higher than Next Step in the hierarchy.
- Uncommitted changes (rule 2) always outrank next backlog item (rule 3). Do not surface a new backlog item as Next Step while uncommitted changes exist.

**Backlog-empty detection** — when a task completes and the backlog is empty, append before the Token Burned block:

```text
Backlog complete — next phase: <roadmap phase name and summary>. Say 'pull next phase' to populate backlog.
```

When the user says 'pull next phase', decompose the roadmap phase into backlog items and propose each for approval before writing.

## Lateral Intent Routing

When a user introduces work that is not the current Next Step and not in the active backlog, classify the intent before proceeding.

**Classification:**

| Signal | Classification | Agent action |
|---|---|---|
| Fits project scope, likely recurring | Backlog candidate | Append capture offer, then proceed |
| New direction or scope change | Roadmap amendment | Append flag, then proceed |
| Clearly one-off, no durable value | Ad-hoc | Proceed without comment |

**Rules:**
- Classify silently. Do not narrate the classification.
- Never block the user's request. The nudge is informational.
- Append at most one nudge per turn, after the main response and before the Token Burned block.
- Do not fire during boot, status checks, or when the user is explicitly responding to a Next Step or backlog pull.

**Nudge format:**

```text
Lateral intent: <backlog candidate | roadmap amendment> — say 'add to backlog' or 'add to roadmap' to capture, or I'll just proceed.
```

## Pre-Push Gate

Before surfacing push as a Next Step, or when the user requests a push, append:

```text
Pre-push: tests added and run for this change? Say 'yes' to push or 'skip' to push without testing.
```

**Rules:**
- Fire once per push action.
- `yes` or `skip` both proceed immediately — no further prompts.
- Do not fire during boot, status checks, or non-push turns.

## Load Announcement Contract

Every file load — at boot OR mid-session — must be announced before the response. Silence on a load is a contract violation.

```text
Loaded: <file-path> — <reason>
```

Rules:
- Announce every file that loads this turn, one line per file, before the main response.
- Reason must be non-empty and specific: what triggered the load.
- Do not re-announce files already loaded earlier in the same session.
- Do not announce `boot.md`, `router.md`, or `per-turn.md` after the initial boot receipt — they are boot-only.
- If multiple files load in one turn, announce each on its own line.

## Memory Candidate Scan

At the end of every turn, before completing the response, run this checklist:

| Check | If yes → candidate for |
|---|---|
| Was a decision made or rationale given? | `decisions.md` |
| Was a risk or concern identified? | `risks.md` |
| Was meaningful progress made or completed? | `progress.md` |
| Was new project context or constraint learned? | `context.md` |
| Was a backlog item added, resolved, or changed? | `backlog.md` |
| Was a user preference or working style observed? | `preferences/` |
| Was a prior candidate surfaced but not saved or skipped? | Re-surface it |

If any match, surface immediately — do not wait for `/m-save` or session end:

```text
Memory candidate: <description> → <target.md> — say 'save' or 'skip'
```

Rules:
- Surface at most one candidate per turn.
- If multiple candidates exist, surface the highest-priority one (decisions > risks > progress > context > backlog > preferences).
- Re-surface a pending candidate before surfacing a new one.
- Never target adapter files (AGENTS.md, CLAUDE.md, copilot-instructions.md).
- `go`, `save`, or `approved` counts as approval for the specific proposed candidate only.

## Index-Driven Retrieval Check

At the end of every turn, scan loaded index summaries against the current task topic. If any indexed entry is relevant to the current task but not yet loaded this session, flag it:

```text
Relevant memory not loaded: <entry title> (<id>) — say '/m-retrieve <query>' to load
```

Rules:
- Surface at most one retrieval suggestion per turn.
- Do not suggest files already loaded this session.
- Do not suggest if the current task has no clear match in the index.
- Query must be specific enough to retrieve the correct entry.

## Proactive Behavior

MindLayer commands are triggered two ways: by the AI detecting a need at the end of a turn, or by the user invoking them explicitly via a recognized phrase. Approval rules apply regardless of how a command is triggered.

### End-of-Turn Detection

At the end of every turn, before completing the response:

- Check whether the turn produced anything durable worth saving. If yes, surface a memory candidate immediately — do not wait for the next turn or session end.
- Check whether the current task context suggests relevant memory that has not yet been loaded. If yes, suggest a retrieval query.
- Estimate session context weight. If heavy or critical, surface a compact session warning.
- Check whether the current task just completed and the backlog is now empty. If yes, surface a roadmap phase pull proposal (see Per-Turn Status Block).

Surface at most one of each per turn. Do not interrupt the main response — append after the primary answer.

### Memory Candidate Format

When a memory candidate is detected via the Memory Candidate Scan checklist, append at the end of the response:

```text
Memory candidate: <description> → <target.md> — say 'save' or 'skip'
```

`go`, `save`, or `approved` counts as explicit approval for the specific proposed candidate only. Full rules in Memory Candidate Scan section above.

### Retrieval Suggestion Format

When a retrieval need is detected via the Index-Driven Retrieval Check, append at the end of the response:

```text
Relevant memory not loaded: <entry title> (<id>) — say '/m-retrieve <query>' to load
```

### Session Warning Format

When session context is heavy (60–80%) or critical (>80%), append at the end of the response:

```text
Session context: <heavy | critical> (~N% used). Recommend: <compact | new session> — say 'msession' for full report.
```

Do not surface this when status is light or moderate.

### Trigger Phrases

Load and save triggers are defined in `~/.mindlayer/router.md` (global) and `.mindlayer/router.md` (project). Routers are the single source of truth for all trigger signals.

The following commands are still user-invocable directly:

| Phrase | Command |
|--------|---------|
| "retrieve X", "load X", "what do we know about X" | `/m-retrieve <X>` |
| "where were we", "memory status", "mstatus", "what's loaded" | `/m-status` |
| "should I compact", "how much context", "start fresh", "msession" | `/m-session` |
| "clean memory", "clean up memory", "archive memory", "archive it", "delete memory", "forget X", "remove X from memory", "memory is getting bloated", "tidy memory" | `/m-archive` |
| "done for today", "wrapping up", "I'm done", "that's all", "bye", "done for now", "end session", "save session" | session write offer |

Interpret intent loosely — treat natural language variations as equivalent to the listed phrases.

`/m-status` and `/m-session` are never AI-initiated. Only the user triggers them.

Save triggers ("ml save", "remember this", "save this", etc.) are handled by the router. See `~/.mindlayer/router.md` Save Triggers section.

### Session Write Format

When a session write trigger fires, append after the main response:

```text
Session summary ready — say 'save session' to write sessions/YYYY-MM-DD.md.
```

Also fires automatically (with approval) at: pre-`/compact`, post-significant-completion, and when session context exceeds 80%.
