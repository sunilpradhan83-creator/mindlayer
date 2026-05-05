# Context

Project-specific background, design philosophy, and non-obvious constraints.

## Product Design Philosophy

id: ml-20260430-004
created: 2026-04-30
updated: 2026-05-05
scope: project
type: context
tags: [design, tokens, memory-quality, writing]
confidence: high
status: active
source: manual

### Summary
Memory is curation, routing, retrieval, and lifecycle — not a chat dump. Token efficiency is the primary design constraint.

### Details
- MindLayer is prompt-first in V1. The installer makes the system one-pass usable by creating predictable files, adapters, indexes, and ignored local directories.
- Initialization must distinguish structural presence from semantic value. Scaffold files with no real content must not be loaded as useful context.
- Token efficiency is the primary design constraint. Everything an agent needs for durable context lives in MindLayer markdowns.
- Memory entries should be short, explicit, and written for AI retrieval with minimal ambiguity and token waste. Clarity wins over jargon.
- Do not duplicate memory across tool-specific adapter files; they drift.
- A memory file that exists but is not indexed is effectively unavailable. Index entries are the discoverability contract.
- Installer changes require sandbox test coverage: fresh install, idempotent rerun, file preservation, and adapter block integrity.

### When to use
Use when deciding whether an implementation detail improves memory quality or merely adds machinery. Use when writing or editing memory entries, templates, prompts, and command instructions.

### Related
ml-20260430-003
