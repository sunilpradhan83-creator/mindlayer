# Decisions

## Adapter Freeze + Auto-Detection Architecture

id: ml-20260511-002
created: 2026-05-11
updated: 2026-05-11
scope: project
type: decision
tags: [adapters, freeze, auto-detection, install, canonical]
confidence: high
status: active
source: conversation

### Summary
All adapter files are frozen whole-file canonical templates. Install auto-detects tools via system signals and existing project files. User content is never lost — routed via `ml save` before restore.

### Details
- No delimiters (`<!-- mindlayer:start/end -->`) in any adapter — whole file is the contract.
- Canonical templates live in `global-template/memory-system/templates/` (repo) and `~/.mindlayer/memory-system/templates/` (installed). Never manually edited.
- `adapters.lock` in project `.mindlayer/` stores SHA-256 hash of each installed adapter. Authority on what MindLayer last wrote.
- Install detects tools via `which <tool>` and `~/.tool/` directory signals plus existing project adapter files.
- Existing project files with user content are never overwritten silently — diffed against canonical, extra content routed via `ml save` flow, then restored.
- `update_marked_block` removed entirely. All adapters use `install_canonical_adapter`.

### When to use
Use when adding a new tool adapter, debugging install behavior, or understanding why an adapter was or was not written.

### Related
ml-20260511-001
ml-20260510-002

## Dogfood Two-Script Architecture

id: ml-20260510-002
created: 2026-05-10
updated: 2026-05-10
scope: project
type: decision
tags: [dogfood, testing, ci, open-source, security, architecture]
confidence: high
status: active
source: manual

### Summary
MindLayer dogfood testing uses two separate scripts with distinct purposes: `dogfood-boot.sh` (product gate, full isolation, API key) and `dogfood-live.sh` (personal health check, real HOME, OAuth).

### Details
- `tools/dogfood-boot.sh` — full HOME isolation + `ANTHROPIC_API_KEY`. Tests exactly what `install.sh` ships. Reproducible on any machine. CI-safe. Required before releases and on PRs touching `global-template/`.
- `tools/dogfood-live.sh` — real HOME + OAuth. Tests the contributor's actual live `~/.mindlayer/` config. Zero setup. Personal sanity check, not a product gate.
- Separation is correct because: (a) the product gate must test what ships, not personal config, (b) the live check needs zero friction for daily use.
- Docker was evaluated and rejected — security investment belongs at distribution layer (CODEOWNERS, signed releases), not dogfood layer. Docker would be security theater here.
- Runners live in `tools/dogfood-runners/`: `claude.sh` (isolated), `claude-live.sh` (live), `codex.sh` (Codex, single-turn only).

### When to use
Load when planning dogfood strategy, adding new agent runners, or evaluating CI integration.

---

## AGENTS.md Boot Trigger Root Cause

id: ml-20260510-003
created: 2026-05-10
updated: 2026-05-10
scope: project
type: decision
tags: [agents-md, boot, non-interactive, adapter, install]
confidence: high
status: active
source: manual

### Summary
In non-interactive (`-p`) mode, agents skip tool calls needed for boot unless `AGENTS.md` explicitly says to boot BEFORE answering. Ambiguous wording causes agents to answer directly from adapter files without running the boot sequence.

### Details
- Root cause: `AGENTS.md` said "run boot before answering the first project-relevant request" — agents interpreted this as optional or deferrable, and answered from `CLAUDE.md`/`AGENTS.md` context directly.
- Fix: added "Never answer a project question without booting first. Never ask the user if they want you to boot — just boot." to both `install.sh` (AGENTS.md template) and `global-template/boot.md`.
- Key insight: "boot before answering" is ambiguous. "boot BEFORE, then answer, never ask permission" is not.
- Applies to all agents in non-interactive/headless mode — not Claude-specific.
- Test fixtures in `tools/dogfood-fixtures/` give the sandbox project real identity (non-scaffold `project.md`, `index.md` with `ml-onboard-complete`) so the agent boots confidently without triggering the onboard flow.

### When to use
Load when modifying AGENTS.md boot instructions, debugging boot receipt failures, or adding new agent runners.

---

## Open Source Security Hardening Decision

id: ml-20260510-004
created: 2026-05-10
updated: 2026-05-10
scope: project
type: decision
tags: [security, open-source, governance, supply-chain]
confidence: high
status: active
source: manual

