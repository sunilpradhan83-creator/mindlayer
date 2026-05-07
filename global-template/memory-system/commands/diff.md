# ml diff

<!-- managed by MindLayer installer — last_updated: YYYY-MM-DD -->

Surface what changed in `.mindlayer/` since the last session. Fires automatically at boot and during `ml status`. Not a user-invocable command — loaded by boot and status flows only.

## Baseline

1. Find the most recent session file in `.mindlayer/sessions/` by filename (YYYY-MM-DD.md, latest date wins).
2. Read the `## Commit` section of that file. Extract the git SHA (first token on the line, e.g. `abc1234`).
3. If no session file exists, or no `## Commit` line is found, skip diff silently — output nothing.
4. If git is unavailable or the SHA is not reachable, skip diff silently — output nothing.

## What to Diff

Run: `git diff <sha>..HEAD -- .mindlayer/`

Scope: project `.mindlayer/` only. Do not diff `~/.mindlayer/`.

Exclude: `sessions/`, `cache/`, `tmp/`, `private/`, `local.md`, `archive.md`.

## What to Extract

Parse the diff for `id:` lines to identify entry-level changes:

- **New entries**: `id:` lines present in HEAD but not in `<sha>` — an entry was added.
- **Updated entries**: `id:` lines present in both, but surrounding content changed — an entry was modified.
- **Archived entries**: `id:` lines removed from a main file and added to `archive.md`, or `status:` changed to `archived`.

Group results by file. Count per category. Do not list full entry titles — file name + count is sufficient.

## Output Format

When changes exist, output this block:

```text
Memory changes since last session:
  New:      N entries (<file>, <file>)
  Updated:  N entries (<file>)
  Archived: N entries
```

Omit any line where count is 0. If all counts are 0 (no changes detected), omit the block entirely — do not output "Memory changes since last session: none."

## Placement

- **Boot receipt**: insert between `Current progress:` and `Context cost:`.
- **ml status output**: insert in the `Context:` section, after files loaded/skipped.

## Rules

- Fire at most once per session per surface (once at boot, once per `ml status` call).
- Skip silently on any error — missing session file, unreachable SHA, git unavailable. Never surface an error message to the user for a missing diff.
- Do not load `archive.md` to compute the diff — use git diff output only.
- Do not propose memory writes based on diff output. Diff is read-only orientation.
