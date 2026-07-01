# Roadmap

Canonical project roadmap for MindLayer. Public `ROADMAP.md` mirrors this file for human readers; `.mindlayer/` remains the source of truth.

## ADR-0001 Migration Execution Plan

id: ml-20260701-001
created: 2026-07-01
updated: 2026-07-01
scope: project
type: roadmap
tags: [adr, migration, execution-plan, mcp, sequencing]
confidence: high
status: active
source: conversation

### Summary
Ordered execution plan for adopting the ADR-0001 target architecture. Combined but
strictly ordered: freeze the target, make the current control plane consistent, migrate
in slices, then expose via MCP. Governing principle: MCP is an exposure layer, not a fix
for unclear architecture — make the architecture deterministic first, then expose it.

### Steps
- Step 0 (done): commit ADR-0001 + typed-status schema. Freeze the target. Branch
  `adr-0001-architecture`, commit `c669261`.
- Step 1 (done): fix the 13 spec-layout failures. Symptom fix for control-plane drift.
- Step 2 (next): ADR migration foundation, back-compat first per ADR Migration Notes:
  - 2a: runtime + verification scaffold reading both old and new layouts; no file moves.
  - 2b: consolidate `pipeline/` -> `work/current.md` (mapping defined in ADR-0001).
  - 2c: move `project-template/` + `global-template/` -> `seed/project/` + `seed/adapters/`.
  - 2d: move router behavior from markdown to executable runtime (the drift cure; last).
- Step 3: read-only, isolated MCP resource spike. Only after runtime boundaries exist.
- Step 4: MCP tools, only after executable runtime boundaries exist.

### When to use
Use when sequencing ADR-0001 migration work or deciding whether MCP work may start.
See `knowledge/decisions/adr-0001-mindlayer-architecture.md` for the target architecture.

### Related
ml-adr-0001
ml-20260517-002

## MindLayer 0.1 Developer Preview Roadmap

id: ml-20260517-002
created: 2026-05-17
updated: 2026-05-17
scope: project
type: roadmap
tags: [roadmap, open-source, developer-preview, script, correctness]
confidence: high
status: active
source: conversation

### Summary
MindLayer will ship a 0.1 Developer Preview before any 1.0 announcement. The first public version is correctness-first: fix verified boot/load/status/save/clean/diff problems, align docs with the real CLI architecture, add open-source hygiene, and rename before public launch.

### Product Direction
Audience: solo AI-native developers using Codex, Claude Code, Cursor, or similar coding agents.

Positioning: human-approved, git-trackable memory for AI coding agents. SCRIPT is the workflow inside the product, not the top-level marketing claim.

Architecture: keep the two-layer markdown memory model, thin adapters, adapter/CLI-first runtime, explicit approval before writes, and SCRIPT lifecycle. No shipping MCP server in 0.1; a non-shipping Resource Plane research spike is sanctioned under the MCP Micro-Kernel Track.

Methodology in force: `knowledge/decisions/script-v0.1.md`.

### Stage 0.1 - Developer Preview
Goal: correctness, positioning, and open-source basics with honest preview framing.

Scope:
- Fix 11 verified correctness findings: starter boot truth, personal preference starter detection, missing project router, `ml load` section resolution, ranking without query hits, false duplicate headings, hierarchical `ml clean`, nearest-index `ml save`, README CLI drift, adapter-doc drift, and archived items appearing as new in `ml diff`.
- Rewrite README around "human-approved, git-trackable memory for AI coding agents."
- Add `comparison.md`, CONTRIBUTING, SECURITY, Code of Conduct, issue/PR templates, CODEOWNERS, one quickstart example, minimal CI, CHANGELOG, release notes, and clean test/lint output.

Exit criteria:
- Full install -> boot -> load -> save -> status -> `ml script status` path works from public docs without maintainer help.
- `verify/test.sh` passes and strict lint is clean.
- Fresh boot does not leak starter content and reports no missing project router.
- README, ROADMAP, `.mindlayer/knowledge/project.md`, and this roadmap tell the same story.
- Public launch waits for rc soak: 48-72 hours and at least 3 independent fresh installs.

### Stage 0.2 - Reliability
Goal: make the preview dependable enough for repeat daily use.

Scope:
- Boot bloat reduction toward roughly 3,500 L0 tokens.
- Python CI matrix on Ubuntu 3.9-3.12, and macOS only after bash 3.2 compatibility is verified.
- Boot-weight regression guard.
- `ml status --lifecycle` and SCRIPT runtime enforcement where dogfood shows decay.
- Read-only docs drift checker that proposes sync; no silent README/ROADMAP generation.

### Stage 0.3 - Cross-Agent Proof
Goal: prove MindLayer works across the AI-native developer tools it claims to support.

Scope:
- Public dogfood transcripts for Codex, Claude Code, and Cursor.
- At least 3 worked examples in the repo.
- Migration notes from adjacent tools when real migration data exists.
- Fewer "what just happened?" moments in fresh-user runs.