### Summary
Security investment for open source MindLayer belongs at the distribution and governance layer, not the dogfood test layer. Three distinct threat vectors, each with its own mitigation.

### Details
- Threat 1 (malicious contributor): CODEOWNERS on `global-template/` + branch protection. Code review is the control — markdown is human-readable, malicious instructions are visible in PR diffs.
- Threat 2 (supply chain): signed releases + published checksums for `install.sh`.
- Threat 3 (developer running unreviewed local changes): document in CONTRIBUTING.md. Self-inflicted risk, not a tooling problem.
- Docker in dogfood was explicitly rejected — it protects the wrong layer and adds contributor friction without meaningful security benefit.
- Full details in `roadmap.md` entry `ml-20260510-001`.

### When to use
Load when planning the open source release, evaluating security PRs, or onboarding security contributors.

---

## Global-Template Sync Rule
id: ml-20260507-007
created: 2026-05-07
updated: 2026-05-07
scope: project
type: decision
tags: [global-template, sync, installer, per-turn, memory-system]
confidence: high
status: active
source: manual
### Summary
When any file in `~/.mindlayer/memory-system/` is updated, `global-template/memory-system/` must be synced in the same session. New users only receive what ships in global-template.
### Details
- Live `~/.mindlayer/memory-system/` is runtime output; `global-template/memory-system/` is what new users install.
- Divergence creates silent regressions for new installs.
- Any memory-system change must update live + global-template, run `tools/test.sh`, and commit both together.


## Agent-Agnostic Design Principle
id: ml-20260507-004
created: 2026-05-07
updated: 2026-05-07
scope: project
type: decision
tags: [architecture, agent-agnostic, adapters, design]
confidence: high
status: active
source: manual
### Summary
MindLayer is designed to work across any LLM tool — Claude, Codex, Cursor, Copilot, and any future agent. No feature, rule, or mitigation should be written as tool-specific unless it is explicitly a thin adapter for that tool.
### Details
- MindLayer is a control plane over agents, not a feature of one tool.
- Product rules, mitigations, and roadmap items must be agent-agnostic; tool-specific content belongs only in thin adapters.
- Correct accidental tool lock-in in memory, decisions, risks, or roadmap immediately.


## ML-999 Backlog Evaluation Decisions
id: ml-20260507-005
created: 2026-05-07
updated: 2026-05-07
scope: project
type: decision
tags: [backlog, roadmap, ml-999, prioritization, v3, v4]
confidence: high
status: active
source: manual
### Summary
Backlog evaluation (ML-999, 2026-05-07) produced activation, defer, and reject decisions for ML-101 through ML-110. These decisions should not be re-litigated without new evidence.
### Details
- Rejected: ML-104, ML-105, ML-106, ML-107, ML-109, ML-110 due to overlap, premature scope, or violating MindLayer's deterministic/agent-agnostic boundaries.
- Deferred: ML-103 and ML-108 until evidence shows adapter gaps or `Related:` fields are insufficient.
- Activated partial ML-101 as ranked retrieval/loading on top of the existing index; no ML or new storage.
- Pulled `ml onboard` into V3 because onboarding mature projects was the biggest adoption barrier.


## MindLayer Source-of-Truth Boundaries
id: ml-20260503-001
created: 2026-05-03
updated: 2026-05-03
scope: project
type: decision
tags: [source-of-truth, templates, memory-routing]
confidence: high
status: active
source: manual
### Summary
While working inside the MindLayer repo, product memory should be saved to project `.mindlayer/`, shipped global behavior should be implemented through `global-template`, and live `~/.mindlayer/` should not be manually edited.
### Details
- Repo `.mindlayer/` is product memory for MindLayer itself.
- Live `~/.mindlayer/` is runtime/install/test output, not product-memory source of truth.
- `project-template` is starter memory for future users; `global-template` ships default global behavior.
- Operational behavior changes must be reflected in templates/adapters/specs, not only saved as memory.


## Literal Approval for Memory Writes
id: ml-20260503-002
created: 2026-05-03
updated: 2026-05-03
scope: project
type: decision
tags: [approval, memory-safety, commands]
confidence: high
status: active
source: manual
### Summary
Memory writes require literal explicit approval before editing durable memory.
### Details
Acknowledgments like `ok`, `got it`, or `we need to save this` are not approval. The agent must propose exact destination/content and wait for clear approval (`approve`, `go ahead`, etc.) before editing durable memory or behavior templates.


