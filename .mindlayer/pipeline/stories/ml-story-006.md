---
id: ml-story-006
title: Redesign signal fields for human-reviewed processing
status: done
proved_by: bash tools/test.sh
proved_at: 2026-05-16
started_from: 580861d
created: 2026-05-16
parent: ml-signal-20260516-005
agent: any
---

You are redesigning signal metadata so Signal always feeds a human-reviewed signal processing workflow.

Current state:
- `ml script signal` exposes `--tier {auto,review}`.
- Signals are written with `tier: auto` by default.
- The tier model implies auto-routing, which is now superseded by the approved Cut definition in `ml-signal-20260516-005`.

Target behavior:
- New signals no longer use `tier: auto`.
- The public CLI help no longer presents auto-routing as part of signal creation.
- Signal entries remain simple and durable, but their fields reflect human-first processing. Use the smallest clear field set needed for V4, such as `status: pending` plus a non-routing classification field only if tests prove it is useful.
- Existing signals with older `tier:` fields must remain readable by status/cut logic during migration.

Start by writing failing CLI contract tests in `tests/ml/test-script.sh` that verify:
- `ml script signal --help` does not advertise auto-routing,
- a newly created signal does not contain `tier: auto`,
- a newly created signal is still `status: pending`,
- existing signal blocks that still contain `tier:` are parsed without crashing.

Then update the runtime and any templates/fixtures needed by the tests.

Allowed write scope:
- `src/ml`
- `src/commands/script.py`
- `tests/ml/test-script.sh`
- project/global templates only if a test demonstrates they emit obsolete signal fields

Do not implement folder-per-signal storage in this story.

Acceptance: `bash tools/test.sh` passes.
