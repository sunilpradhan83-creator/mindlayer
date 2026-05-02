# MindLayer

Memory as intelligence for AI-native developers.

MindLayer is a markdown-first memory system for AI coding agents. It gives agents a safe, predictable way to remember durable preferences, project context, decisions, progress, risks, and next steps without stuffing everything into chat history or tool-specific instruction files.

V1 is intentionally small: markdown files, prompt files, thin tool adapters, and a safe installer. No backend, no embeddings, no vector database, and no editor extension.

## Why MindLayer

AI coding agents are useful in the moment, but they often lose the durable context that makes a project coherent over time.

MindLayer helps by:

- separating memory from tool adapters
- keeping global preferences separate from project facts
- using indexes before loading full memory files
- requiring explicit approval before memory writes
- preserving existing files during install
- reducing token bloat, duplication, and memory drift

Good memory is not a chat dump. It is curated, routed, indexed, compact, and maintained.

## Install

Remote install:

```sh
curl -fsSL https://raw.githubusercontent.com/sunilpradhan83-creator/mindlayer/main/install.sh | bash
```

Local install:

```sh
bash install.sh --project .
```

Then open your AI coding tool and run:

```text
/m-init
```

## How It Works

MindLayer creates two memory layers:

```text
~/.mindlayer/      global memory shared across projects
./.mindlayer/      project memory for the current repo
```

Global memory stores stable cross-project preferences, habits, principles, reusable workflows, anti-patterns, and prompt patterns.

Project memory stores project identity, progress, decisions, context, backlog, risks, and an index.

Tool adapters stay thin:

```text
AGENTS.md
CLAUDE.md
.github/copilot-instructions.md
```

They tell tools how to use MindLayer, but they are not memory stores.

## Commands

MindLayer V1 uses prompt files, not a CLI runtime:

- `/m-init`: initialize the session with minimal useful memory context.
- `/m-retrieve <query>`: fetch specific memory using indexes first.
- `/m-save`: propose durable memory writes and wait for approval.
- `/m-status`: check memory health and suggest fixes.

Prompt sources live in [`prompts/`](prompts/).

## Effective Use

Start a session with `/m-init` when project memory matters.

Use `/m-retrieve <query>` instead of loading every memory file. Retrieval should start from indexes and load only relevant sections.

Use `/m-save` after durable learning happens: new decisions, stable preferences, meaningful progress, risks, reusable workflows, or backlog items. MindLayer should propose writes first and only save after approval.

Use `/m-status` when memory feels stale, duplicated, oversized, or inconsistent.

## Best Practices

- Do not use `README.md` as memory input.
- Do not dump raw conversations into memory.
- Prefer updating existing memory over creating duplicates.
- Keep global preferences in `~/.mindlayer/`.
- Keep project facts in `.mindlayer/`.
- Keep tool-specific files thin.
- Commit shared project memory.
- Ignore personal, private, generated, and session memory.

Commit:

```text
.mindlayer/project.md
.mindlayer/progress.md
.mindlayer/decisions.md
.mindlayer/context.md
.mindlayer/backlog.md
.mindlayer/risks.md
.mindlayer/index.md
```

Ignore:

```text
.mindlayer/local.md
.mindlayer/private/
.mindlayer/sessions/
.mindlayer/cache/
.mindlayer/tmp/
```

Do not ignore the entire `.mindlayer/` directory.

## Safety

The installer creates missing files and preserves existing content. Adapter files are updated only inside the MindLayer marker block:

```text
<!-- mindlayer:start -->
...
<!-- mindlayer:end -->
```

The installer does not overwrite memory files, delete files, move files, clean/archive memory, or duplicate global memory into project memory.

## Validation

Run the local validation suite before release or deploy:

```sh
tools/test.sh
```

It runs memory/adapters linting and a sandboxed install readiness test for fresh and existing projects.

## Learn More

- [Concepts](docs/concepts.md)
- [Install](docs/install.md)
- [File routing](docs/file-routing.md)
- [Git strategy](docs/git-strategy.md)
- [Lifecycle](docs/lifecycle.md)
- [Token strategy](docs/token-strategy.md)
- [Tool adapters](docs/tool-adapters.md)
