# Architecture Decisions

Historical decision bundle. The accepted target architecture is `knowledge/decisions/adr-0001-mindlayer-architecture.md`; this file is retained for context and for still-valid local decisions, not as a final architecture summary.

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
MindLayer dogfood testing uses `verify/dogfood.sh` with pluggable agent runners. Isolated runs are product gates; live real-HOME checks are personal health checks.

### Details
- `verify/dogfood.sh` with an isolated runner — full HOME isolation + agent credentials. Tests exactly what `install.sh` ships. Reproducible on any machine. CI-safe. Required before releases and on PRs touching `seed/adapters/` or install behavior.
- Live real-HOME dogfood checks test the contributor's actual `~/.mindlayer/` config. Zero setup. Personal sanity check, not a product gate.
- Separation is correct because: (a) the product gate must test what ships, not personal config, (b) the live check needs zero friction for daily use.
- Docker was evaluated and rejected — security investment belongs at distribution layer (CODEOWNERS, signed releases), not dogfood layer. Docker would be security theater here.
- Runners live in `verify/dogfood-runners/`: `claude.sh` and `codex.sh`.

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
- Test fixtures in `verify/dogfood-fixtures/` give the sandbox project real identity (non-scaffold `project.md`, `index.md` with `ml-onboard-complete`) so the agent boots confidently without triggering the onboard flow.

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

## MCP Resource Plane Research Spike

id: ml-20260627-002
created: 2026-06-27
updated: 2026-06-27
scope: project
type: decision
tags: [architecture, mcp, fastmcp, research-spike, dependencies, agent-agnostic]
confidence: medium
status: active
source: conversation

### Summary
MindLayer may explore MCP as a future micro-kernel runtime, but the approved near-term work is a non-shipping Resource Plane research spike. FastMCP is accepted for evaluation only and must not become a 0.1 runtime dependency without a later go/no-go decision.

### Details
- The 0.1 Developer Preview remains focused on rename, release-candidate soak, and public launch hygiene.
- The spike may prototype read-only MCP resources over existing markdown memory and index-first retrieval.
- The spike must not alter install behavior, boot behavior, public docs, or the shipping `ml` command path.
- FastMCP introduces the project's first runtime dependency, so adoption requires an explicit follow-up decision covering version pinning, install impact, offline/corporate environments, and fallback if the dependency churns.
- Docker remains deferred for MCP Tool Plane work. The prior Docker rejection was dogfood-specific, so future tool execution needs its own threat model before choosing an isolation backend.
- Prompt Plane cutover requires proof that supported agent clients can carry the contract; no existing hook should be deprecated on a single-client assumption.

### When to use
Use when planning MCP work, evaluating FastMCP, changing runtime dependencies, or deciding whether MCP work is allowed before 1.1.

### Related
ml-20260627-001
ml-20260517-002
ml-20260507-004
ml-20260510-002
ml-20260510-004

## Size-Aware Consolidation Mapping (ADR-0001 Refinement)

id: ml-20260701-002
created: 2026-07-01
updated: 2026-07-01
scope: project
type: decision
tags: [adr, migration, layout, work, consolidation]
confidence: high
status: active
source: conversation

### Summary
Refines ADR-0001's pipeline/ -> work/ mapping: consolidate progress+backlog into a
single work/current.md only while it stays under the memory line budget; otherwise
keep backlog as a sibling work/backlog.md.

### Details
- ADR-0001's consolidation intent is "keep fresh installs small," not "force a mature
  project's now+later state into one file."
- ml migrate collapses to one current.md when the projected file stays under the
  240-line warn threshold; past it, backlog splits to work/backlog.md. Deterministic,
  avoids re-split churn for growing memory such as MindLayer's own dogfood repo.
- roadmap always moves to knowledge/roadmap.md; sessions to work/sessions/; archive to
  top-level archive/. Root index stays pointer-only; router/roadmap rows relocate to
  knowledge/index.md.

### When to use
Use when changing ml migrate, the work/ layout, or the memory size budget.

### Related
ml-adr-0001
