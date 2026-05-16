---
id: ml-signal-20260516-005
title: Redefine signal processing workflow and Cut step
created: 2026-05-16
tier: review
status: completed
---

Redefine how signals are processed end-to-end, with a new precise definition of Cut.

**New Cut definition:**
Cut is the full editorial pass on raw signals before anything routes anywhere. It is not just routing. In sequence, Cut must:
1. Remove ambiguity — clarify vague or under-specified signals
2. Merge correlated signals — related signals become one before planning
3. Drop signals that are misaligned with the goal, misleading, or not urgent now (this is the literal meaning of "cut" — editorial removal)
4. Produce a fully fledged plan for what remains
5. Make each surviving signal refine-ready (story-level detail)
6. Always requires human (developer) review and explicit approval before routing to destination

No signal routes without passing through a complete Cut. Auto-routing is removed entirely.

**Workflow rename:** this full activity is called "signal processing."

**Tier/type fields** on signals need redesign to reflect this human-first model — no more "auto" tier.

Correlated signals to merge during Cut: ml-signal-20260516-002 (Token Burned footer drift) and ml-signal-20260516-004 (Next Step rule chain drift) — same root cause, one plan.
ml-signal-20260516-003 (signals folder refactor) depends on ml-signal-20260516-005 completing first.
