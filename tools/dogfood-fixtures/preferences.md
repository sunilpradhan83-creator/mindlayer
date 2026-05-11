# Dogfood Test Preferences

id: ml-dogfood-pref-20260510-001
created: 2026-05-10
updated: 2026-05-10
scope: global
type: preference
tags: [dogfood, test, boot]
confidence: high
status: active
source: manual

### Summary
Always emit the full MindLayer boot receipt at the start of every session, before answering any project-relevant question. Do not skip or abbreviate the boot receipt. Do not answer project questions before the boot receipt has been emitted.

### Details
- The boot receipt is mandatory on every project-relevant turn where boot has not yet run.
- A question like "what is this project?" is always project-relevant and must trigger boot.
- The boot receipt must appear before the answer, not after.
- Never answer a project question and then offer to boot — boot first, then answer.

### When to use
Every session, every project. Always-on.
