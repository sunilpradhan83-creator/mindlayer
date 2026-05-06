# /m-archive

Scan for stale memory entries and propose archive or delete actions. Do not write without explicit approval.

## Triggers

Invoke immediately when the user says:
- "clean memory", "clean up memory", "archive memory", "archive it"
- "delete memory", "forget X", "remove X from memory"
- "memory is getting bloated", "memory is too large", "tidy memory"

Also invoked at proactive checkpoints — see Checkpoints below.

## Scan Strategy

Scan the **index first** — read `~/.mindlayer/index.md` and `.mindlayer/index.md`. Use index metadata (`status`, `last_updated`, `type`, `tags`, `summary`) to flag candidates before reading full file sections. Only load a section when proposing an action on that specific entry.

### Never Scan

Excluded from archive actions:

| File | Reason |
|------|--------|
| `index.md` (global and project) | Navigation map — entries are updated, not archived |
| `boot.md` | Operational rules — system managed |
| `~/.mindlayer/router.md` | Operational rules — system managed |
| `.mindlayer/router.md` | Operational rules — system managed |
| `memory-system/` (all subfiles) | Operational rules — system managed |
| `archive.md` | The destination itself |

### Staleness Criteria by Type

| Type | Flag when | Default proposal |
|------|-----------|-----------------|
| `progress` | `status: completed` or phase ended | archive |
| `backlog` | All sub-items completed | archive |
| `risk` | `status: resolved` or `mitigated` | archive |
| `decision` | Superseded by a newer decision on the same topic | archive |
| `roadmap` | Version or phase marked completed | archive |
| `context` | `last_updated` > 90 days and no recent index reference | archive or keep |
| `playbook` | Superseded by a newer workflow entry | archive |
| `principles` | Explicitly superseded | archive |
| `anti-patterns` | Explicitly resolved | archive |
| `local.md` entries | Any entry — file is inherently transient | delete |
| `preference` | Explicitly contradicted or tool/style no longer relevant | delete or keep |

## Archive vs Delete

- **Archive**: entry was once true and has historical or reference value. Move content to `archive.md` in the same scope.
- **Delete**: entry is wrong, irrelevant, or purely transient with no future reference value (`local.md` entries, explicitly contradicted preferences).

Decisions are never deleted — they always archive. Progress and risk entries always archive. Only `local.md` entries and explicitly outdated preferences are candidates for deletion.

## Proposal Format

For each flagged entry, show:

```text
Archive Candidate:
- Title: <entry title>
- File: <source file> → section: <section heading>
- Reason: <why it's stale>
- Proposed action: archive | delete | keep
- Action detail: move to <archive.md> | remove entirely | no change
- Confidence: high | medium | low
```

After listing all candidates:

```text
Summary: N to archive, N to delete, N to keep
Say 'approve all', approve by title, or adjust per entry.
```

If no stale entries are found:

```text
No stale entries found. Memory is clean.
```

## Approval Rules

Show all candidates before acting. Wait for explicit approval.

Approval must be literal. `approve`, `approved`, `go ahead`, `approve all`, or an equally explicit instruction counts. `ok`, `got it`, `sounds good` do not count.

If the user approves a batch (`approve all`): execute all proposed actions.
If the user approves selectively: execute only the named entries.
If the user adjusts an action (e.g., "keep the decisions one"): update that entry before executing.

## Execution

When approved:

1. **Archive**: Move the entry's full markdown section to `archive.md` (global or project scope). Create `archive.md` if it does not exist, with a `# Archive` heading.
2. **Delete**: Remove the entry's full markdown section from the source file.
3. **Index update**: For archived entries — set `status: archived`, update `file: archive.md`. For deleted entries — remove the entry from the index entirely.
4. **Report**:

```text
Done.
- Archived: <titles>
- Deleted: <titles>
- Kept: <titles>
```

## Subdirectory Cleanup

`/m-clean` also handles ephemeral subdirectory content — not just index entries:

- **`tmp/`**: clear all files when stale (modification date from a prior session). Always propose before deleting.
- **`cache/`**: flag files older than 7 days as potentially stale. Propose deletion per file — cache is always regenerable.
- **`sessions/`**: never cleared. Dated snapshots are permanent logs.
- **`private/`**: never auto-cleared. User deletes manually.

Propose subdirectory cleanup alongside index entry proposals when both are present. Batch under the same approval flow.

## Checkpoints

`/m-archive` scans and prompts automatically (approval still required) at these moments:

1. **Post-backlog completion** — when a backlog item is marked completed, scan for entries made stale by that completion.
2. **Session heavy/critical** — when `/m-session` reports ≥ 60% context usage, suggest an archive pass before compact or new session.
3. **Index size threshold** — when active entry count in either index exceeds 20 entries, nudge with a clean-pass suggestion.
4. **Phase transition** — when `progress.md` records a version or phase transition (e.g., V1 → V2), flag all entries from the completed phase for review.
5. **Risk resolved** — when a risk entry is updated to resolved or mitigated, prompt to archive it immediately.

At checkpoints, do not interrupt the main response. Append after the primary answer:

```text
Memory check: <N> stale entries found — say 'clean' or '/m-archive' to review.
```
