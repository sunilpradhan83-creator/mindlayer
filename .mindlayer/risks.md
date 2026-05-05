# Risks

Known risks, blockers, fragile areas, and trust concerns.

## V1 Trust and Quality Risks

id: ml-20260430-006
created: 2026-04-30
updated: 2026-05-05
scope: project
type: risk
tags: [trust, tokens, installer, onboarding]
confidence: high
status: active
source: manual

### Summary
MindLayer must stay safe, compact, and trustworthy across all install scenarios.

### Details
- Token bloat: too much memory loaded at boot hurts efficiency. Keep L0 minimal.
- Wrong routing: agents writing durable memory to adapters instead of `.mindlayer/` files breaks the source boundary.
- Installer safety: destructive behavior on reinstall would destroy user work.
- Scaffold false confidence: placeholder files treated as real memory waste tokens and mislead agents.
- Adapter drift: duplicated memory in tool-specific files gets out of sync over time.
- Undiscoverable memory: files that exist but lack index entries are effectively unavailable.
- Existing project onboarding gap: no automated way to populate `.mindlayer/` from existing project knowledge on first install into a mature project. Users must populate manually or with agent assistance.
- Silent behavior change: `memory-system.md` refreshes on reinstall silently change agent behavior without user awareness.

### When to use
Use when changing prompts, installer behavior, adapter content, or planning new install scenarios.

### Related
ml-20260430-003
