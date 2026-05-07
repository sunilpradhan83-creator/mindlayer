# Project Router

<!-- managed by MindLayer installer — last_updated: YYYY-MM-DD -->

Read this file immediately after `~/.mindlayer/router.md`. Follow the load triggers below for project memory files.

## Auto-Load Behavior

Load triggers fire automatically — no approval required for reads. After loading, append a one-line notification before the response:

```text
Loaded: <file.md> — <reason>
```

Load each file at most once per session. Load before acting on the trigger, not after.

## Always Load (handled by boot sequence)

- `index.md`, `project.md`, `progress.md`, `backlog.md`

## Conditional Loads

| File | Load when | Signal variants |
|---|---|---|
| `decisions.md` | Design or architecture question | "why", "how did we decide", "rationale", "design", "architecture", "reasoning", "tradeoff", "alternative", "why does X work", "why did we choose", "what was the decision", "behavior", "rule" |
| `context.md` | Product or philosophy question | "what is this project", "product goals", "philosophy", "purpose", "principles", "constraints", "how does it work", "design goals", "vision", "what are we building" |
| `risks.md` | Risk or safety question | "risk", "failure", "trust", "safety", "crash", "edge case", "what could go wrong", "concern", "downside", "problem with", "danger", "careful" |
| `roadmap.md` | Planning or vision question | "roadmap", "future", "what's next", "version", "phase", "long term", "plan", "next major", "coming up", "vision", "after this", "what comes after" |
| `sessions/YYYY-MM-DD.md` | Session recovery | "where were we", "last session", "what did we work on", "catch me up", "remind me", "what was left", ml status invoked |

## Failsafe Rules

- Load each file at most once per session.
- When in doubt, load.
- Never load `archive.md` unless ml load explicitly targets archived content.
- Never load `local.md` unless index marks it relevant or user explicitly references it.
