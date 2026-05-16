---
id: ml-story-013
title: Archive completed signals on transfer
status: ready
created: 2026-05-16
parent: ml-signal-20260516-011
agent: any
---

You are implementing completed-signal archiving for the SCRIPT transfer lifecycle.

Current behavior:
- Active signals live in `.mindlayer/pipeline/signals/`.
- Completed stories move into `.mindlayer/pipeline/archive/`.
- Transfer marks the parent signal `completed`, but the completed signal remains in the active signal folder.

Target behavior:
- Active signal records remain in `.mindlayer/pipeline/signals/`.
- Completed signal records move to `.mindlayer/pipeline/archive/signals/`.
- Archived stories remain in `.mindlayer/pipeline/archive/` for now.
- `signals/index.md` should list only active folder signals after transfer.
- `.mindlayer/pipeline/archive/signals/index.md` should list archived signal records.
- The archived signal file must preserve id, title, created date, prior provenance fields such as `merged_into`, and body.
- The archived signal file should have `status: completed` after transfer.
- `ml script status` should continue to ignore completed signals for pending counts.
- Legacy flat `signals.md` fallback should remain readable during migration, but folder signal archival is the source-of-truth behavior for signal-backed backlog items.

Start by writing failing contract tests in `tests/ml/test-script.sh` that verify:
- transfer moves a completed folder signal into `archive/signals/`,
- active `signals/index.md` removes the archived signal row,
- `archive/signals/index.md` contains the archived signal row,
- the archived signal file has `status: completed`,
- `ml script status` counts remaining active pending/merged signals correctly after archival,
- legacy flat signals do not break transfer behavior.

Then implement the smallest runtime change in `src/commands/script.py`.

Allowed write scope:
- `src/commands/script.py`
- `tests/ml/test-script.sh`
- `.mindlayer/pipeline/stories/`

Do not migrate existing completed signal files in this story unless the implementation needs a fixture update. The current project data can be normalized by a separate transfer/migration step after the command behavior is proven.

Acceptance: `bash tools/test.sh` passes.
