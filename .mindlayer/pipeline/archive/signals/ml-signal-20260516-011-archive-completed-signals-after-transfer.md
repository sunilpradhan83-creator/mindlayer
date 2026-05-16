---
id: ml-signal-20260516-011
title: Archive completed signals after transfer
created: 2026-05-16
status: completed
---

Completed signals should be preserved for future context, but moved out of the active signal queue once their implementation story set transfers. Store active signals in .mindlayer/pipeline/signals/ and archived signal records in .mindlayer/pipeline/archive/signals/. Preserve ids, titles, statuses, Cut context, merged/dropped provenance, and body. Keep active and archive indexes so agents can retrieve why-context from signals and how-context from archived stories without active queue drift.