## Skill Approval Gate
id: ml-20260507-002
created: 2026-05-07
updated: 2026-05-07
scope: project
type: decision
tags: [approval, skills, ml-init, adapter-safety, memory-safety]
confidence: high
status: active
source: manual
### Summary
Skills that write files (such as the `init` skill triggered by `ml init`) must not execute autonomously in the MindLayer repo. The agent must read the target file, explain what the skill would do, and wait for explicit approval before any write.
### Details
- Skills/slash commands that write files, including `ml init`-triggered adapter rewrites, require the same literal approval as memory writes.
- If a skill writes without approval, revert and explain. MindLayer product learnings belong in MindLayer memory, not tool-native memory.


## Pre-Push Gate
id: ml-20260505-008
created: 2026-05-05
updated: 2026-05-05
scope: project
type: decision
tags: [pre-push, testing, quality-gate, proactive]
confidence: high
status: active
source: manual
### Summary
Before every push, the agent appends a one-line test confirmation. `yes` or `skip` both proceed immediately.
### Details
- Fires once per push action with: `Pre-push: tests added and run for this change? Say 'yes' to push or 'skip' to push without testing.`
- `yes` and `skip` both proceed immediately. Does not fire during boot, status checks, or non-push turns.


## Lateral Intent Routing
id: ml-20260505-007
created: 2026-05-05
updated: 2026-05-05
scope: project
type: decision
tags: [lateral-intent, routing, backlog, roadmap, proactive]
confidence: high
status: active
source: manual
### Summary
When a user introduces work outside the current Next Step or backlog, the agent classifies it silently and appends a one-line non-blocking nudge before proceeding.
### Details
- Classify out-of-plan work as backlog candidate, roadmap amendment, or ad-hoc.
- Append at most one non-blocking nudge before Token Burned; do not fire during boot/status or direct Next Step/backlog-pull responses.
- Capture only on explicit user response; approval rules still apply.


## Token Burned Per-Turn Status Block
id: ml-20260505-005
created: 2026-05-05
updated: 2026-05-06
scope: project
type: decision
tags: [session-continuity, per-turn, next-step, token-tracking, handoff, goal-hierarchy, coming-up, priority]
confidence: high
status: active
source: manual
### Summary
Handoff is deprecated. Every agent turn ends with a Token Burned block. Next Step is always a single plain-text action. Optional Coming Up: surfaces for ambiguity or long queues. Priority hierarchy is strictly enforced.
### Details
- Every turn ends with Token Burned, Session estimate, and nonblank `Next Step`; optional `Coming Up` appears only for ambiguity or long queues.
- Next Step hierarchy: active task → commit uncommitted changes → next backlog item → next roadmap phase → brainstorm next major version.
- `Coming Up` lists only lower-priority follow-ups; uncommitted changes always outrank new backlog work.


## SCRIPT Product Engine Architecture
id: ml-20260508-002
created: 2026-05-08
updated: 2026-05-08
scope: project
type: decision
tags: [script, v4, product-engine, lifecycle, roadmap, backlog, agent-stories, transfer]
confidence: high
status: active
source: conversation
### Summary
V4 reframes MindLayer as a SCRIPT-driven product development engine, not just a memory helper. Signal is the universal ingress point; Roadmap → Backlog → Agent Stories → Progress is the artifact queue; Transfer splits into Learning Path and History Path.
### Details
- SCRIPT remains the process flow: Signal → Cut → Refine → Implement → Prove → Transfer.
- Signal is detected by the agent but remains pending until human-approved routing; no `signals.md` durable queue is planned for V4.
- Approved Signals route to roadmap for product/version direction, backlog for near-term work, Agent Stories when already refined, progress for active execution state, or learning memory when the content is durable knowledge only.
- Roadmap, backlog, Agent Stories, and progress are artifact buckets in a queue. Ideas should be promoted through the queue rather than duplicated across files.
- Refine produces one or more Agent Stories with human in the loop; Agent Stories replace durable user stories/tasks/actions as the post-planning work unit an agent can execute.
- Transfer has two paths: Learning Path (`.mindlayer/learnings/` typed files for project, decisions, context, risks) and History Path (`.mindlayer/history/` version archives plus archive index for completed or inactive flow artifacts).
- V4 should be spec-first, then implemented by a local Python `ml` runtime. IDE integrations come after the lifecycle runtime is stable.
