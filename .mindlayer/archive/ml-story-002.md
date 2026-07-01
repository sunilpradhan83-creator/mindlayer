---
id: ml-story-002
title: Split decisions.md into decisions/ subfolder
status: done
proved_by: bash tools/test.sh
proved_at: 2026-05-16
started_from: 587107f
created: 2026-05-14
parent: hierarchical-index-tree
agent: any
---

You are splitting `.mindlayer/knowledge/decisions.md` into a subfolder with one file per logical group.

Current state: one flat `decisions.md` at 700+ lines — over the 300-line budget.

Target structure:
```
.mindlayer/knowledge/
  decisions/
    index.md          ← summary index: maps script-v4.md, architecture.md, process.md
    script-v4.md      ← ml-20260514-001, ml-20260514-002, ml-20260514-003, ml-20260514-004
    architecture.md   ← ml-20260512-001, ml-20260511-002, ml-20260510-002, ml-20260510-003,
                         ml-20260510-004, ml-20260507-007, ml-20260507-004, ml-20260513-001
    process.md        ← ml-20260503-001, ml-20260503-002, ml-20260507-002, ml-20260505-007,
                         ml-20260505-005, ml-20260508-002, ml-20260514-005, ml-20260514-006
```

`decisions/index.md` summary format (one line per entry):
```
- <id> | <title> | <file> | <one-line summary>
```

Start by writing failing tests in `tests/ml/test-load.sh` that verify:
- `ml load script` returns entries from `decisions/script-v4.md`.
- `ml load approval` returns entries from `decisions/process.md`.
- `ml load boot` returns entries from `decisions/architecture.md`.
- `decisions.md` flat file no longer exists after migration.

Then:
1. Create `knowledge/decisions/` directory.
2. Move entries into the three files (keep full entry content intact — do not compress).
3. Create `knowledge/decisions/index.md` with a summary pointer line per entry.
4. Delete `knowledge/decisions.md`.

Do not touch root `index.md`, `knowledge/index.md`, lint, or `_index.py` — those are handled in other stories.

Acceptance: all tests pass (`bash tools/test.sh`). `decisions.md` does not exist. Each split file is under 300 lines.
