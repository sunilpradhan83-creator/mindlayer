# ADR-0001: MindLayer Memory and Runtime Architecture

id: ml-adr-0001
date: 2026-06-30
status: accepted
scope: project
type: architecture
tags: [architecture, memory-layout, runtime, install, mcp, adapters, reliability]
confidence: high
source: conversation

## Context

MindLayer's core promise is reliable, human-approved, git-trackable memory for AI coding agents. The current implementation proves the direction, but it mixes concerns:

- Global scope contains both user memory and shipped runtime markdown.
- Project memory contains useful structure, but too many starter files can create maintenance weight before real content exists.
- Router behavior is instruction-driven markdown, which is useful as documentation but not reliable enough for zero-drift execution.
- Agent adapters can accidentally become memory, documentation, or scratchpads unless they stay thin and frozen.
- Future MCP exposure needs a clean distinction between resources, prompts, and executable tools.

The target architecture must keep the one-command install experience while separating memory, executable behavior, generated runtime state, and adapter bootstraps.

## Decision

MindLayer will use four explicit planes:

1. **Project memory plane**: `.mindlayer/`
2. **User preference plane**: `~/.mindlayer/preferences/`
3. **Executable runtime plane**: installed MindLayer code and commands
4. **Adapter plane**: thin bootstrap files such as `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, Cursor, Copilot, and Windsurf adapters

Markdown is allowed to store resources, prompts, decisions, work state, and human-readable context. Markdown must not be the authority for deterministic behavior. Routing, install behavior, safety checks, indexing, validation, and write operations must be implemented in executable code and covered by verification.

## Target Project Layout

A fresh project install creates only structural files that are immediately useful:

```text
project/
├── .mindlayer/
│   ├── index.md
│   ├── knowledge/
│   │   ├── index.md
│   │   ├── project.md
│   │   └── decisions/
│   │       └── index.md
│   ├── work/
│   │   ├── index.md
│   │   └── current.md
│   └── archive/
│       └── index.md
├── AGENTS.md
├── CLAUDE.md
├── GEMINI.md
└── other detected adapter files
```

Do not create empty future-volume folders by default. The runtime creates these lazily when real content exists:

- `.mindlayer/work/sessions/`
- `.mindlayer/work/signals/`
- `.mindlayer/work/stories/`
- `.mindlayer/prompts.md` or `.mindlayer/prompts/`
- `.mindlayer/archive/archive.md`
- `.mindlayer/local.md`

## Project Memory Rules

`.mindlayer/` is the project resource root. Do not add a nested `.mindlayer/resources/` directory; that repeats the same concept.

Use these domains:

- `.mindlayer/knowledge/`: stable project truth, identity, context, risks, and accepted decisions.
- `.mindlayer/knowledge/decisions/`: ADRs and decision indexes.
- `.mindlayer/work/`: active and recent work state.
- `.mindlayer/work/current.md`: current state, active signals, and immediate next work.
- `.mindlayer/work/sessions/`: session continuity, created lazily and normally gitignored.
- `.mindlayer/archive/`: retired durable truth, completed work, superseded decisions, and promoted historical material.

Sessions belong under `work/`, not `knowledge/`, because they are continuity state. Promote durable conclusions from sessions into `knowledge/decisions/` or other knowledge files.

`local.md` is not created by default. Machine-specific notes belong in global preferences when they are user preferences, or in an explicit gitignored local file only when project-specific and intentionally private.

### Mapping From Current Layout

The current `pipeline/` layout migrates into `work/` by consolidation, not by one-to-one renaming every file:

- `pipeline/progress.md`, `pipeline/backlog.md`, and `pipeline/signals.md` collapse into sections inside `work/current.md`.
- `pipeline/signals/` becomes `work/signals/` only when signals need separate files.
- `pipeline/stories/` becomes `work/stories/` only when stories exist.
- `pipeline/roadmap.md` is not part of the minimal fresh install. Existing durable roadmap content should move into `knowledge/roadmap.md` or an ADR-backed planning record when it represents stable strategy.
- `pipeline/archive/` durable content moves to top-level `archive/`.

## Decision Records

Final architecture is preserved in ADRs, not in `project.md` and not in a hand-maintained `architecture.md` summary. The current `knowledge/decisions/architecture.md` file is a historical decision bundle during migration, not the canonical final architecture document.

- `project.md` stores stable project identity.
- `knowledge/decisions/index.md` is the architecture map.
- ADR files are the source of truth for accepted architecture.
- When architecture changes, create a new ADR and mark older ADRs as superseded in the index.
- Avoid temporary `decision-notes.md`; unsettled inputs belong in `work/current.md` as signals until accepted.

## Global Scope

Global scope exists for user-owned cross-project preferences, not for project memory and not as the canonical home for shipped product behavior.

Target global layout:

```text
~/.mindlayer/
└── preferences/
    ├── index.md
    └── playbook.md
