---
id: ml-signal-20260516-003
title: Refactor signals storage to folder-per-signal layout
created: 2026-05-16
tier: plan
status: cut-approved
---

Signals should move from a single `signals.md` file to a `signals/` folder. Each signal gets its own file named by a unique human-readable name (not the id). A `signals/index.md` serves as the index. Plan the folder structure, naming convention, and migration of existing signals before implementing.
