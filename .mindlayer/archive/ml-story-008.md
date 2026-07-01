---
id: ml-story-008
title: Merge agent drift signals into processing enforcement plan
status: done
proved_by: bash tools/test.sh
proved_at: 2026-05-16
started_from: b191772
created: 2026-05-16
parent: ml-signal-20260516-005
agent: any
---

You are folding `ml-signal-20260516-002` and `ml-signal-20260516-004` into one enforcement plan for per-turn footer drift.

Current state:
- `ml-signal-20260516-002` reports Token Burned footer format drift.
- `ml-signal-20260516-004` reports Next Step rule-chain drift.
- The approved Cut for `ml-signal-20260516-005` says these share one root cause and should merge before routing.

Target behavior:
- The signal processing workflow can represent merged/correlated signals without losing provenance.
- The resulting backlog/story plan treats Token Burned format and Next Step priority-chain enforcement as one implementation concern.
- Dependent `ml-signal-20260516-003` remains blocked until this signal processing model is implemented.

Start by writing failing tests or contract checks at the lowest useful level. Prefer CLI tests if merge/provenance is represented in `ml script`; otherwise add deterministic lint/status coverage that proves merged signal ids remain visible and no longer appear as separate ready-to-route work after approval.

Then implement the smallest change needed to represent and surface merged signal provenance.

Allowed write scope:
- `src/ml`
- `src/commands/script.py`
- `tests/ml/test-script.sh`
- `.mindlayer/pipeline/signals.md` only for the approved status/provenance updates required by this story

Do not solve the actual Token Burned footer enforcement in this story unless the signal processing model needs a tiny validator hook to prove merge behavior.

Acceptance: `bash tools/test.sh` passes, and `ml script status` no longer makes `002` and `004` look like independent unprocessed work once they are merged under `005`.
