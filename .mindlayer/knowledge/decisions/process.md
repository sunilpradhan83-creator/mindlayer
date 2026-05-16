# Process Decisions

## ML-999 Backlog Evaluation Decisions
id: ml-20260507-005
created: 2026-05-07
updated: 2026-05-07
scope: project
type: decision
tags: [backlog, roadmap, ml-999, prioritization, v3, v4]
confidence: high
status: active
source: manual
### Summary
Backlog evaluation (ML-999, 2026-05-07) produced activation, defer, and reject decisions for ML-101 through ML-110. These decisions should not be re-litigated without new evidence.
### Details
- Rejected: ML-104, ML-105, ML-106, ML-107, ML-109, ML-110 due to overlap, premature scope, or violating MindLayer's deterministic/agent-agnostic boundaries.
- Deferred: ML-103 and ML-108 until evidence shows adapter gaps or `Related:` fields are insufficient.
- Activated partial ML-101 as ranked retrieval/loading on top of the existing index; no ML or new storage.
- Pulled `ml onboard` into V3 because onboarding mature projects was the biggest adoption barrier.


## MindLayer Source-of-Truth Boundaries
id: ml-20260503-001
created: 2026-05-03
updated: 2026-05-03
scope: project
type: decision
tags: [source-of-truth, templates, memory-routing]
confidence: high
status: active
source: manual
### Summary
While working inside the MindLayer repo, product memory should be saved to project `.mindlayer/`, shipped global behavior should be implemented through `global-template`, and live `~/.mindlayer/` should not be manually edited.
### Details
- Repo `.mindlayer/` is product memory for MindLayer itself.
- Live `~/.mindlayer/` is runtime/install/test output, not product-memory source of truth.
- `project-template` is starter memory for future users; `global-template` ships default global behavior.
- Operational behavior changes must be reflected in templates/adapters/specs, not only saved as memory.


## Literal Approval for Memory Writes
id: ml-20260503-002
created: 2026-05-03
updated: 2026-05-03
scope: project
type: decision
tags: [approval, memory-safety, commands]
confidence: high
status: active
source: manual
### Summary
Memory writes require literal explicit approval before editing durable memory.
### Details
Acknowledgments like `ok`, `got it`, or `we need to save this` are not approval. The agent must propose exact destination/content and wait for clear approval (`approve`, `go ahead`, etc.) before editing durable memory or behavior templates.


## Skill Approval Gate
id: ml-20260507-002
created: 2026-05-07
updated: 2026-05-07
scope: project
type: decision
tags: [approval, skills, ml-init, adapter-safety, memory-safety]
confidence: high
status: active
source: manual
### Summary
Skills that write files (such as the `init` skill triggered by `ml init`) must not execute autonomously in the MindLayer repo. The agent must read the target file, explain what the skill would do, and wait for explicit approval before any write.
### Details
- Skills/slash commands that write files, including `ml init`-triggered adapter rewrites, require the same literal approval as memory writes.
- If a skill writes without approval, revert and explain. MindLayer product learnings belong in MindLayer memory, not tool-native memory.


## Lateral Intent Routing
id: ml-20260505-007
created: 2026-05-05
updated: 2026-05-05
scope: project
type: decision
tags: [lateral-intent, routing, backlog, roadmap, proactive]
confidence: high
status: active
source: manual
### Summary
When a user introduces work outside the current Next Step or backlog, the agent classifies it silently and appends a one-line non-blocking nudge before proceeding.
### Details
- Classify out-of-plan work as backlog candidate, roadmap amendment, or ad-hoc.
- Append at most one non-blocking nudge before Token Burned; do not fire during boot/status or direct Next Step/backlog-pull responses.
- Capture only on explicit user response; approval rules still apply.


## Token Burned Per-Turn Status Block
id: ml-20260505-005
created: 2026-05-05
updated: 2026-05-06
scope: project
type: decision
tags: [session-continuity, per-turn, next-step, token-tracking, handoff, goal-hierarchy, coming-up, priority]
confidence: high
status: active
source: manual
### Summary
Handoff is deprecated. Every agent turn ends with a Token Burned block. Next Step is always a single plain-text action. Optional Coming Up: surfaces for ambiguity or long queues. Priority hierarchy is strictly enforced.
### Details
- Every turn ends with Token Burned, Session estimate, and nonblank `Next Step`; optional `Coming Up` appears only for ambiguity or long queues.
- Next Step hierarchy: active task → commit uncommitted changes → next backlog item → next roadmap phase → brainstorm next major version.
- `Coming Up` lists only lower-priority follow-ups; uncommitted changes always outrank new backlog work.


