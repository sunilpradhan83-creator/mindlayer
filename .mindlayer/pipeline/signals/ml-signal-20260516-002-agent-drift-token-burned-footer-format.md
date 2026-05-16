---
id: ml-signal-20260516-002
title: Agent drift: Token Burned footer format
created: 2026-05-16
tier: auto
status: merged
merged_into: ml-signal-20260516-005
---

Agent was emitting a stripped-down freeform Token Burned footer instead of the exact block specified in `~/.mindlayer/memory-system/per-turn.md`. Correct format requires separator lines, word/token estimates with `~`, and `Coming Up` section. Root cause: per-turn.md contract not being applied precisely. Revisit to determine if enforcement needs to be strengthened (hook, validator, or spec clarification).
