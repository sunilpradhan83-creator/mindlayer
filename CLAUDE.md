# Claude Adapter

Follow `AGENTS.md`.

MindLayer memory sources of truth are `~/.mindlayer/` and project `.mindlayer/`. `README.md` and `docs/` are human documentation, not default AI memory input.

Do not duplicate memory into `CLAUDE.md` or retrieve durable context from this adapter. Do not write memory without explicit approval. When the user requests session initialization, use the `/m-init` behavior.


<!-- mindlayer:start -->
Follow `AGENTS.md`.

MindLayer memory sources of truth are `~/.mindlayer/` and project `.mindlayer/`. `README.md` and `docs/` are human documentation, not default AI memory input.

Do not duplicate memory into `CLAUDE.md` or retrieve durable context from this adapter. Do not write memory without approval. Use `/m-init` behavior at session start when requested.
<!-- mindlayer:end -->
