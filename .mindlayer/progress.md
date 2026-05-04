# Progress

## Installer-First V1 Seed

id: ml-20260430-002
created: 2026-04-30
updated: 2026-05-04
scope: project
type: progress
tags: [v1, installer]
confidence: high
status: active
source: manual

### Summary
Current phase: installer-first V1 seed published; boot-first memory initialization is implemented and validated.

### Details
- Current phase: installer-first V1 seed project.
- Completed: created templates, prompts, docs, adapters, dogfood memory, and safe installer.
- Completed: local install was tested.
- Completed: idempotence was checked.
- Completed: `/m-init` and `/m-save` were validated.
- Completed: `/m-status` executed and duplicate id issue resolved.
- Completed: `/m-init` behavior refined and validated; it skips scaffold-only files and `local.md` by default.
- Completed: installer validated across local and fresh dummy project.
- Completed: seed repo committed as `2f0d64d Seed MindLayer V1`.
- Completed: GitHub repo published at `https://github.com/sunilpradhan83-creator/mindlayer`.
- Completed: manual `/m-init` dogfooding found that `~/.mindlayer/memory-system.md` could exist but remain unloaded/unreported when the global index lacked a `memory-system.md` entry.
- Completed: installer fallback index content was updated, existing global indexes are repaired when missing `memory-system.md`, the local global index was repaired, and readiness tests now verify both fresh installs and old existing global indexes include `file: memory-system.md`.
- Completed: boot-first initialization replaced `/m-init`-first workflow across adapters, installer output, templates, docs, prompts, and tests.
- Completed: MindLayer boot now requires loading `~/.mindlayer/memory-system.md` first, treats `/m-init` as a legacy/manual refresh alias, and does not treat plain greetings as project-relevant boot triggers.
- Completed: agent behavior tests now reject boot receipts that omit `~/.mindlayer/memory-system.md` from `Loaded:`.
- Completed: full `tools/test.sh` suite passed with install readiness and boot contract validation.
- Completed: manual command dogfooding confirmed `/m-init` works as a legacy/manual refresh alias and `/m-save` proposes memory writes without writing automatically.
- Completed: commit `e4f4e6c` clarified global preferences as user-owned cross-project memory, made starter-only preferences skipped during boot, added backup guidance for `~/.mindlayer/`, preserved user preferences on reinstall, and refreshed managed `memory-system.md` on reinstall.
- Next step: reinstall locally, inspect live `~/.mindlayer/memory-system.md` and `~/.mindlayer/preferences.md`, then start a fresh session to verify greeting/no-boot and project-question/boot behavior.

### When to use
Use during MindLayer boot to understand the current project state.

### Related
ml-project-20260430-001
