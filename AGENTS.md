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

Run MindLayer boot at session start or tool preflight when the host supports it. If no preflight hook exists, run boot before answering the first project-relevant request. Do not treat a plain greeting as project-relevant.


<!-- mindlayer:start -->
MindLayer memory is stored outside this adapter.

Global memory: `~/.mindlayer/`
Project memory: `.mindlayer/`

MindLayer boot should run at session start or tool preflight when the host supports it. If no preflight hook exists, run boot before answering the first project-relevant request. Do not treat a plain greeting as project-relevant.

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
Approx. N words loaded (~N est. tokens).

Context share:
- Global memory: ~N%
- Project memory: ~N%
- Other sources: 0% (README.md, docs/, and adapters skipped)

Token strategy:
L0 boot: command rules, indexes, substantive preferences, project identity, and latest progress only.

Ready.
What would you like to work on?
```

`/m-init` is a legacy/manual refresh alias for showing or rerunning the boot receipt.
Use `/m-retrieve <query>` when specific memory is needed.
Use `/m-save` only to propose memory writes; never write without approval.
Use `/m-status` to check memory health.
Use `/m-session` to report session context cost and recommend compact or new session.
Use `/m-archive` (alias: `/m-clean`) to scan for stale entries and propose archive or delete actions.

Commands are also triggered proactively. See the Proactive Behavior section in `~/.mindlayer/memory-system.md` for end-of-turn detection rules, trigger phrases, and surface formats.
<!-- mindlayer:end -->
