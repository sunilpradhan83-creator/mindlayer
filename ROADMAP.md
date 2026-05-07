# MindLayer Roadmap

This document captures the product vision and planned evolution of MindLayer. Near-term tracked work lives in `.mindlayer/backlog.md`.

---

## V1 — Installer Seed (shipped)

A minimal, installable markdown-first memory system.

- Global (`~/.mindlayer/`) and project (`.mindlayer/`) memory layers
- Thin tool adapters: `AGENTS.md`, `CLAUDE.md`, Copilot instructions
- Prompt-driven commands: boot, `ml retrieve`, `ml save`, `ml status`
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

## V4 — IDE Extensions + Intelligence Layer

Bring MindLayer into the editor, ship SCRIPT as a user-facing feature, and make retrieval smarter.

- `/m-script` command — walks any user through S→C→R→I→P→T for their project; ships in global-template
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
