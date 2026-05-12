# MindLayer Roadmap

This document captures the product vision and planned evolution of MindLayer. Near-term tracked work lives in `.mindlayer/backlog.md`.

---

## V1 — Installer Seed (shipped)

A minimal, installable markdown-first memory system.

- Global (`~/.mindlayer/`) and project (`.mindlayer/`) memory layers
- Thin tool adapters: `AGENTS.md`, `CLAUDE.md`, Copilot instructions
- Prompt-driven commands: boot, `ml load`, `ml save`, `ml status`
- Safe installer: non-destructive, idempotent, marker-block updates
- Validated by install, boot, and session continuity contract tests

---

## V2 — AI-Driven Prompt Automation

Make MindLayer commands proactive and automatic without replacing the prompt-driven model. The AI becomes the driver — detecting, proposing, and executing commands at the right moments, not just when explicitly asked.

- `ml session` — new command: session context cost and new-session vs compact recommendation (shipped)
- End-of-turn detection — AI checks every turn for memory candidates and retrieval needs, surfaces proposals immediately
- Trigger phrases — natural language invocation of all commands without typing slash commands
- Proactive session warnings — AI surfaces compact warning when context is heavy or critical
- `ml clean` — archive and forget: archive old entries or remove stale memory (ml archive + ml forget)
- `.mindlayer/` subdirectories — `private/`, `sessions/`, `cache/`, `tmp/` with real V2 behavior behind each

---

## V3 — Memory Quality + Smarter Retrieval

Make stored memory more useful over time and easier to find.

- Memory health scoring: auto-warn when files are stale, oversized, or duplicated
- Memory diff: surface what changed since the last session
- Programmatic index-first retrieval beyond agent-prompted reads
- Auto-summarization suggestions when entries grow too large

---

## V4 — Harness-as-Runtime

**Thesis:** harness-as-instructions becomes harness-as-runtime. Mechanics move to scripts; judgment stays in instructions. Scripts trigger instruction modules. Conditional modules need machine-checkable triggers.

The instruction-only boot reads ~7,300 words (~9,500 tokens) every session — far above the ~1,200 token design target. V4 fixes this in two stages:

### V4 Phase 0 — Boot Weight Reduction (instruction compression, no runtime)

Compress the instruction-only system as far as possible before the runtime exists. Each step ships as a separate commit so it is independently reversible.

- **A1** — Split `per-turn.md`: always-loaded core (Token Burned format only, ~150 words) + conditional modules loaded on trigger (`load-announce`, `memory-candidate`, `retrieval`, `lateral-intent`, `session-warning`, `pre-push`, `post-write`).
- **A2** — Compress `index.md`: boot loads a summary-only index (title + one-line summary + file pointer). Full entry blocks load on `ml load` only.
- **A3** — Compress `progress.md`: keep current phase only; archive completed phase history.
- **A4** — Compress `backlog.md`: keep active/planned items only; archive completed V2/V3 items.
- Build `test-boot-receipt.sh` and ~10 boot fixture sessions before the refactor begins — establishes a receipt-diff harness so regressions are caught per step.

Target: ~3,000 words (~3,900 tokens) at L0 boot. Track A alone cannot reach the original ~1,200 token goal — Track B is required for that.

### V4 Phase 1 — `ml` Command Runner Foundation (read-only)

A local Python script (`~/.mindlayer/ml`). Stdlib-first, tiny, lazy-loaded. Python unless `ml load` latency becomes a measured problem.

Agent interaction changes: instead of reading 7,300 words of instructions, the agent runs `ml boot` and reads ~400 words of output. Instructions become executable, not readable.

Read-only commands first (no agent trust required):

| Command | Behaviour |
|---|---|
| `ml boot` | Reads boot files, prints boot receipt to stdout |
| `ml status` | Scores memory health, prints report |
| `ml diff` | Computes memory changes since last session |
| `ml load <query>` | Scores index, returns ranked matches |
| `ml session` | Reports context cost and recommendation |

