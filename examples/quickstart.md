# Quickstart: First Session with MindLayer

This walkthrough shows what a real first session looks like after installing MindLayer into an existing project. It assumes Claude Code, but the same pattern works in Cursor, Codex, or any MindLayer-aware agent.

---

## 1. Install

```sh
cd your-project
bash install.sh --project .
```

The installer creates `.mindlayer/` in your project and `~/.mindlayer/` globally. It writes adapter files (`AGENTS.md`, `CLAUDE.md`, etc.) but does not touch your code.

---

## 2. Boot the session

Open your AI coding tool and ask it to boot:

```
ml boot
```

The agent loads minimal context — your global preferences, project identity, current progress, and the command index — and prints a receipt showing what was loaded and how many tokens it cost.

If `.mindlayer/knowledge/project.md` is a placeholder (fresh install), the agent will offer to run `ml onboard` to help populate it from your existing README and code.

---

## 3. Work on something

Do your normal work. The agent has project context and knows how to save memory when something durable happens.

---

## 4. Save a decision

When you make a durable decision, the agent should surface it as a memory candidate. If it doesn't, ask explicitly:

```
ml save
```

The agent will propose what to save, where, and what the entry should say. You approve or reject each candidate before anything is written.

Example output:

```
Memory candidate:
  file: .mindlayer/knowledge/decisions/auth.md
  section: ## JWT Token Expiry Decision
  action: create
  content: >
    Chose 15-minute access tokens with 7-day refresh tokens.
    Reason: balances session usability with security exposure
    on shared machines.

Approve? [y/n]
```

---

## 5. Check memory health

```
ml status
```

Shows per-file health (OK / WARN / CRITICAL), stale entries, and what to do next. Run this whenever memory feels out of date.

---

## 6. Load specific memory

In a new session, instead of loading everything:

```
ml load auth decisions
```

The agent fetches relevant memory from the index and loads only the sections that match, ranked by relevance.

---

## 7. End the session

```
ml session
```

Shows how much context the session has consumed and whether to compact or start fresh. At a task boundary, prefer starting a new session: save progress first, then start fresh. The next session boots from durable memory, not from chat history.

---

## What the file layout looks like after a few sessions

```text
.mindlayer/
  index.md                    ← compact search map for the project
  router.md                   ← tells the agent how to route requests
  knowledge/
    project.md                ← product identity and north star
    context.md                ← design philosophy, non-obvious constraints
    decisions/
      index.md
      auth.md                 ← decision captured in step 4
    risks.md
  pipeline/
    progress.md               ← current phase and next step
    backlog.md
    roadmap.md
```

Everything in `.mindlayer/` is plain markdown. Commit the shared files, ignore the private ones (see `.gitignore`).
