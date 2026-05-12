# Project Memory Index — Boot Summary

Each line: id | title | file | one-line summary
Full entries live in `index-full.md`; load via `ml load` only.

- ml-project-20260430-001 | MindLayer Project Identity | project.md | Markdown-first installable memory system for AI-native developers.
- ml-20260503-001 | MindLayer Source-of-Truth Boundaries | decisions.md | Repo `.mindlayer/` is product memory; live `~/.mindlayer/` is runtime/test output.
- ml-20260503-002 | Literal Approval for Memory Writes | decisions.md | Memory writes need exact destination/content proposal and clear approval.
- ml-20260505-008 | Pre-Push Gate | decisions.md | Before push, agent asks whether tests were added/run; `yes` and `skip` both proceed.
- ml-20260505-007 | Lateral Intent Routing | decisions.md | Out-of-plan work gets a one-line backlog/roadmap nudge before proceeding.
- ml-20260505-005 | Token Burned Per-Turn Status Block | decisions.md | Every turn ends with estimates and a Next Step from the goal hierarchy.
- ml-20260430-004 | Product Design Philosophy | context.md | Token efficiency is the primary constraint; memory is curation, not chat dump.
- ml-20260505-004 | Goal Hierarchy and Flow | context.md | Project identity -> roadmap -> backlog -> progress -> sessions -> per-turn Next Step.
- ml-20260430-006 | V1 Trust and Quality Risks | risks.md | Tracks token bloat, routing, installer safety, onboarding, adapter drift, and trust risks.
- ml-20260430-005 | Future Roadmap | backlog.md | V4 command runner foundation is next; ROADMAP.md holds the full vision.
- ml-20260505-006 | Current Phase — V3 Memory Quality + Smarter Retrieval | progress.md | V3 complete; V4 command-runner foundation is next.
- ml-20260505-003 | MindLayer Product Roadmap | roadmap.md | V4 targets SCRIPT lifecycle runtime and future IDE integrations.
- ml-20260506-002 | Project Router | router.md | Project-level conditional load triggers for decisions, context, risks, roadmap, and sessions.
- ml-20260507-007 | Global-Template Sync Rule | decisions.md | Update live `~/.mindlayer` and `global-template` together for behavior changes.
- ml-20260507-006 | Per-Turn Behavioral Contract Compliance Risk | risks.md | Per-turn behaviors are instruction-enforced until V4 runtime hardens them.
- ml-20260507-003 | Router Enforcement Gap | risks.md | Router trigger rules are soft contracts until a command runner enforces them.
- ml-20260507-005 | ML-999 Backlog Evaluation Decisions | decisions.md | ML-101-110 decisions are settled unless new evidence appears.
- ml-20260510-002 | Dogfood Two-Script Architecture | decisions.md | `dogfood-boot.sh` is product gate; `dogfood-live.sh` is personal health check.
- ml-20260510-003 | AGENTS.md Boot Trigger Root Cause | decisions.md | Non-interactive agents need explicit boot-before-answer wording.
- ml-20260510-004 | Open Source Security Hardening Decision | decisions.md | Security belongs in distribution/governance, not dogfood isolation.
- ml-20260507-004 | Agent-Agnostic Design Principle | decisions.md | Product rules stay agent-agnostic; tool-specific logic belongs only in adapters.
- ml-20260507-002 | Skill Approval Gate | decisions.md | Writing skills/slash commands require explanation and explicit approval.
- ml-20260507-001 | SCRIPT Development Philosophy | context.md | Signal, Cut, Refine, Implement, Prove, Transfer guides human+AI development.
- ml-20260508-001 | Instruction-Only Architecture Ceiling | risks.md | V4 should add deterministic local runtime while keeping markdown storage.
- ml-20260508-002 | SCRIPT Product Engine Architecture | decisions.md | Signal ingress feeds Roadmap -> Backlog -> Agent Stories -> Progress.
- ml-20260511-002 | Adapter Freeze + Auto-Detection Architecture | decisions.md | Adapters are frozen templates; install auto-detects tools; user content routes via `ml save`.
