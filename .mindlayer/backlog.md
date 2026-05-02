# Backlog

## Future Roadmap

id: ml-20260430-005
created: 2026-04-30
updated: 2026-04-30
scope: project
type: backlog
tags: [roadmap]
confidence: medium
status: active
source: manual

### Summary
Future work belongs after the simple V1 seed.

### Details
- CLI in V2.
- VS Code extension later.
- Archive mode later.
- Optional vector search later.
- SaaS/product exploration later.

### When to use
Use when planning post-V1 work.

### Related
ml-20260430-003

## Deploy Readiness Test Harness

id: ml-20260502-001
created: 2026-05-02
updated: 2026-05-02
scope: project
type: backlog
tags: [testing, installer, deploy-readiness]
confidence: high
status: active
source: manual

### Summary
Add a sandboxed local readiness test suite that validates whether MindLayer is ready to deploy.

### Details
The suite should install MindLayer into both fresh and existing projects, exercise important installer and memory-contract edge cases, and report a clear deploy verdict. It should evolve with future feature changes and commits so it becomes a maintained deploy gate rather than a one-off installer check.

### When to use
Use when planning release validation, installer changes, or test coverage for new MindLayer features.

### Related
ml-20260430-006
