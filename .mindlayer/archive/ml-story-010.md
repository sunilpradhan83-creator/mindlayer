---
id: ml-story-010
title: Write new signals as id-slug files with index rows
status: done
proved_by: bash tools/test.sh
proved_at: 2026-05-16
started_from: 2417bce
created: 2026-05-16
parent: ml-signal-20260516-003
agent: any
---

You are changing `ml script signal` so new signals write to the folder-based storage layout.

Target behavior:
- New signals are written to `.mindlayer/pipeline/signals/<id>-<short-slug>.md`.
- The short slug is derived deterministically from the signal title.
- The filename must include the stable signal id first.
- `.mindlayer/pipeline/signals/index.md` is created/updated atomically with a row for the new signal.
- Filename collisions must not overwrite an existing file; if needed, append a deterministic suffix.
- Existing legacy `.mindlayer/pipeline/signals.md` remains untouched.

Start by writing failing CLI contract tests in `tests/ml/test-script.sh` that verify:
- `ml script signal` creates `signals/` and `signals/index.md`,
- the signal file name starts with `ml-signal-YYYYMMDD-NNN-`,
- the file contains `id`, `title`, `created`, `status: pending`, and body,
- the index row references the file,
- creating two signals with the same title does not overwrite the first file.

Then implement the smallest runtime change needed in `src/commands/script.py`.

Allowed write scope:
- `src/commands/script.py`
- `tests/ml/test-script.sh`

Do not migrate existing project `signals.md` in this story. Do not change Cut routing semantics.

Acceptance: `bash tools/test.sh` passes.
