# Risks

## V1 Trust Risks

id: ml-20260430-006
created: 2026-04-30
updated: 2026-04-30
scope: project
type: risk
tags: [trust, tokens, installer]
confidence: high
status: active
source: manual

### Summary
MindLayer must stay safe, compact, and trustworthy.

### Details
- Too much memory may hurt token efficiency.
- Wrong routing may reduce trust.
- Installer must avoid destructive behavior.
- Installer safety depends on testing local installs, idempotent reruns, global memory creation, adapter marker updates, and fresh dummy projects.
- Deployment confidence depends on a maintained sandbox test suite that checks fresh install, existing project install, idempotence, preservation of user files, global/project memory integrity, adapter block duplication, index integrity, and `/m-init` contract alignment.
- Readiness tests must verify discoverability through indexes and `/m-init` reporting paths, not only file existence. A memory file can exist but still be effectively unavailable if the relevant index omits it.
- Scaffold files may cause token waste and false confidence if treated as real memory.
- Tool-specific files may drift if duplicated.

### When to use
Use when changing prompts, installer behavior, or adapter content.

### Related
ml-20260430-003
