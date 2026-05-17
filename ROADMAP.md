# MindLayer Roadmap

MindLayer is moving toward a **0.1 Developer Preview**, not a 1.0 launch. The goal is to earn trust through correctness, dogfood, and external users before claiming stability.

Canonical planning lives in `.mindlayer/pipeline/roadmap.md`. This file is the public, human-facing mirror.

---

## Positioning

MindLayer is **human-approved, git-trackable memory for AI coding agents**.

It is for solo AI-native developers using tools like Codex, Claude Code, Cursor, or similar agents. The product keeps durable project memory in plain markdown, keeps writes approval-gated, and uses SCRIPT as the workflow inside the system.

SCRIPT currently means:

`Signal -> Cut -> Refine -> Implement -> Prove -> Transfer`

For 0.1, the methodology is intentionally simple: capture signals, cut them by size, turn approved work into lean stories, prove the result, and optionally transfer durable lessons with human approval.

---

## 0.1 Developer Preview

**Goal:** correctness, positioning, and open-source basics.

0.1 is a developer preview. It should be useful to early solo developers who want to dogfood it, but it is not a polished stable release.

Planned scope:

- Fix verified correctness bugs in boot, load, status, clean, save, diff, and docs.
- Rewrite README around the real product wedge.
- Add `comparison.md` with dated, fact-only competitor context.
- Add open-source basics: CONTRIBUTING, SECURITY, Code of Conduct, issue/PR templates, CODEOWNERS, one worked example, minimal CI, CHANGELOG, and release notes.
- Clean passing test/lint output.

Public launch is gated by an rc soak period: at least 48-72 hours and at least 3 independent fresh installs that complete install -> boot -> save without maintainer help.

---

## 0.2 Reliability

**Goal:** make MindLayer dependable for repeat daily use.

Planned scope:

- Reduce boot weight toward roughly 3,500 L0 tokens.
- Expand CI to Ubuntu Python 3.9-3.12.
- Add boot-weight regression checks.
- Add `ml status --lifecycle` once SCRIPT v0.1 data exists in real dogfood.
- Decide which SCRIPT rules become CLI-enforced, status-warned, or convention-only.
- Add a read-only docs drift checker that proposes sync without silently rewriting human-facing docs.

---

## 0.3 Cross-Agent Proof

**Goal:** prove the product works across the tools it claims to support.

Planned scope:

- Public dogfood transcripts for Codex, Claude Code, and Cursor.
- At least 3 worked examples in the repo.
- Migration notes from adjacent tools where real migration data exists.
- Fewer "what just happened?" moments in fresh-user runs.

---

## 1.0 Public Stable

1.0 is earned, not scheduled.

MindLayer should not ship 1.0 until all of these hold:

- At least 5 external users run it for at least 4 weeks.
- Zero open critical bugs.
- At least one unsolicited third-party blog post or public repo uses it.
- Install -> boot -> load -> save -> status -> SCRIPT flow works from public docs alone.
- 0.1 correctness invariants still hold.
- CHANGELOG covers every change since 0.1.
- Adapter/CLI behavior is stable across at least 2 of Codex, Claude Code, and Cursor.
- VS Code extension available so VS Code users can install without touching a terminal.

---

## 2.0 Ecosystem Reach

**Goal:** reach users in environments where `curl | bash` is blocked or insufficient.

Planned scope:

- Rename package if `mindlayer` is taken on PyPI at the time of 2.0.
- PyPI package (`pip install mindlayer`) for corporate environments using internal package registries.
- `ml install` Python command that replaces install.sh logic, making pip install a complete one-step setup path.

---

## Principles

- Memory is curation, not a chat dump.
- Humans approve durable memory writes.
- Memory stays plain markdown and git-trackable.
- Adapters stay thin; `.mindlayer/` is the source of truth.
- Docs are human-facing mirrors, not boot memory.
- No silent README/ROADMAP generation; future tooling may propose sync, never overwrite.
- Zero-infra is a core wedge, so embeddings/vector stores stay off-roadmap unless the strategy changes deliberately.