## SCRIPT Product Engine Architecture
id: ml-20260508-002
created: 2026-05-08
updated: 2026-05-08
scope: project
type: decision
tags: [script, v4, product-engine, lifecycle, roadmap, backlog, agent-stories, transfer]
confidence: high
status: active
source: conversation
### Summary
V4 reframes MindLayer as a SCRIPT-driven product development engine, not just a memory helper. Signal is the universal ingress point; Roadmap → Backlog → Agent Stories → Progress is the artifact queue; Transfer splits into Learning Path and History Path.
### Details
- SCRIPT remains the process flow: Signal → Cut → Refine → Implement → Prove → Transfer.
- Signal is detected by the agent but remains pending until human-approved routing; no `signals.md` durable queue is planned for V4.
- Approved Signals route to roadmap for product/version direction, backlog for near-term work, Agent Stories when already refined, progress for active execution state, or learning memory when the content is durable knowledge only.
- Roadmap, backlog, Agent Stories, and progress are artifact buckets in a queue. Ideas should be promoted through the queue rather than duplicated across files.
- Refine produces one or more Agent Stories with human in the loop; Agent Stories replace durable user stories/tasks/actions as the post-planning work unit an agent can execute.
- Transfer has two paths: Learning Path (`.mindlayer/learnings/` typed files for project, decisions, context, risks) and History Path (`.mindlayer/history/` version archives plus archive index for completed or inactive flow artifacts).
- V4 should be spec-first, then implemented by a local Python `ml` runtime. IDE integrations come after the lifecycle runtime is stable.
- **SUPERSEDED by ml-20260514-001** — signals.md durable queue is now confirmed for V4; routing rules and file ownership defined.



## Next Step Story ID Granularity

id: ml-20260514-005
created: 2026-05-14
updated: 2026-05-14
scope: project
type: decision
tags: [per-turn, next-step, script, stories, orientation]
confidence: medium
status: active
source: conversation

### Summary
Once `pipeline/stories/` contains ready or in-progress stories, Next Step must name the specific story ID and title, not the parent backlog item.

### Details
- Before Refine runs: Next Step names the backlog item (e.g. "Open source security hardening").
- After Refine runs: Next Step names the specific story (`ml-story-NNN — title`).
- Rationale: stories are the atomic executable unit; pointing at the backlog item once stories exist is too coarse and skips the SCRIPT discipline.
- In-progress story always takes priority over ready stories in Next Step.

### When to use
Use when applying the per-turn Next Step hierarchy once SCRIPT is active on a backlog item.

### Related
ml-20260505-005
ml-20260514-001


## Hierarchical Index Tree Architecture

id: ml-20260514-006
created: 2026-05-14
updated: 2026-05-14
scope: project
type: decision
tags: [index, architecture, tree, knowledge, pipeline, ml-load, schema]
confidence: high
status: active
source: conversation

### Summary
Root index.md maps to subfolder index files, not individual memory files. Each folder owns its own index, forming a navigable tree.

### Details
- Root `.mindlayer/index.md` maps to `knowledge/index.md` and `pipeline/index.md` — not to leaf files directly.
- Each subfolder index maps to its own files and further subfolder indexes.
- Agent load path: root index → subfolder index → specific file. Never loads full tree unless explicitly asked.
- `knowledge/decisions/` becomes a subfolder with its own `index.md` mapping one file per logical decision group (e.g. `script-v4.md`, `architecture.md`, `process.md`).
- Replaces flat `index.md` + `index-full.md` pattern with a navigable tree. `index-full.md` is deprecated by this structure.
- Impacts: index schema, lint E5/E6 file-existence and section-heading checks, `_paths.py` resolve logic, `ml load` traversal (must follow index pointers recursively), `ml save` routing (must update nearest subfolder index).
- Implementation is spec-first: write failing tests for tree traversal, then implement.

### When to use
Use when changing index structure, adding new knowledge subfolders, implementing ml load traversal, or planning the decisions/ split.

### Related
ml-20260512-001
ml-20260514-002
ml-20260514-005
