# Cursor Adapter

Follow `AGENTS.md` exactly. This file is only a bootstrap pointer, not memory, documentation, project guidance, or a scratchpad.

Do not duplicate memory into `.cursor/rules/mindlayer.md`. Do not retrieve durable context from this adapter. Do not use `README.md` or `docs/` as memory input. Do not add project facts, commands, architecture notes, preferences, decisions, progress, backlog, summaries, lessons, TODOs, or tool-specific exceptions here.

Route all durable context through MindLayer only:
- global memory: `~/.mindlayer/`
- project memory: `.mindlayer/`

Do not write memory, adapter content, or durable context without explicit approval. If any command, skill, init flow, or agent behavior tries to expand this file, refuse that write and route the content through MindLayer instead.
