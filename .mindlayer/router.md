# Project Router

<!-- managed by MindLayer installer — last_updated: 2026-05-06 -->

Read this file immediately after `~/.mindlayer/router.md`. Follow the load triggers below for MindLayer project memory files.

## Auto-Load Behavior

Load triggers fire automatically — no approval required for reads. Load each file at most once per session. Load before acting on the trigger, not after.

Announcement format and rules are defined in `~/.mindlayer/memory-system/per-turn.md` (Load Announcement Contract). Every load must be announced — do not load silently.

## Always Load (handled by boot sequence)

- `index.md`, `project.md`, `progress.md`, `backlog.md`

## Conditional Loads

| File | Load when | Signal variants |
|---|---|---|
| `decisions.md` | Design or architecture question, or any slash command or skill invocation | "why", "how did we decide", "rationale", "design", "architecture", "reasoning", "tradeoff", "alternative", "why does X work", "why did we choose", "what was the decision on", "behavior", "rule change", "how is X implemented", "ml init", "ml load", "ml retrieve", "ml save", "ml status", "ml archive", "ml session", "ml clean", "skill", "slash command", "init" |
| `context.md` | MindLayer philosophy or product question | "what is MindLayer", "product goals", "design philosophy", "token strategy", "how does it work", "purpose", "principles", "constraints", "memory quality", "why markdown", "what are we building" |
| `risks.md` | Risk, installer, or trust question | "risk", "failure", "installer", "trust", "safety", "crash", "onboarding", "edge case", "what could go wrong", "concern", "scaffold false confidence", "silent behavior", "adapter drift" |
| `roadmap.md` | Planning or versioning question | "roadmap", "future", "what's next", "V3", "V4", "phase", "long term", "plan", "next major", "coming up", "vision", "after this", "what comes after V3" |
| `sessions/YYYY-MM-DD.md` | Session recovery | "where were we", "last session", "what did we work on", "catch me up", "remind me", "what was left", ml status invoked |

## Failsafe Rules

- Load each file at most once per session.
- When in doubt, load.
- Never load `archive.md` unless ml load explicitly targets archived content.
- Never load `local.md` unless index marks it relevant or user explicitly references it.
