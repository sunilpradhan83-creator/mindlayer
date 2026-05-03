# MindLayer Agent Instructions

MindLayer is a markdown-first memory system for AI-native software developers. It separates durable memory from tool-specific instruction files.

Global user memory lives at:

```text
~/.mindlayer/
```

Project memory lives at:

```text
project/.mindlayer/
```

Tool adapters such as `AGENTS.md`, `CLAUDE.md`, and `.github/copilot-instructions.md` are not memory stores. They are thin instructions for using MindLayer and should not be used as durable retrieval sources beyond these instructions.

Human documentation such as `README.md` and `docs/` explains the tool for people. It is not default AI memory input.

## Commands

- `/m-init`: initialize the session with minimal useful memory context.
- `/m-retrieve <query>`: fetch specific memory on demand using indexes first.
- `/m-save`: analyze recent work and propose memory writes. Never write without approval.
- `/m-status`: check memory health and suggest fixes.

## Rules

- Do not use `README.md` or `docs/` as memory input.
- Do not write memory without explicit user approval.
- Use index files before loading full memory files.
- Prefer updating existing memory over creating duplicates.
- Keep token usage transparent: state what was loaded and skipped.
- Do not dump raw conversations into memory.
- Route global preferences to `~/.mindlayer/`.
- Route project facts, decisions, progress, risks, and backlog to `project/.mindlayer/`.
- Keep tool-specific files thin. Do not duplicate memory into adapters or retrieve durable context from adapters.
- Go outside MindLayer memory only when necessary for the task.

At the first meaningful interaction in a project, initialize minimal useful MindLayer context automatically. When memory is needed, use `/m-retrieve`. When saving memory, use `/m-save`. For health checks, use `/m-status`. Use `/m-init` when the user asks to refresh or show initialization context.


<!-- mindlayer:start -->
MindLayer memory is stored outside this adapter.

Global memory: `~/.mindlayer/`
Project memory: `.mindlayer/`

At the first meaningful interaction in this project, initialize minimal useful MindLayer context automatically. Read command rules and indexes first, then load only essential global preferences, project identity, and current progress. Report a compact context receipt with loaded, skipped, missing, current understanding, current progress, and rough word or token cost.

Use `/m-init` when the user asks to refresh or show initialization context.
Use `/m-retrieve <query>` when specific memory is needed.
Use `/m-save` only to propose memory writes; never write without approval.
Use `/m-status` to check memory health.

Rules:
- Do not use `README.md` or `docs/` as memory input.
- Use index files before full files.
- Prefer update over duplicate.
- Keep token usage transparent.
- Do not dump raw conversations into memory.
- Keep adapters thin; do not store or retrieve durable memory here.
- Go outside MindLayer memory only when necessary for the task.
<!-- mindlayer:end -->
