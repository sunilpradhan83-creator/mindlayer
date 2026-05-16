---
id: ml-story-012
title: Migrate project signals to folder layout
status: ready
created: 2026-05-16
parent: ml-signal-20260516-003
agent: any
---

You are migrating this project's existing `.mindlayer/pipeline/signals.md` queue into the new folder-per-signal layout.

Prerequisites:
- `ml-story-009`, `ml-story-010`, and `ml-story-011` are done.

Target behavior:
- Every existing signal in `.mindlayer/pipeline/signals.md` becomes a file in `.mindlayer/pipeline/signals/`.
- Filenames use `<id>-<short-slug>.md`.
- `signals/index.md` lists every migrated signal.
- All ids, titles, statuses, legacy `tier` fields when present, `merged_into` provenance, and bodies are preserved.
- After migration, runtime commands use the folder layout as source of truth.
- Legacy `signals.md` should either be removed from active pipeline use or converted into a short migration note, depending on the tests and lint expectations.

Start by writing a deterministic migration test or fixture that proves no signal ids/statuses/provenance are lost. Then perform the project memory migration using the runtime/helpers where possible.

Allowed write scope:
- `src/commands/script.py` only if a tiny migration helper is needed
- `tests/ml/test-script.sh`
- `.mindlayer/pipeline/signals.md`
- `.mindlayer/pipeline/signals/`
- `.mindlayer/pipeline/stories/`

Do not alter unrelated backlog, roadmap, or knowledge entries except story status/proof updates.

Acceptance: `bash tools/test.sh` passes and `./src/ml script status` reads the migrated folder signals correctly.
