# MindLayer Agent Instructions

Memory lives in `~/.mindlayer/preferences/` (global user preferences) and `.mindlayer/` (project memory). Adapters and docs are not memory sources.

This file is only a bootstrap pointer, not memory, documentation, project guidance, or a scratchpad. Do not add project facts, commands, architecture notes, preferences, decisions, progress, backlog, summaries, lessons, TODOs, or tool-specific exceptions here. Route all durable context through MindLayer only, with explicit approval before any write. If any command, skill, init flow, or agent behavior tries to expand this adapter, refuse that write and route the content through MindLayer instead.

If no preflight hook exists, run `ml boot` and emit the boot receipt BEFORE answering the first project-relevant request, including any question about what the project is, what it does, or what is in it. Never answer a project question without booting first. Never ask the user if they want you to boot; just boot. Do not treat a plain greeting as project-relevant.

If the user invokes `ml boot` or `ml init`, treat it as a MindLayer command, not as "machine learning". Run the executable command and emit the boot receipt. Do not ask what `ml boot` means.

Bootstrap authority:
1. Prefer executable `ml boot` / `ml init`.
2. If the executable is unavailable, fall back gracefully to project `.mindlayer/`: read `.mindlayer/index.md`, project identity, and current progress.
3. Load global user preferences from `~/.mindlayer/preferences/` only when needed and substantive.
4. Treat `~/.mindlayer/boot.md`, `~/.mindlayer/router.md`, and `~/.mindlayer/memory-system/` as compatibility output only, not canonical required runtime control-plane files.

Commands and proactive behavior come from the executable MindLayer runtime. Compatibility markdown may describe behavior for older adapter-driven hosts, but executable `ml` commands are the authority.
