# MindLayer Roadmap

This document captures the product vision and planned evolution of MindLayer. Near-term tracked work lives in `.mindlayer/backlog.md`.

---

## V1 — Installer Seed (shipped)

A minimal, installable markdown-first memory system.

- Global (`~/.mindlayer/`) and project (`.mindlayer/`) memory layers
- Thin tool adapters: `AGENTS.md`, `CLAUDE.md`, Copilot instructions
- Prompt-driven commands: boot, `/m-retrieve`, `/m-save`, `/m-status`
- Safe installer: non-destructive, idempotent, marker-block updates
- Validated by install, boot, and session continuity contract tests

---

## V2 — CLI + Core Commands

Replace prompt files with a real CLI so commands are reliable, scriptable, and host-agnostic.

- `m install` — install or update MindLayer in a project
- `m save` — propose and write durable memory with approval flow
- `m retrieve <query>` — index-first retrieval from the command line
- `m status` — memory health check with actionable output
- `m session` — show session context cost, recommend new session vs compact
- Archive mode — archive old memory entries without deleting them
- `.mindlayer/` subdirectories — `private/`, `sessions/`, `cache/`, `tmp/` with real V2 behavior behind each

---

## V3 — Memory Quality + Smarter Retrieval

Make stored memory more useful over time and easier to find.

- Memory health scoring: auto-warn when files are stale, oversized, or duplicated
- Memory diff: surface what changed since the last session
- Programmatic index-first retrieval beyond agent-prompted reads
- Auto-summarization suggestions when entries grow too large

---

## V4 — IDE Extensions + Intelligence Layer

Bring MindLayer into the editor and make retrieval smarter.

- VS Code extension: memory sidebar, quick-save from selection
- JetBrains and Cursor support
- Optional semantic search layer for large memory stores
- Auto-routing suggestions: agent recommends where to save based on content type

---

## V5 — Teams

Shared memory for collaborating developers on the same project.

- Shared project memory with per-person private layer
- Memory proposal and review workflow: propose → review → merge
- Access controls: what's shared vs personal

---

## V5+ — Hosted / SaaS

A fundamentally different deployment model. Cross-device sync, web dashboard, team collaboration with a backend. This is a separate product decision, not just a feature addition.

---

## Principles that should survive every version

- Token efficiency first: load only what is needed, when it is needed.
- Memory is curation, not a chat dump.
- Never overwrite user-owned content without explicit approval.
- Keep adapters thin; durable memory lives in `.mindlayer/` files.
- Indexes before full files, always.
