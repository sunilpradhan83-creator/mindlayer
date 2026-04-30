# Concepts

MindLayer treats memory as intelligence, not storage.

An AI coding agent needs more than facts. It needs to know what matters, where it belongs, how to retrieve it, and when old information should stop influencing decisions.

## Memory as Intelligence

Useful memory has four jobs:

- curation: keep durable knowledge, not raw chat
- routing: put each memory in the right file
- retrieval: start from compact indexes
- lifecycle: mark memory as active, experimental, deprecated, or archived

## Layers

Global user memory lives in `~/.mindlayer/` and follows the developer across projects.

Project memory lives in `project/.mindlayer/` and captures project-specific identity, progress, decisions, context, backlog, and risks.

Tool adapters such as `AGENTS.md`, `CLAUDE.md`, and Copilot instructions are thin instructions. They are not memory stores.

