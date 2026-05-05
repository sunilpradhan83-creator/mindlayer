# GitHub Copilot Adapter

Follow `AGENTS.md`.

Use MindLayer memory files for context when they are present. Run MindLayer boot at session start or before the first project-relevant request. Read `~/.mindlayer/memory-system.md` first when available, then indexes. Do not use `README.md` or `docs/` as AI memory input. Do not treat this adapter as a memory store. Do not modify memory files unless explicitly requested by the user.

<!-- mindlayer:start -->
Follow `AGENTS.md`.

Use project `.mindlayer/` for project context. Use `~/.mindlayer/` for global user memory when available.

Run MindLayer boot at session start or before the first project-relevant request. Read `~/.mindlayer/memory-system.md` first when available, then indexes, and report a compact context receipt when visible to the user.

Do not use `README.md` or `docs/` as memory input. Do not retrieve durable context from this adapter. Do not modify memory files unless explicitly requested. Keep generated changes minimal and safe.

MindLayer boot is cheap — prefer starting a new session at each task boundary over compacting mid-session.
<!-- mindlayer:end -->
