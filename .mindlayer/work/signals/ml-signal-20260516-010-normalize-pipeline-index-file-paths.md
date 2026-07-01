---
id: ml-signal-20260516-010
title: Normalize pipeline index file paths
created: 2026-05-16
tier: auto
status: pending
---

pipeline/index.md uses bare filenames resolved by loader knowledge of pipeline files, while decisions entries use explicit root-relative paths. Not broken, but normalize for consistency and future resolver safety.
