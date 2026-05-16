---
id: ml-story-005
title: Make story id generation archive-aware
status: ready
created: 2026-05-16
parent: ml-signal-20260516-005
agent: any
---

You are fixing SCRIPT story id allocation so Refine never reuses ids that already exist in `pipeline/archive/`.

Current state:
- Active `pipeline/stories/` can be empty after Transfer.
- Archived story files can still exist in `pipeline/archive/`.
- `src/commands/script.py` currently chooses the next id by scanning only active `pipeline/stories/`, which would recreate `ml-story-001` after archived stories `001-004`.

Start by writing failing CLI contract tests in `tests/ml/test-script.sh` that:
- create archived `ml-story-001.md` through `ml-story-004.md`,
- leave active `pipeline/stories/` empty except `index.md`,
- run `ml script refine --approve`,
- prove the created story is `ml-story-005.md`,
- prove `pipeline/stories/index.md` references `ml-story-005`,
- prove no archived story file is overwritten.

Then implement the smallest runtime change, likely in `_next_story_id`, to scan both `pipeline/stories/` and `pipeline/archive/` for `ml-story-NNN.md` files.

Allowed write scope:
- `src/commands/script.py`
- `tests/ml/test-script.sh`

Do not change signal processing behavior in this story.

Acceptance: `bash tools/test.sh` passes.
