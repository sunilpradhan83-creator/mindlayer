# Context

## Memory as Intelligence Context

id: ml-20260430-004
created: 2026-04-30
updated: 2026-04-30
scope: project
type: context
tags: [memory, retrieval, lifecycle]
confidence: high
status: active
source: manual

### Summary
Memory is curation, routing, retrieval, and lifecycle.

### Details
MindLayer is prompt-first in V1. The installer makes the system one-pass usable by creating predictable files, adapters, indexes, and ignored local directories.

Initialization must distinguish structural presence vs semantic value to maintain low-token retrieval.

MindLayer's main motive is token-efficient AI work. Everything the AI needs for durable context should live in global and project MindLayer markdowns. Human documentation can explain the system, but should not become AI memory input unless the task specifically requires documentation work or external context.

### When to use
Use when deciding whether implementation details improve memory quality or merely add machinery.

### Related
ml-20260430-003

## AI-Efficient Memory Language

id: ml-20260503-003
created: 2026-05-03
updated: 2026-05-03
scope: project
type: context
tags: [ai-context, tokens, writing]
confidence: high
status: active
source: manual

### Summary
MindLayer memory should use clear, compact language that AI companions can understand with minimal ambiguity and token waste.

### Details
MindLayer memory files are durable context for AI companions. Entries should be short, explicit, and easy to retrieve. Jargon is acceptable when it is broadly understood and more efficient than a plain-language alternative, but clarity wins when wording could confuse agents or users.

### When to use
Use when writing or editing memory entries, templates, prompts, adapters, and command instructions.

### Related
ml-20260430-004
