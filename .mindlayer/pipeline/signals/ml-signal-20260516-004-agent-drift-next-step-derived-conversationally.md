---
id: ml-signal-20260516-004
title: Agent drift: Next Step derived conversationally instead of by rule chain
created: 2026-05-16
tier: auto
status: merged
merged_into: ml-signal-20260516-005
---

Agent has been deriving "Next Step" in the Token Burned footer conversationally ("awaiting direction", "continue with X") instead of applying the 5-rule priority chain defined in `~/.mindlayer/memory-system/per-turn.md`. Rule 2 (uncommitted changes → commit) was skipped multiple times in this session. Revisit to determine if the rule chain needs to be enforced more explicitly, or if a validator/check can catch drift before it surfaces.
