# MindLayer Agent Instructions

Memory lives in `~/.mindlayer/` (global) and `.mindlayer/` (project). Adapters and docs are not memory sources.

If no preflight hook exists, run the full boot sequence and emit the boot receipt BEFORE answering the first project-relevant request, including any question about what the project is, what it does, or what is in it. Never answer a project question without booting first. Never ask the user if they want you to boot; just boot. Do not treat a plain greeting as project-relevant.

Boot order:
1. Read `~/.mindlayer/boot.md` first when available.
2. Read `~/.mindlayer/router.md` and follow its load triggers.
3. Read `.mindlayer/index.md` — project memory catalog.
4. Load project identity and current progress.

Commands and proactive behavior: see `~/.mindlayer/memory-system/per-turn.md`.
