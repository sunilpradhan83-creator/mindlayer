---
id: ml-signal-20260516-007
title: Warn on broken index pointers
created: 2026-05-16
tier: auto
status: pending
---

Recursive index traversal currently treats missing pointer targets as empty indexes because parse_index returns [] when the referenced file does not exist. A typo in a pointer entry like knowledge/index.md can silently hide all entries below that pointer. Future work should add a diagnostic or validation path for missing pointer target files before story-002 starts creating and relying on subfolder indexes.