### Stage 1.0 - Public Stable
Goal: earned stability, not a calendar milestone.

Ship only when all hold:
- At least 5 external users run MindLayer for at least 4 weeks.
- Zero open critical bugs.
- At least one unsolicited third-party blog post or public repo uses MindLayer.
- Install -> boot -> load -> save -> status -> SCRIPT flow works from docs alone.
- Correctness invariants from 0.1 still hold.
- CHANGELOG covers every change since 0.1.
- Adapter/CLI behavior is stable across at least 2 of Codex, Claude Code, and Cursor.
- VS Code extension available so VS Code users can install without touching a terminal.

### Stage 2.0 - Ecosystem Reach
Goal: reach users in environments where curl | bash is blocked or insufficient.

Scope:
- Rename package if `mindlayer` is taken on PyPI at the time of 2.0.
- PyPI package (`pip install mindlayer`) for corporate environments using internal registries.
- `ml install` Python command that replaces install.sh logic, so pip install is a complete setup path.

### MCP Micro-Kernel Track

id: ml-20260627-001
created: 2026-06-27
updated: 2026-06-27
scope: project
type: roadmap
tags: [roadmap, mcp, fastmcp, micro-kernel, disposable-scaffolding, hope]
confidence: medium
status: active
source: conversation

#### Summary
Explore a future MindLayer runtime built as a single MCP server with three planes: Resource for read-only context access, Tool for guarded execution boundaries, and Prompt for preset workflows. The Resource Plane is intentionally disposable scaffolding: if native model memory or HOPE-style sleep cycles make explicit context fetching obsolete, remove the Resource Plane while preserving Tool and Prompt boundaries. Markdown remains the durable storage format; no vector database, embeddings layer, or RAG stack is introduced.

#### Guardrails
- This track must not derail the 0.1 Developer Preview rename, release-candidate soak, or launch hygiene.
- 0.1 ships without an MCP server, MCP install path, or FastMCP runtime dependency.
- Any write-capable MCP tool must preserve approval-before-write semantics.
- MCP must remain agent-agnostic, not a Claude-only integration.
- Docker remains deferred. Tool Plane isolation starts from subprocess plus `/tmp` sandboxing only after a dedicated Tool Plane threat model.
- FastMCP adoption requires a separate architecture decision before implementation work lands on the shipping path.

#### Phase M0 - Resource Plane Research Spike (parallel, non-shipping)
Goal: produce enough signal to decide whether MCP belongs in the post-0.1 runtime without changing the 0.1 product surface.

Scope:
- Build on an isolated branch or experimental path that is not required by install, boot, `ml` commands, or public docs.
- Evaluate FastMCP as a candidate dependency without adding it to the 0.1 shipping runtime.
- Prototype read-only MCP resources backed by the existing index-first memory model and path resolution.
- Compare Resource Plane behavior against `ml load` for targeted queries and entry-id retrieval.
- Produce one worked transcript showing an agent pulling targeted context through MCP.

Exit criteria:
- Equivalence notes cover global/project precedence, archive handling, entry-id retrieval, query ranking, deterministic ordering, and missing-entry behavior.
- Install and 0.1 docs remain unchanged unless a later approved decision promotes the spike.
- A go/no-go architecture decision records whether to continue, defer, or kill the full MCP track.

#### Phase M1 - Tool Plane (queued after go/no-go, no earlier than 1.1)
Goal: establish stable `@mcp.tool` execution boundaries.

Scope:
- Define a Tool Plane threat model before choosing subprocess, `/tmp`, Docker, or another isolation backend.
- Wrap test-suite and code-verification runs as MCP tools only after approval and isolation rules are settled.
- Require approval gates on every write-capable tool.
- Add behavior-contract tests for each tool, mirroring the existing `verify/test.sh` discipline.

#### Phase M2 - Prompt Plane and Cutover (queued after cross-agent proof)
Goal: move preset workflows into MCP prompts only when the supported agent clients can carry the contract.

Scope:
- Build a Codex, Claude Code, Cursor, and future-agent capability matrix before deprecating any existing hook.
- Port slash-command-style workflows to MCP prompts where client support is strong enough.
- Keep thin adapters as bootstraps; product facts and command behavior stay in `.mindlayer/`, shipped templates, command specs, or runtime code.

#### HOPE-Era Migration Note
The Resource Plane is the only disposable layer. If native model memory makes explicit context fetching unnecessary, remove read resources and keep Tool and Prompt planes as the execution and workflow surface.

#### Related
ml-20260517-002
ml-20260507-004
ml-20260510-002
ml-20260510-004
ml-20260627-002

### Out of Scope Until Signal Says Otherwise
- Shipping MCP server before 1.1.
- Hosted/SaaS layer.
- Teams/shared memory before 1.0 ships.
- Embeddings/vector store, because that breaks the zero-infra wedge.
- Homebrew — install.sh already covers macOS and Linux without it.

### Related
ml-20260517-001
ml-20260510-001
