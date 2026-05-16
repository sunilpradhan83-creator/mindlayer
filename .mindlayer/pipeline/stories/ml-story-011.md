---
id: ml-story-011
title: Teach status and cut to read folder signals first
status: ready
created: 2026-05-16
parent: ml-signal-20260516-003
agent: any
---

You are updating `ml script status` and `ml script cut` to operate on folder-based signals first while preserving legacy fallback.

Current behavior:
- Status counts legacy `signals.md` by scanning status lines.
- Cut finds and updates signal blocks in legacy `signals.md`.

Target behavior:
- Status counts pending and merged signals from folder-based signal files first.
- If no folder signals exist for an id, legacy `signals.md` remains readable.
- Cut can find a folder-based signal by id and update its status to `cut-approved`.
- Cut can still find/update legacy flat signals during migration.
- Duplicate ids prefer the folder-based signal.

Start by writing failing CLI contract tests that verify:
- status counts folder-based `pending`, `merged`, `completed`, and `cut-approved` signals correctly,
- Cut can route a folder-based pending signal and update the signal file,
- Cut still routes a legacy flat pending signal,
- when both folder and legacy contain the same id, Cut updates the folder file and leaves legacy fallback untouched.

Then implement the smallest runtime change in `src/commands/script.py`.

Allowed write scope:
- `src/commands/script.py`
- `tests/ml/test-script.sh`

Do not migrate the current project signals in this story.

Acceptance: `bash tools/test.sh` passes.