```

Global scope should not contain canonical project templates, runtime markdown control planes, or duplicated product architecture. `boot.md`, `router.md`, and `memory-system/` were temporary compatibility output during migration; installs now prune them because the executable runtime and managed hooks are authoritative.

Reusable working rules such as Critical Architect Mode belong in `~/.mindlayer/preferences/playbook.md`. A tool-specific skill can adapt that rule for one agent, but the global preference remains the source of truth.

## Executable Runtime

Deterministic behavior belongs in code. The runtime owns:

- boot and load selection
- URI routing
- write safety and path traversal checks
- index validation
- adapter guard behavior
- markdown block updates
- session creation and retention
- archive and cleanup operations
- install, update, and migration
- MCP resource, prompt, and tool exposure

The one-command install experience remains valid, but `install.sh` is a bootstrapper. It should install or update the runtime and initialize project memory in one pass; it should not make runtime markdown the behavioral authority.

## Repository Layout

Use this repository organization:

```text
src/
  mindlayer runtime code

verify/
  proof scripts, test cases, fixtures, and release checks

seed/
  project/
    starter .mindlayer/ files
  adapters/
    thin adapter templates
```

`src/` contains product behavior. `verify/` contains proof. `seed/` contains installable starting content. This replaces the old conceptual split between `tests/` and `tools/` where both were mostly verifiers, and replaces `global-template/` and `project-template/` naming with clearer install seeds.

## Adapters

Adapters are bootstrap pointers only. They must not contain project facts, architecture decisions, progress, backlog, preferences, or scratch notes.

Adapter responsibilities:

- tell the agent to run or honor MindLayer boot
- point to MindLayer memory as the source of truth
- prevent adapter files from becoming memory
- stay small, frozen, and hash-guarded when installed

## MCP Mapping

MindLayer can expose project state through MCP without changing the core ownership model:

- MCP Resources: `.mindlayer/knowledge/**/*.md`, `.mindlayer/work/**/*.md`, `.mindlayer/archive/**/*.md`, and selected global preferences.
- MCP Prompts: `.mindlayer/prompts.md` or `.mindlayer/prompts/**/*.md` when present.
- MCP Tools: installed MindLayer commands and explicitly approved project tools only.

Never auto-expose arbitrary project `.py` or `.sh` files as MCP tools. Tools require an explicit contract, argument schema, path safety, approval policy, and verification. If project tools are exposed later, use an allowlist manifest rather than scanning executable files.

This ADR accepts the target ownership model for MCP exposure. Shipping MCP still remains gated by `ml-20260627-002` until a later go/no-go decision approves runtime dependency, compatibility, and release impact.

## Consequences

Positive:

- Reduces drift by moving behavior out of markdown and into verified code.
- Keeps project memory git-trackable and inspectable.
- Keeps global scope user-owned instead of product-owned.
- Makes MCP exposure natural: resources are data, prompts are prompts, tools are explicit actions.
- Keeps fresh installs small and lets structure grow only when real content appears.

Tradeoffs:

- Migration is required from the current `pipeline/`, `global-template/`, `project-template/`, and global runtime markdown model.
- Existing agents still need thin adapters until MCP support is universal and reliable.
- Runtime code and verification must become stricter because markdown instructions will no longer carry behavioral ambiguity.

## Migration Notes

Do this as an explicit migration, not as a hidden file shuffle:

1. Add runtime support for the target layout while preserving compatibility with the current layout.
2. Add verification for fresh install, existing install migration, adapter guarding, path safety, and MCP exposure contracts.
3. Migrate and consolidate `pipeline/` into `work/` through a migration command.
4. Move durable archived content from current pipeline archive locations into top-level `.mindlayer/archive/`.
5. Move install seeds from `project-template/` and `global-template/` into `seed/project/` and `seed/adapters/`.
6. Remove global runtime markdown after adapters and runtime boot no longer depend on it; prune legacy `~/.mindlayer/boot.md`, `router.md`, and `memory-system/` during install while preserving `preferences/`.

## Supersedes

This ADR supersedes the target architecture implied by:

- `ml-20260512-001` as a target model for instruction-driven boot/per-turn behavior
- `ml-20260507-007` as a target model for global-template synchronization
- global runtime markdown as canonical behavior
- `global-template/` as the long-term distribution model
- instruction-only router files as the behavioral control plane
- hand-maintained final architecture summaries
- creating empty future-volume memory folders on fresh install

Historical decisions remain useful for context, but this ADR is the accepted target architecture.

## Related

- `ml-20260627-002`: MCP remains a non-shipping research spike until a later go/no-go decision.
- `ml-20260511-002`: adapter freezing remains valid, but template location and runtime ownership migrate under this ADR.
- `ml-20260513-001`: command output standard remains valid and should be implemented by executable runtime.
