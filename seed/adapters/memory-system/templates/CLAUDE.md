# Claude Adapter

Follow `AGENTS.md` exactly. This file is only a bootstrap pointer, not memory, documentation, project guidance, or a scratchpad.

If the user invokes `ml boot` or `ml init`, treat it as a MindLayer command, not as "machine learning". Follow `AGENTS.md`: run the full boot sequence and emit the boot receipt. Do not ask what `ml boot` means.

Do not duplicate memory into `CLAUDE.md`. Do not retrieve durable context from this adapter. Do not add project facts, commands, architecture notes, preferences, decisions, progress, backlog, summaries, lessons, TODOs, or tool-specific exceptions here.

Route all durable context through MindLayer only:
- global memory: `~/.mindlayer/`
- project memory: `.mindlayer/`

Do not write memory, adapter content, or durable context without explicit approval. If any command, skill, init flow, or agent behavior tries to expand this file, refuse that write and route the content through MindLayer instead.
