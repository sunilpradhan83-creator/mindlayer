# MindLayer

Human-approved, git-trackable memory for AI coding agents.

MindLayer gives AI coding agents a safe, predictable place to store and retrieve durable context — project decisions, preferences, progress, risks, and backlog — without stuffing everything into chat history or tool-specific instruction files.

It is intentionally small: markdown files, a local `ml` command runner, thin tool adapters, and a safe installer. No backend, no embeddings, no vector database, no editor extension.

> **0.1 Developer Preview.** MindLayer is usable for early adopters who want to dogfood it, but it is not a polished stable release. Expect rough edges and breaking changes before 1.0.

## Why

AI coding agents are useful in the moment but lose the durable context that makes a project coherent over time. The usual workarounds — pasting notes into the system prompt, duplicating facts across tool-specific files, or relying on chat compaction — all drift, bloat, or disappear across sessions.

MindLayer fixes this by:

- keeping project memory in plain markdown, committed to git alongside the code
- separating global preferences (`~/.mindlayer/`) from project facts (`.mindlayer/`)
- loading from indexes first, not from full files
- requiring explicit human approval before any memory write
- preserving existing content on reinstall

Good memory is curated, indexed, compact, and approval-gated. Not a chat dump.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/sunilpradhan83-creator/mindlayer/main/install.sh | bash
```

Or from a local clone:

```sh
bash install.sh --project .
```

Then open your AI coding tool. MindLayer-aware adapters boot minimal context automatically when the host supports tool preflight, or before the first project-relevant request as a fallback.

## How It Works

MindLayer creates two memory layers:

```text
~/.mindlayer/      global memory — shared across all projects
./.mindlayer/      project memory — committed to the repo
```

Global memory stores user-owned preferences, habits, principles, reusable workflows, and anti-patterns. Project memory stores project identity, progress, decisions, context, backlog, risks, and an index.

Tool adapters stay thin and are not memory stores:

```text
AGENTS.md
CLAUDE.md
.github/copilot-instructions.md
GEMINI.md
.cursor/rules/mindlayer.md
.windsurf/rules/mindlayer.md
```

## Commands

MindLayer installs a local `ml` command runner plus markdown command specs that define expected behavior:

- `ml boot` — print the session boot receipt with minimal useful memory context.
- `ml load <query>` — fetch specific memory using ranked index matches first. `ml retrieve <query>` is an alias.
- `ml save` — propose durable memory writes and wait for approval.
- `ml status` — check memory health and suggest fixes.
- `ml diff` — show project memory changes since the last session commit.
- `ml clean` — review stale memory and propose archive or delete actions.
- `ml session` — report session context cost and recommend compact or a fresh session.
- `ml script` — run the SCRIPT lifecycle commands (Signal → Cut → Refine → Implement → Prove → Transfer).
- `ml onboard` — help populate MindLayer when installing into an existing project.

Command specs live in `~/.mindlayer/memory-system/commands/` after install and ship from [`global-template/memory-system/commands/`](global-template/memory-system/commands/).

## Effective Use

Boot loads `~/.mindlayer/boot.md`, `~/.mindlayer/router.md`, the project router, `~/.mindlayer/memory-system/per-turn.md`, indexes, substantive user preferences, project identity, and current progress. Starter-only placeholders are skipped.

Use `ml load <query>` instead of loading every memory file. Loading starts from indexes and loads only relevant sections.

Use `ml save` after durable learning happens — new decisions, stable preferences, meaningful progress, risks, reusable workflows, or backlog items. MindLayer proposes writes first and only saves after approval.

Use `ml status` when memory feels stale, duplicated, oversized, or inconsistent.

## Session Strategy

MindLayer makes new sessions cheap. Boot loads the minimum useful context regardless of how long the previous session was.

Prefer starting a new session at each task boundary: save progress with `ml save`, finish the task, and start fresh. The next session boots from durable memory, not from chat history.

Use `/compact` only when mid-task and hitting the context limit with active work still in progress. A new session has zero history overhead; compaction adds per-message cost for every message that follows.

This pattern works across all agents — Claude, Cursor, Codex, Copilot, and any LLM-backed tool. Durable memory is what makes new sessions viable.

## Best Practices

- Do not use `README.md` or `docs/` as memory input.
- Do not dump raw conversations into memory.
- Prefer updating existing memory over creating duplicates.
- Keep user-owned global preferences in `~/.mindlayer/preferences/personal.md`.
- Keep project facts in `.mindlayer/` and commit them.
- Keep tool-specific adapter files thin.

Commit:

```text
.mindlayer/index.md
.mindlayer/router.md
.mindlayer/knowledge/index.md
.mindlayer/knowledge/project.md
.mindlayer/knowledge/context.md
.mindlayer/knowledge/risks.md
.mindlayer/knowledge/decisions/index.md
.mindlayer/knowledge/decisions/*.md
.mindlayer/pipeline/index.md
.mindlayer/pipeline/progress.md
.mindlayer/pipeline/backlog.md
.mindlayer/pipeline/roadmap.md
```

Ignore:

```text
.mindlayer/local.md
.mindlayer/private/
.mindlayer/knowledge/sessions/
.mindlayer/cache/
.mindlayer/tmp/
```

Do not ignore the entire `.mindlayer/` directory.

## Global Backup

`~/.mindlayer/` is outside project Git by design. It survives deleting or recloning a project, but project commits do not back it up.

Back it up with your normal dotfiles, encrypted backup, or a private personal repository. Do not store secrets, tokens, raw conversations, or project-specific facts in global memory.

## Safety

The installer creates missing files and preserves existing content. It may refresh managed system files (`~/.mindlayer/boot.md`, `~/.mindlayer/router.md`, `~/.mindlayer/memory-system/`, and canonical adapter templates) while preserving user-owned preferences and memory.

Project adapters are frozen full-file templates tracked by `.mindlayer/adapters.lock`. Reinstall refreshes an adapter only when its hash matches the lock. If an adapter contains user-added content, install refuses to overwrite it and asks you to route that content through MindLayer first.

The installer never overwrites user-owned memory files, deletes files, moves files, or duplicates global memory into project memory.

## Validation

Run the full test suite before contributing or releasing:

```sh
bash tools/test.sh
```

Runs memory/adapter lint, sandboxed install tests, behavior contract tests, and `ml` CLI contract tests.

Optional live agent dogfood:

```sh
# Claude (default)
tools/dogfood.sh

# Codex (requires bubblewrap on Linux: sudo apt install bubblewrap)
AGENT_RUNNER=tools/dogfood-runners/codex.sh tools/dogfood.sh
```

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md). Open an issue before writing code.

## Changelog

See [`CHANGELOG.md`](CHANGELOG.md).

## Roadmap

See [`ROADMAP.md`](ROADMAP.md) for the full product vision.
