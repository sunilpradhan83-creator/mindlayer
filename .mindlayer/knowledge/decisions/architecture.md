# Architecture Decisions

## V4 Phase 0 Boot Compression Architecture

id: ml-20260512-001
created: 2026-05-12
updated: 2026-05-12
scope: project
type: decision
tags: [v4, boot, compression, per-turn, index, progress, backlog]
confidence: high
status: active
source: implementation

### Summary
V4 Phase 0 compresses instruction-only boot weight by splitting per-turn behavior into lazy modules, loading a summary-only project index at boot, and archiving completed progress/backlog history.

### Details
- `memory-system/per-turn.md` is now the always-loaded core: Token Burned format and Next Step hierarchy only.
- Conditional per-turn contracts moved to `memory-system/per-turn/`: load announcements, memory candidates, retrieval suggestions, lateral intent, session warnings, and post-write size checks.
- Boot reads `.mindlayer/index.md` as a summary-only catalog; full metadata lives in `.mindlayer/index-full.md` and loads via `ml load`.
- `progress.md` keeps only current phase state; completed V1/V2/V3 progress history is archived as `ml-progress-archive-v1v2v3`.
- `backlog.md` keeps active/planned V4 and deferred work; completed V2/V3 backlog history is archived as `ml-backlog-archive-v2v3`.
- Track A targets roughly 3,900 boot tokens. Track B, the V4 command runner, is still required for the original roughly 1,200-token goal.

### When to use
Use when changing boot sequence, per-turn modules, index loading, progress/backlog compression, or planning V4 command-runner work.

### Related
ml-20260508-001
ml-20260508-002
ml-20260507-007

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

## Agent-Agnostic Command Output Standard
id: ml-20260513-001
created: 2026-05-13
updated: 2026-05-13
scope: project
type: decision
tags: [agent-agnostic, commands, boot, output, runtime]
confidence: high
status: active
source: dogfood
### Summary
MindLayer command outputs, especially `ml boot`, must be standardized across Claude, Codex, Cursor, Copilot, and future agents.
### Details
- The local `ml` runtime is the authoritative output surface for command receipts and schemas.
- Agents should relay or execute runtime output without transforming it into tool-specific narration, repo analysis, skill initialization, or adapter rewrites.
- `ml boot` must emit the same receipt schema everywhere and must not trigger `init` skills or writes to tool adapters.
- Tool-specific adapters remain bootstraps only; product facts and command behavior belong in `.mindlayer/`, shipped templates, command specs, or runtime code.
### When to use
Use when changing command output schemas, boot behavior, dogfood runners, adapter behavior, or cross-agent UX.
### Related
ml-20260507-004
ml-20260511-002
ml-20260507-002
ml-20260508-001
