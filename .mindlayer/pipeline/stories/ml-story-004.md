---
id: ml-story-004
title: Update lint to follow pointer entries recursively
status: ready
created: 2026-05-14
parent: hierarchical-index-tree
agent: any
---

You are updating `tools/lint.sh` to follow pointer entries in index files recursively,
validating E3/E5/E6 on every subfolder index it reaches.

Depends on ml-story-001, ml-story-002, ml-story-003 being done first.

Current state: `lint_dir()` reads only the root index file and validates entries in it directly.
Pointer entries (file ending in `/index.md`) are not followed — they pass E5 (file exists) but
their referenced subfolder indexes are never validated.

Target behaviour:
1. When `parse_index()` returns an entry whose `file` ends with `/index.md`, treat it as a pointer.
2. Recursively call `lint_dir()` (or an equivalent inline check) on the pointed-to subfolder index.
3. E3 (required keys) applies to leaf entries only — pointer entries need only `id`, `title`, `file`.
4. E4 (duplicate ids) must be checked across the full resolved tree, not just per-file.
5. E5 (file exists) and E6 (section heading exists) apply to leaf entries only.
6. W1 (staleness), W2/W3 (size), W4 (placeholders) apply to each resolved leaf file.
7. Stop loading `index-full.md` in lint — it is deprecated.
8. Remove the `require_file` checks for canonical template files that no longer exist
   (e.g. if `decisions.md` is gone, remove its lint check).

Start by writing failing tests in `tests/lint/test-source-boundaries.sh` or a new
`tests/lint/test-index-tree.sh` that verify:
- A root index with a valid pointer to a subfolder index passes lint with no errors.
- A root index with a pointer to a non-existent subfolder index fails E5.
- A subfolder index with a missing-section entry fails E6.
- Duplicate ids across root and subfolder indexes fail E4.
- `index-full.md` presence does not cause lint errors (it is ignored now).

Then implement the lint changes.

Do not modify `_index.py`, `_paths.py`, or any memory files.

Acceptance: all tests pass (`bash tools/test.sh`). Lint reports 0 errors on the current repo state.
