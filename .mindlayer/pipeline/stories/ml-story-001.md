---
id: ml-story-001
title: Recursive load_indexes with pointer detection
status: ready
created: 2026-05-14
parent: hierarchical-index-tree
agent: any
---

You are implementing recursive index traversal in `src/commands/_index.py`.

Currently `load_indexes()` hardcodes three candidates:
- `~/.mindlayer/preferences/index.md`
- `.mindlayer/index-full.md`
- `.mindlayer/index.md`

After this story, `load_indexes()` must:
1. Read root `.mindlayer/index.md` (summary format).
2. Detect pointer entries — lines where the id field starts with `ml-index-ptr-` OR the file field ends with `/index.md` and the title contains "Index".
3. Follow each pointer by reading the referenced subfolder index file.
4. Collect leaf entries from all reached indexes (deduplicating by id).
5. Still load `~/.mindlayer/preferences/index.md` as before.
6. Stop loading `index-full.md` — it is deprecated.

A pointer entry in summary index format looks like:
```
- ml-index-ptr-knowledge | Knowledge Index | knowledge/index.md | Index for knowledge/ subfolder
```

Start by writing failing tests in `tests/ml/test-load.sh` that verify:
- A root index with a pointer to `knowledge/index.md` causes entries in that subfolder index to be returned by `ml load`.
- A two-level pointer chain (root → knowledge/index.md → decisions/index.md) resolves leaf entries correctly.
- `index-full.md` entries are NOT loaded when a pointer structure exists.
- Duplicate ids across indexes are deduplicated (first seen wins).

Then implement in `_index.py` until all new tests pass and existing tests still pass.

Do not touch any other file. Do not modify lint or _paths.py.

Acceptance: all tests pass (`bash tools/test.sh`).
