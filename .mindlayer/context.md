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

## Goal Hierarchy and Flow

id: ml-20260505-004
created: 2026-05-05
updated: 2026-05-05
scope: project
type: context
tags: [goal-hierarchy, roadmap, backlog, next-step, flow, token-burned]
confidence: high
status: active
source: manual

### Summary
MindLayer uses a product goal flow: project identity (north star) → roadmap (versioned vision) → backlog (near-term tasks) → progress (current execution state) → sessions (daily work) → per-turn Next Step. The per-turn Token Burned block surfaces Next Step by walking this hierarchy bottom-up.

### Product Goal Flow

```text
project.md -> roadmap.md -> backlog.md -> progress.md -> sessions/YYYY-MM-DD.md -> Token Burned / Next Step
```

- `project.md`: stable product identity and north star.
- `roadmap.md`: long-term versioned product direction.
- `backlog.md`: near-term work pulled from the active roadmap phase.
- `progress.md`: current shipped state, active phase, and immediate execution target.
- `sessions/YYYY-MM-DD.md`: daily continuity and handoff notes.
- Token Burned / Next Step: smallest useful next action surfaced every turn.

### Flow Diagram

```mermaid
flowchart TD
    P["project.md\nProduct identity / north star"]
    R["ROADMAP.md\nVersioned vision (V1 → V5+)"]
    B["backlog.md\nNear-term phase items"]
    P2["progress.md\nCurrent execution state"]
    S["sessions/YYYY-MM-DD.md\nDaily work log"]
    T["Per-turn Token Burned block\nNext Step prediction"]

    P -->|"Shapes versioned direction"| R
    R -->|"Phase kickoff\n(human approves)"| B
    B -->|"Task execution"| P2
    P2 -->|"Session continuity"| S
    S -->|"Every agent turn"| T

    B -->|"Backlog empty →\nagent proposes next roadmap phase"| R
    R -->|"Roadmap complete →\nbrainstorm next version with user"| R
```

### Next Step Prediction Hierarchy

The agent always predicts the smallest useful next action by walking up:

1. **Active task** → next action within the current task
2. **Task complete** → next item in backlog
3. **Backlog empty** → surface next roadmap phase for human approval to pull
4. **Roadmap complete** → propose brainstorming next major version with the user

### Backlog Pull

When the agent surfaces a roadmap phase pull and the user says 'pull next phase', decompose the phase into discrete backlog items and propose each for approval before writing.

### When to use
Use when implementing or evaluating Next Step prediction, backlog pull behavior, roadmap-to-backlog decomposition, and per-turn Token Burned block logic.

### Related
ml-20260430-005
ml-20260505-003

## Memory System Self-Reference Problem

id: ml-20260506-001
created: 2026-05-06
scope: project
type: context
tags: [memory-system, token-efficiency, architecture, v3]
confidence: high
status: active
source: manual

### Summary
`memory-system.md` has a chicken-and-egg problem: the rules for what to load
and when are embedded inside the file that must be fully loaded first (~3,500
tokens) just to learn what not to load.

### Proposed Solution
Split into `memory-system/` folder with a lightweight index (~150 tokens)
that carries load triggers. Boot loads only `index.md` + `per-turn.md`.
Everything else is pulled conditionally within a turn.

### Savings Estimate
- Current boot cost: ~3,500 tokens
- Proposed typical session cost: ~1,200 tokens
- Worst case unchanged: ~3,500 tokens

### When to use
Use when evaluating V3 token-efficiency work or designing changes to how
`memory-system.md` is structured and loaded.

### Related
ml-20260505-006
