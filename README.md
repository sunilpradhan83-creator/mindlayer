# MindLayer

Memory as intelligence for AI-native developers.

MindLayer is a markdown-first memory system for AI coding agents. It helps agents decide what to remember, where to store it, how to retrieve it efficiently, and how to avoid memory drift, duplication, unsafe overwrites, and hidden token bloat.

V1 is intentionally small: markdown files, prompt files, thin tool adapters, and a safe installer. No backend, no vector database, no embeddings, no editor extension.

## The Problem

AI coding agents are good at local reasoning but weak at durable project memory. Important decisions, preferences, risks, and current work often disappear into chat history or get duplicated across tool-specific instruction files.

MindLayer separates memory from adapters:

- Memory lives in predictable markdown files.
- Tool files only tell agents how to use that memory.
- Retrieval starts with compact indexes before loading full sections.
- Writes require explicit approval.

## Philosophy

Memory is not a dump of everything that happened. Memory is curation, routing, retrieval, and lifecycle.

Good memory should be:

- durable enough to matter later
- compact enough to keep token usage low
- routed to the right file
- indexed for discovery
- updated instead of duplicated
- safe to commit when it belongs to the project

## Quick Install

Remote install:

```sh
curl -fsSL https://raw.githubusercontent.com/<USER>/mindlayer/main/install.sh | bash
```

Local install:

```sh
bash install.sh --project .
```

Then open your AI coding tool and run:

```text
/m-init
```

## What Gets Installed

Global memory is created at:

```text
~/.mindlayer/
```

Project memory is created at:

```text
./.mindlayer/
```

Adapters are created or updated safely:

```text
AGENTS.md
CLAUDE.md
.github/copilot-instructions.md
```

The installer only creates missing memory files. Existing files are preserved. Adapter files are updated only inside the `<!-- mindlayer:start -->` and `<!-- mindlayer:end -->` block.

## Global vs Project Memory

Global memory is for stable cross-project preferences, habits, reusable workflows, principles, anti-patterns, and prompt templates.

Project memory is for the current project: identity, progress, decisions, context, backlog, risks, and index.

MindLayer tries to link project `.mindlayer/memory.md` to `~/.mindlayer/memory.md`. If the symlink fails, it writes a pointer file instead. It never duplicates global memory into project memory.

## Commands

MindLayer V1 uses prompt files, not a CLI runtime:

- `/m-init` initializes an AI session with minimal useful memory context.
- `/m-retrieve <query>` fetches specific memory using indexes first.
- `/m-save` proposes memory writes and waits for approval.
- `/m-status` checks memory health and suggests fixes.

Prompt sources live in [`prompts/`](prompts/).

## File Structure

```text
global-template/      starter files for ~/.mindlayer/
project-template/     starter files for project .mindlayer/
prompts/              command prompts for AI tools
docs/                 concepts and operating guidance
examples/             sample project memory
.mindlayer/           MindLayer's own project memory
```

## Git Strategy

Commit project intelligence:

```text
.mindlayer/project.md
.mindlayer/progress.md
.mindlayer/decisions.md
.mindlayer/context.md
.mindlayer/backlog.md
.mindlayer/risks.md
.mindlayer/index.md
```

Ignore personal, private, generated, and session memory:

```text
.mindlayer/memory.md
.mindlayer/local.md
.mindlayer/private/
.mindlayer/sessions/
.mindlayer/cache/
.mindlayer/tmp/
```

Do not ignore the entire `.mindlayer` directory.

## Tool Usage

Codex and other agentic coding tools should read [`AGENTS.md`](AGENTS.md).

Claude Code should use [`CLAUDE.md`](CLAUDE.md) as a thin adapter that points back to `AGENTS.md`.

GitHub Copilot should use [`.github/copilot-instructions.md`](.github/copilot-instructions.md) as a thin adapter and avoid modifying memory files unless explicitly requested.

## Safety Guarantees

The installer does not:

- overwrite existing memory files
- overwrite existing adapter files
- overwrite `.gitignore`
- delete files
- move files
- clean or archive files
- modify content outside MindLayer marker blocks
- duplicate global memory into project memory

## V1 Limitations

- No CLI command implementation.
- No backend service.
- No vector search or embeddings.
- No VS Code extension.
- No automatic archive or cleanup behavior.
- Memory quality still depends on agent discipline and user approval.

## Roadmap

- V2 CLI for project initialization, status checks, and memory routing.
- Optional archive workflow.
- Optional local search helpers.
- VS Code extension later.
- Optional vector search later.
- SaaS/product exploration later.

## Testing

Run:

```sh
bash install.sh --project .
bash install.sh --project . --no-onboard
```

Expected behavior:

- first run creates missing global and project files
- repeated runs preserve existing memory
- adapter files contain exactly one MindLayer marked block
- `.gitignore` contains the local/private MindLayer rules once