### V4 Phase 2 — Guarded Write Commands

| Command | Behaviour |
|---|---|
| `ml save` | Proposes candidate → writes on approval |
| `ml archive` | Proposes stale entries → archives on approval |
| `ml session write` | Writes session file on approval |

### V4 Phase 3 — SCRIPT Lifecycle Commands

| Command | Behaviour |
|---|---|
| `ml script` | Walks user through S→C→R→I→P→T interactively |
| `ml signal` | Captures a raw signal, routes to roadmap/backlog/discard |
| `ml story` | Refines a backlog item into an Agent Story |

### V4 Phase 4 — Cross-Agent Boot Parity Testing

`test-boot-receipt.sh` — runs `ml boot` and parses the receipt against structural assertions. Run via `tools/dogfood-boot.sh` against each agent runner (Claude, Codex). Output diffs surfaced as failures. Closes the Codex-vs-Claude compliance gap observed in V3.

### V4 Phase 5 — IDE Extensions

- VS Code extension: memory sidebar, quick-save from selection
- JetBrains and Cursor support
- `ml script` as first-class user feature in global-template

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

## Development Philosophy — SCRIPT

How MindLayer is built, and how every user should build with an AI companion.

SCRIPT is a six-step development cycle for human + AI pairs working on any kind of project. It wraps Agile — backlog grooming and sprint planning live in Cut and Refine, execution in Implement, QA and review in Prove, retrospective in Transfer — while adding the two steps Agile never had: **Signal** (validate the real problem before it enters the backlog) and **Transfer** (save lessons to persistent memory so every cycle is smarter than the last).

**S — Signal**
Surface the real problem. Raw input: user complaint, metric drop, founder instinct, market gap. This is pre-backlog — no filtering yet, just honest capture.

**C — Cut**
Decide what is worth doing now. Two gates in sequence:
- Roadmap gate: does this advance the current version goal? If not, defer to a future version or drop.
- Backlog gate: is this the right moment to execute? If not, park and revisit next cycle.
Most signals die here. That is correct.

**R — Refine**
Shape the smallest version that answers the key question. Write 2–3 acceptance criteria before any build starts. This is where user stories live. "Smallest" means smallest enough to learn from fast — not smallest imaginable.

**I — Implement**
Build it. Unit tests are part of Implement, not after it. AI companion leads execution; human steers direction and scope.

**P — Prove**
Broader tests, real scenario validation, dogfooding. Run it against your own workflow before calling it done. Guard rails: does it break anything upstream? AI companion can run regression checks automatically.

**T — Transfer**
Save what changed your understanding to persistent memory. Not what you built — what you learned. This feeds the next Signal and makes every cycle smarter than the last.

```
S → C → R → I → P → T → (back to S)
```

### SCRIPT and Agile

| Agile concept | SCRIPT step |
|---|---|
| Backlog grooming | Cut |
| Sprint planning | Cut + Refine |
| User stories + acceptance criteria | Refine |
| Sprint execution | Implement |
| QA / sprint review | Prove |
| Retrospective | Transfer |
| Continuous delivery | Prove → Signal loop |

SCRIPT does not replace Agile. Agile fits inside it. Signal and Transfer are the extensions Agile never had because it was designed before AI companions existed.

### SCRIPT across MindLayer versions

- **Now (V3):** Philosophy documented. Lateral intent routing handles Signal. `ml save` handles Transfer.
- **V4:** `ml script` command — walks any user through S→C→R→I→P→T for their project. Ships in global-template as a first-class user feature.
- **V5:** SCRIPT as shared team language. Retros feed Transfer across team members. Signal becomes crowd-sourced across the team.

---

## Principles that should survive every version

- Token efficiency first: load only what is needed, when it is needed.
- Memory is curation, not a chat dump.
- Never overwrite user-owned content without explicit approval.
- Keep adapters thin; durable memory lives in `.mindlayer/` files.
- Indexes before full files, always.
