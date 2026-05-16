# Signals

## Bug: GEMINI.md missing from .gitignore, incorrectly committed to repo

id: ml-signal-20260516-006
created: 2026-05-16
tier: review
status: pending

GEMINI.md is a generated adapter file created on demand by install.sh when gemini_signal fires (Gemini CLI or ~/.gemini detected). It belongs to the same class as .cursor/rules/mindlayer.md and .windsurf/rules/mindlayer.md — both of which are correctly gitignored. GEMINI.md is missing from .gitignore, which allowed it to surface as untracked and get committed to the repo in error (commit 9c8c1ad).

Fixes required:
1. Add GEMINI.md to .gitignore (consistent with cursor/windsurf adapters)
2. git rm --cached GEMINI.md to untrack it from the repo
3. Verify install.sh lint checks do not require GEMINI.md to be committed

Broader principle: all on-demand generated adapter files must be gitignored at the time the template and install logic are added — not after the fact.

## Populate personal.md with developer personal intent

id: ml-signal-20260516-001
created: 2026-05-16
tier: auto
status: pending

personal.md is the correct home for cross-project developer personal preferences and intent. Currently scaffold-only. Needs to be filled with real preferences so it loads at every boot (non-scaffold condition in boot step 5). Also: evaluate making boot step 5 unconditional to close bootstrap gap on fresh installs.

## Agent drift: Next Step derived conversationally instead of by rule chain

id: ml-signal-20260516-004
created: 2026-05-16
tier: auto
status: pending

Agent has been deriving "Next Step" in the Token Burned footer conversationally ("awaiting direction", "continue with X") instead of applying the 5-rule priority chain defined in `~/.mindlayer/memory-system/per-turn.md`. Rule 2 (uncommitted changes → commit) was skipped multiple times in this session. Revisit to determine if the rule chain needs to be enforced more explicitly, or if a validator/check can catch drift before it surfaces.

## Redefine signal processing workflow and Cut step

id: ml-signal-20260516-005
created: 2026-05-16
tier: review
status: pending

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

## Refactor signals storage to folder-per-signal layout

id: ml-signal-20260516-003
created: 2026-05-16
tier: plan
status: pending

Signals should move from a single `signals.md` file to a `signals/` folder. Each signal gets its own file named by a unique human-readable name (not the id). A `signals/index.md` serves as the index. Plan the folder structure, naming convention, and migration of existing signals before implementing.

## Agent drift: Token Burned footer format

id: ml-signal-20260516-002
created: 2026-05-16
tier: auto
status: pending

Agent was emitting a stripped-down freeform Token Burned footer instead of the exact block specified in `~/.mindlayer/memory-system/per-turn.md`. Correct format requires separator lines, word/token estimates with `~`, and `Coming Up` section. Root cause: per-turn.md contract not being applied precisely. Revisit to determine if enforcement needs to be strengthened (hook, validator, or spec clarification).
