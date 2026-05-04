# MindLayer Agent Instructions

MindLayer is a markdown-first memory system for AI-native software developers. It separates durable memory from tool-specific instruction files.

Global user memory lives at:

```text
~/.mindlayer/
```

Project memory lives at:

```text
project/.mindlayer/
```

Tool adapters such as `AGENTS.md`, `CLAUDE.md`, and `.github/copilot-instructions.md` are not memory stores. They are thin instructions for using MindLayer and should not be used as durable retrieval sources beyond these instructions.

Human documentation such as `README.md` and `docs/` explains the tool for people. It is not default AI memory input.

## Commands

- MindLayer boot: initialize the session with minimal useful memory context.
- `/m-retrieve <query>`: fetch specific memory on demand using indexes first.
- `/m-save`: analyze recent work and propose memory writes. Never write without approval.
- `/m-status`: check memory health and suggest fixes.

## Rules

- Do not use `README.md` or `docs/` as memory input.
- Do not write memory without explicit user approval.
- Use index files before loading full memory files.
- Prefer updating existing memory over creating duplicates.
- Keep token usage transparent: state what was loaded and skipped.
- Do not dump raw conversations into memory.
- Route user-owned cross-project preferences to `~/.mindlayer/preferences.md`.
- Route project facts, decisions, progress, risks, and backlog to `project/.mindlayer/`.
- Keep tool-specific files thin. Do not duplicate memory into adapters or retrieve durable context from adapters.
- Go outside MindLayer memory only when necessary for the task.

Run MindLayer boot at session start or tool preflight when the host supports it. If no preflight hook exists, run boot before answering the first project-relevant request. Do not treat a plain greeting as project-relevant. When memory is needed, use `/m-retrieve`. When saving memory, use `/m-save`. For health checks, use `/m-status`. `/m-init` is a legacy/manual refresh alias for showing or rerunning the boot receipt.

MindLayer Handoff is a checkpoint/status artifact, not running commentary. Show it only at task end, explicit status or next-step requests, pause, block, handoff, or recovery. Do not show it before/after every command or during routine progress updates; use plain concise updates with a proactive next-step cue when useful.

Preferred handoff shape:

```text
Backlog item: <larger durable goal>
Task: <current concrete work>
  - Last result: <what just happened>
  - Next step: <smallest useful action>
  - Status: active | blocked | paused | completed

Context:
  - Task: ~<N> words, ~<N> est. tokens
  - Session: ~<N> words, ~<N> est. tokens
```

Use this exact boot receipt format when the boot is visible to the user:

```text
MindLayer context loaded.

Loaded:
- ...

Skipped:
- ...

Missing:
- ...

Current understanding:
...

Current progress:
...

Context cost:
Approx. N words loaded.

Ready.
What would you like to work on?
```


<!-- mindlayer:start -->
MindLayer memory is stored outside this adapter.

Global memory: `~/.mindlayer/`
Project memory: `.mindlayer/`

MindLayer boot should run at session start or tool preflight when the host supports it. If no preflight hook exists, run boot before answering the first project-relevant request. Do not treat a plain greeting as project-relevant.

MindLayer Handoff is a checkpoint/status artifact, not running commentary. Show it only at task end, explicit status or next-step requests, pause, block, handoff, or recovery. Do not show it before/after every command or during routine progress updates; use plain concise updates with a proactive next-step cue when useful.

Preferred handoff shape:

```text
Backlog item: <larger durable goal>
Task: <current concrete work>
  - Last result: <what just happened>
  - Next step: <smallest useful action>
  - Status: active | blocked | paused | completed

Context:
  - Task: ~<N> words, ~<N> est. tokens
  - Session: ~<N> words, ~<N> est. tokens
```

Boot order:
1. Read `~/.mindlayer/memory-system.md` first when available.
2. Read `~/.mindlayer/index.md` and `.mindlayer/index.md`.
3. Load substantive user preferences when present, project identity, and current progress.

Use this exact boot receipt format when the boot is visible to the user:

```text
MindLayer context loaded.

Loaded:
- ...

Skipped:
- ...

Missing:
- ...

Current understanding:
...

Current progress:
...

Context cost:
Approx. N words loaded.

Ready.
What would you like to work on?
```

`/m-init` is a legacy/manual refresh alias for showing or rerunning the boot receipt.
Use `/m-retrieve <query>` when specific memory is needed.
Use `/m-save` only to propose memory writes; never write without approval.
Use `/m-status` to check memory health.

Rules:
- Do not use `README.md` or `docs/` as memory input.
- Use index files before full files.
- Prefer update over duplicate.
- Keep token usage transparent.
- Do not dump raw conversations into memory.
- Keep adapters thin; do not store or retrieve durable memory here.
- Go outside MindLayer memory only when necessary for the task.
<!-- mindlayer:end -->
