# Roadmap

Long-term versioned vision. Full roadmap lives in `ROADMAP.md` in the repo root.

## MindLayer Product Roadmap

id: ml-20260505-003
created: 2026-05-05
updated: 2026-05-08
scope: project
type: roadmap
tags: [roadmap, v2, v3, v4, script, cli]
confidence: medium
status: active
source: manual

### Summary
V1, V2, and V3 shipped. V4 targets a SCRIPT-driven product engine and lifecycle runtime first: Signal routing, Roadmap → Backlog → Agent Stories → Progress artifact queue, Transfer to Learning/History paths, and then IDE integrations.

### Details
- V1 (shipped): installer, prompt commands, thin adapters, boot/continuity/install contracts.
- V2 (shipped): proactive behavior, archive mode, `ml session`, `private/` `sessions/` `cache/` `tmp/` subdirectories, Token Burned per-turn block.
- V3 (shipped): memory health scoring, memory diff, auto-summarization, `ml load` primary command, and ranked-load contract for agent-executed retrieval.
- V4: SCRIPT product engine and deterministic lifecycle runtime. Signal is universal ingress; Roadmap → Backlog → Agent Stories → Progress is the artifact queue; Transfer writes to Learning Path (`.mindlayer/learnings/`) and History Path (`.mindlayer/history/`). Start spec-first, then build a local Python `ml` runtime. IDE extensions follow after lifecycle runtime stability.
- V5+: teams, SaaS. Full vision in `ROADMAP.md`.
- SCRIPT development philosophy defined in `ROADMAP.md` and `context.md` (ml-20260507-001).
- SCRIPT Product Engine Architecture saved in `decisions.md` (ml-20260508-002).

### Status
V1 shipped. V2 shipped. V3 shipped. V4 is next.

### Related
ml-20260430-005
ml-20260507-001

---

## Open Source Security Hardening

id: ml-20260510-001
created: 2026-05-10
updated: 2026-05-10
scope: project
type: roadmap
tags: [security, open-source, release, governance]
confidence: high
status: planned
source: manual

### Summary
Before open sourcing MindLayer, ship a security hardening layer targeting the distribution and governance threat surface — not the dogfood test layer.

### Details
Three threat vectors identified, each requiring a distinct mitigation:

**1. Malicious contributor modifying memory templates**
- Add CODEOWNERS file — any change to `global-template/` requires 2 maintainer approvals
- GitHub branch protection on `main` — no direct pushes, mandatory PR review
- Separate CODEOWNERS entries for `global-template/`, `install.sh`, and `tools/`

**2. Supply chain attack on the published package**
- Sign releases (GPG or sigstore)
- Publish checksums for `install.sh` alongside each release
- Pin dependencies and audit them on every release

**3. Developer running unreviewed local changes**
- Document clearly in CONTRIBUTING.md that dogfood should only be run on reviewed code
- The dogfood temp dir sandbox is sufficient for this tier — Docker is not needed

### Decision
Security investment belongs at the distribution and governance layer, not the dogfood test layer. Docker in dogfood would be security theater — it protects the wrong layer.

### Status
Planned. To be implemented before first public open source release.
