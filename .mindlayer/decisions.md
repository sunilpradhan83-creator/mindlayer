# Decisions

## V1 Memory Architecture Decisions

id: ml-20260430-003
created: 2026-04-30
updated: 2026-04-30
scope: project
type: decision
tags: [architecture, installer, adapters]
confidence: high
status: active
source: manual

### Summary
MindLayer V1 uses markdown files, global and project memory layers, thin tool adapters, and strict source boundaries.

### Details
- Use `~/.mindlayer/` for global memory.
- Use project `.mindlayer/` for project memory.
- Use `AGENTS.md` as the universal adapter.
- Use `CLAUDE.md` and Copilot instructions as thin adapters.
- Treat `README.md` as human-facing product documentation only, not AI memory input.
- Treat `docs/` as human-facing deep-dive documentation only, not default AI memory input.
- Treat tool adapters such as `AGENTS.md`, `CLAUDE.md`, and Copilot instructions as blocked memory stores: agents should not add durable memory there or use them as retrieval sources beyond the thin MindLayer instructions.
- AI agents should rely on global `~/.mindlayer/` and project `.mindlayer/` markdown files for initialization, on-demand retrieval, and memory writes.
- Agents may go outside MindLayer memory only when necessary for the task, and should remain cautious about token usage.
- Use a symlink to global memory when possible.
- Use a pointer fallback when symlink creation fails.
- Never overwrite existing user files.
- Fail fast on required installer write errors instead of printing success after partial failure.
- `/m-init` must skip scaffold-only files and `local.md` by default unless relevant or non-placeholder.
- Do not ignore the entire `.mindlayer` directory.
- Do not implement archive or cleanup in V1.

### When to use
Use when evaluating feature scope, installer behavior, documentation boundaries, adapter behavior, or AI memory retrieval rules.

### Related
ml-project-20260430-001
