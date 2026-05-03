# GitHub Copilot Adapter

Follow `AGENTS.md`.

Use MindLayer memory files for context when they are present. At the first meaningful interaction in this project, initialize minimal useful MindLayer context automatically using indexes first and report a compact context receipt. Do not use `README.md` or `docs/` as machine memory input. Do not treat this adapter as a memory store. Do not modify memory files unless explicitly requested by the user.

<!-- mindlayer:start -->
Follow `AGENTS.md`.

Use project `.mindlayer/` for project context. Use `~/.mindlayer/` for global user memory when available.

At the first meaningful interaction in this project, initialize minimal useful MindLayer context automatically using indexes first and report a compact context receipt.

Do not use `README.md` or `docs/` as memory input. Do not retrieve durable context from this adapter. Do not modify memory files unless explicitly requested. Keep generated changes minimal and safe.
<!-- mindlayer:end -->
