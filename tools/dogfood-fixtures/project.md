# Project Memory

## MindLayer Dogfood Test Project

id: ml-dogfood-20260510-001
created: 2026-05-10
updated: 2026-05-10
scope: project
type: context
tags: [mindlayer, dogfood, test]
confidence: high
status: active
source: manual

### Summary
This is a MindLayer dogfood test project. It exists to verify that MindLayer boots correctly, emits a valid boot receipt, respects source boundaries, and maintains session continuity.

### Details
- This project is a sandboxed install of MindLayer used for automated behavioral testing.
- It has no real codebase — only MindLayer memory files and adapter files.
- The dogfood test simulates a real user interacting with a MindLayer-enabled project.
- Tests cover: boot receipt on first project-relevant turn, session continuity, source boundary enforcement, and no-unsolicited-write discipline.

### When to use
Load at boot. This is the primary project identity file.
