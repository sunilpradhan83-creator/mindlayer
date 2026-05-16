---
id: ml-signal-20260516-006
title: Bug: GEMINI.md missing from .gitignore, incorrectly committed to repo
created: 2026-05-16
tier: review
status: completed
---

GEMINI.md is a generated adapter file created on demand by install.sh when gemini_signal fires (Gemini CLI or ~/.gemini detected). It belongs to the same class as .cursor/rules/mindlayer.md and .windsurf/rules/mindlayer.md — both of which are correctly gitignored. GEMINI.md is missing from .gitignore, which allowed it to surface as untracked and get committed to the repo in error (commit 9c8c1ad).

Fixes required:
1. Add GEMINI.md to .gitignore (consistent with cursor/windsurf adapters)
2. git rm --cached GEMINI.md to untrack it from the repo
3. Verify install.sh lint checks do not require GEMINI.md to be committed

Broader principle: all on-demand generated adapter files must be gitignored at the time the template and install logic are added — not after the fact.
