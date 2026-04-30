# Tool Adapters

Tool adapters tell AI coding tools how to use MindLayer. They are not memory stores.

## AGENTS.md

`AGENTS.md` is the universal adapter for agentic coding tools. It explains the memory layers, commands, and rules.

## CLAUDE.md

`CLAUDE.md` is intentionally thin. It tells Claude Code to follow `AGENTS.md` and use MindLayer memory files as the source of truth.

## GitHub Copilot

`.github/copilot-instructions.md` is also thin. It tells Copilot to follow `AGENTS.md`, use `.mindlayer/` for project context when available, and avoid modifying memory files unless explicitly requested.

## Drift Prevention

Do not duplicate durable memory into adapters. If an adapter and memory file disagree, update the memory file after approval and keep the adapter generic.

