# How MindLayer Compares

MindLayer occupies a specific niche: human-approved, git-trackable memory for solo AI-native developers. This page explains where it fits relative to common alternatives.

## vs. Tool instruction files (AGENTS.md, .cursorrules, system prompts)

Tool instruction files are loaded on every turn, run into token limits quickly, and live outside your project git history or duplicate it. They are also tool-specific — a `.cursorrules` file does nothing in Claude Code.

MindLayer uses these files as thin adapters that tell the agent *how to use MindLayer*, not as memory stores themselves. The actual memory stays in `.mindlayer/` markdown files, indexed and loaded on demand, with a global/project split that keeps preferences separate from project facts.

| | Instruction files alone | MindLayer |
|---|---|---|
| Token cost | Always loaded in full | Index-first, load on demand |
| Cross-tool | One file per tool | Single memory, all adapters |
| Git-trackable | Sometimes | Yes, by design |
| Write approval | Manual | Gated by `ml save` |

## vs. Vector databases and embedding-based memory (mem0, Zep, Letta)

Embedding-based systems store memory in a backend, retrieve it by semantic similarity, and update it automatically. This trades transparency and control for retrieval power.

MindLayer makes the opposite tradeoff: plain markdown files, deterministic index-based retrieval, and human-approved writes. You can read every memory entry in a text editor, diff it in git, and roll it back.

| | Embedding memory | MindLayer |
|---|---|---|
| Storage | Backend / cloud | Local markdown files |
| Retrieval | Semantic similarity | Index + ranked keyword match |
| Writes | Automatic or semi-auto | Explicit human approval |
| Auditability | Opaque | Full git history |
| Offline | Requires service | Fully local |

## vs. Compaction and long-context models

Compaction and large context windows let you keep more chat history in the session. They help within a session but do not solve the across-session problem: each new session still starts cold.

MindLayer does not compete with compaction — it complements it. Use compaction mid-task when you need to keep going. Use MindLayer to save the durable parts so the next session starts warm. The two approaches together are better than either alone.

## vs. Project-specific scripts and dot files

Some developers keep a `CONTEXT.md`, `NOTES.md`, or a collection of dot files. This works at small scale but tends to drift: content gets stale, files proliferate, there is no retrieval strategy, and every agent reads everything every time.

MindLayer adds structure: a defined file layout, an index, a retrieval command, write approval, and health checks. It is more opinionated than free-form notes but stays in plain markdown.

## When MindLayer is not the right fit

- **You want automatic memory.** MindLayer requires explicit approval before any write. If you want the agent to silently learn and remember, look at embedding-based systems.
- **You need semantic similarity search.** MindLayer uses keyword and index-based retrieval. If your queries are highly varied and unstructured, vector retrieval may perform better.
- **You are using a single tool that already has good built-in memory.** Some tools (Cursor background agents, OpenAI memory) handle simple preference storage adequately. MindLayer adds value when you use multiple tools or want durable project memory across sessions.
- **You want a managed service.** MindLayer is entirely local. There is no hosted version, no sync, and no SaaS.
