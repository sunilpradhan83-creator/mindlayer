# MindLayer

Memory as intelligence for AI-native developers.

MindLayer is a markdown-first memory system for AI coding agents. It gives agents a safe, predictable way to remember durable preferences, project context, decisions, progress, risks, and next steps without stuffing everything into chat history or tool-specific instruction files.

V1 is intentionally small: markdown files, prompt files, thin tool adapters, and a safe installer. No backend, no embeddings, no vector database, and no editor extension.

## Why MindLayer

AI coding agents are useful in the moment, but they often lose the durable context that makes a project coherent over time.

MindLayer helps by:

- separating memory from tool adapters
- keeping user-owned global preferences separate from project facts
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

Then open your AI coding tool. MindLayer-aware adapters boot minimal context automatically when the host supports tool preflight, or before the first project-relevant request as a fallback.

## How It Works

MindLayer creates two memory layers:

```text
~/.mindlayer/      global memory shared across projects
./.mindlayer/      project memory for the current repo
```

Global memory stores user-owned cross-project preferences, habits, principles, reusable workflows, anti-patterns, and prompt patterns.

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

- MindLayer boot: initialize the session with minimal useful memory context.
- `/m-retrieve <query>`: fetch specific memory using indexes first.
- `/m-save`: propose durable memory writes and wait for approval.
- `/m-status`: check memory health and suggest fixes.

Prompt sources live in [`prompts/`](prompts/).

## Effective Use

MindLayer boot should load `~/.mindlayer/memory-system.md` first, then indexes, substantive user preferences when present, project identity, and current progress. Starter-only preferences are skipped. `/m-init` remains a legacy/manual refresh alias for showing or rerunning the boot receipt.

Use `/m-retrieve <query>` instead of loading every memory file. Retrieval should start from indexes and load only relevant sections.

Use `/m-save` after durable learning happens: new decisions, stable preferences, meaningful progress, risks, reusable workflows, or backlog items. MindLayer should propose writes first and only save after approval.

Use `/m-status` when memory feels stale, duplicated, oversized, or inconsistent.

## Session Strategy

MindLayer makes new sessions cheap. Boot loads the minimum useful context — command rules, indexes, substantive preferences, project identity, and current progress — regardless of how long the previous session was.

Prefer starting a new session at each task boundary over compacting mid-session. Save progress with `/m-save`, finish the task, and start fresh. The next session boots from durable memory, not from chat history.

Use `/compact` only when mid-task and hitting the context limit with active work still in progress. Compacting preserves history at a cost: every subsequent message in that session pays for the summary. A new session has zero history overhead.

This pattern works across all agents — Claude, ChatGPT, Cursor, Copilot, and any LLM-backed tool. Durable memory is what makes new sessions viable; without it, every session restart means re-explaining everything.

## Best Practices

- Do not use `README.md` as memory input.
- Do not dump raw conversations into memory.
- Prefer updating existing memory over creating duplicates.
- Keep user-owned global preferences in `~/.mindlayer/preferences.md`.
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

## Global Backup

`~/.mindlayer/` is outside project Git by design. It survives deleting or recloning a project, but project commits do not back it up.

Back up `~/.mindlayer/` with your normal dotfiles, encrypted backup, or private personal repository if you want cross-project preferences and global memory preserved across machine loss. Do not store secrets, tokens, raw conversations, or project-specific facts in global preferences.

## Safety

The installer creates missing files and preserves existing content. It may refresh managed MindLayer system instructions such as `~/.mindlayer/memory-system.md`, while preserving user-owned global preferences. Adapter files are updated only inside the MindLayer marker block:

```text
<!-- mindlayer:start -->
...
<!-- mindlayer:end -->
```

The installer does not overwrite user-owned memory files, delete files, move files, clean/archive memory, or duplicate global memory into project memory.

## Roadmap

See [`ROADMAP.md`](ROADMAP.md) for the full product vision across versions.

## Validation

Run the local validation suite before release or deploy:

```sh
tools/test.sh
```

It runs memory/adapters linting, sandboxed install readiness tests for fresh and existing projects, and boot receipt contract tests.

For an opt-in real Codex CLI dogfood check:

```sh
tools/dogfood-codex-boot.sh
```

This depends on local Codex auth, model availability, and network access.

