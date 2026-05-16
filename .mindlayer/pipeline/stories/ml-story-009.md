---
id: ml-story-009
title: Add folder-based signal store with legacy fallback
status: ready
created: 2026-05-16
parent: ml-signal-20260516-003
agent: any
---

You are adding the internal signal storage abstraction for MindLayer's folder-per-signal layout.

Target storage:
- Folder: `.mindlayer/pipeline/signals/`
- Index: `.mindlayer/pipeline/signals/index.md`
- Signal files: `<id>-<short-slug>.md`, for example `ml-signal-20260516-003-refactor-signals-storage.md`
- Each signal file preserves at least `id`, `title`, `created`, `status`, optional provenance fields such as `merged_into`, and the body.

Compatibility:
- Existing flat `.mindlayer/pipeline/signals.md` must remain readable.
- Folder-based signals are read first.
- Legacy flat signals are fallback/read-compatible during migration.

Start by writing failing CLI contract tests in `tests/ml/test-script.sh` or focused unit-style shell scenarios that prove:
- a folder signal file with `<id>-<short-slug>.md` is parsed,
- a legacy flat `signals.md` signal is still parsed when no folder signal exists,
- duplicate ids prefer the folder-based signal over the legacy fallback,
- `merged_into` provenance survives parsing.

Then implement the smallest helper layer in `src/commands/script.py` to load signal records from both storage shapes. Keep behavior unchanged except for this internal read compatibility.

Allowed write scope:
- `src/commands/script.py`
- `tests/ml/test-script.sh`

Do not change where new signals are written in this story. Do not migrate project memory in this story.

Acceptance: `bash tools/test.sh` passes.
