# Roadmap

Canonical project roadmap for MindLayer. Public `ROADMAP.md` mirrors this file for human readers; `.mindlayer/` remains the source of truth.

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

Architecture: keep the two-layer markdown memory model, thin adapters, adapter/CLI-first runtime, explicit approval before writes, and SCRIPT lifecycle. No MCP server in 0.1.

Methodology in force: `knowledge/decisions/script-v0.1.md`.

### Stage 0.1 - Developer Preview
Goal: correctness, positioning, and open-source basics with honest preview framing.

Scope:
- Fix 11 verified correctness findings: starter boot truth, personal preference starter detection, missing project router, `ml load` section resolution, ranking without query hits, false duplicate headings, hierarchical `ml clean`, nearest-index `ml save`, README CLI drift, adapter-doc drift, and archived items appearing as new in `ml diff`.
- Rewrite README around "human-approved, git-trackable memory for AI coding agents."
- Add `comparison.md`, CONTRIBUTING, SECURITY, Code of Conduct, issue/PR templates, CODEOWNERS, one quickstart example, minimal CI, CHANGELOG, release notes, and clean test/lint output.

Exit criteria:
- Full install -> boot -> load -> save -> status -> `ml script status` path works from public docs without maintainer help.
- `tools/test.sh` passes and strict lint is clean.
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

### Out of Scope Until Signal Says Otherwise
- MCP server before 1.1.
- Hosted/SaaS layer.
- Teams/shared memory before 1.0 ships.
- Embeddings/vector store, because that breaks the zero-infra wedge.
- Homebrew — install.sh already covers macOS and Linux without it.

### Related
ml-20260517-001
ml-20260510-001
