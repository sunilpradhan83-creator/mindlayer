---
id: ml-story-003
title: Update root index.md to pointer format and deprecate index-full.md
status: ready
created: 2026-05-14
parent: hierarchical-index-tree
agent: any
---

You are restructuring `.mindlayer/index.md` to be a pointer-only root index and creating
`knowledge/index.md` and `pipeline/index.md` as subfolder indexes.

Depends on ml-story-001 (recursive loader) and ml-story-002 (decisions/ split) being done first.

Current state: root `index.md` lists all 44 individual entries directly.

Target state:

**`.mindlayer/index.md`** — pointer-only, ~10 lines:
```
# Project Memory Index

Boot summary. Pointers to subfolder indexes.

- ml-index-ptr-knowledge | Knowledge Index | knowledge/index.md | Index for knowledge/ subfolder
- ml-index-ptr-pipeline | Pipeline Index | pipeline/index.md | Index for pipeline/ subfolder
```

**`.mindlayer/knowledge/index.md`** — summary index for knowledge/ files + pointer to decisions/:
```
- ml-index-ptr-decisions | Decisions Index | decisions/index.md | Index for decisions/ subfolder
- ml-project-20260430-001 | Project Identity | project.md | Markdown-first memory system for AI-native devs.
- ml-20260430-004 | Product Philosophy | context.md | Token efficiency; memory is curation.
- ml-20260430-006 | Trust Risks | risks.md | Token, routing, installer, onboarding, adapter risks.
... (all knowledge/ non-decision entries)
```

**`.mindlayer/pipeline/index.md`** — summary index for pipeline/ files:
```
- ml-20260430-005 | Future Roadmap | backlog.md | Active V4 foundation work.
- ml-20260505-006 | Current Phase | progress.md | V4 foundation complete; ml script shipped.
- ml-20260505-003 | Product Roadmap | roadmap.md | V4 SCRIPT runtime and IDE path.
- ml-20260506-002 | Project Router | router.md | Project conditional load triggers.
... (all pipeline/ entries)
```

**`index-full.md`** — rename to `index-full.md.deprecated` or delete. Remove from `.gitignore` check if present.

Start by writing failing tests in `tests/ml/test-load.sh` that verify:
- Root `index.md` contains only pointer lines (no leaf entry ids directly).
- `ml load project` resolves through root → knowledge/index.md → project.md entry.
- `ml load progress` resolves through root → pipeline/index.md → progress.md entry.
- `ml load script` resolves root → knowledge/index.md → decisions/index.md → script-v4.md entry.
- `index-full.md` is not loaded.

Then implement the file restructuring.

Do not modify `_index.py`, lint, or `_paths.py`.

Acceptance: all tests pass (`bash tools/test.sh`). Root `index.md` has only pointer entries. `index-full.md` is gone.
