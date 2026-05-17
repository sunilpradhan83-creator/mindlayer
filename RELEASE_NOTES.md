# MindLayer 0.1.0 — Developer Preview

**Status:** Developer Preview. Usable for early adopters willing to dogfood and report issues. Not a stable release.

---

## What This Is

MindLayer is human-approved, git-trackable memory for AI coding agents. It keeps durable project context in plain markdown files committed to git, with explicit approval before any memory write, and a local `ml` command runner as the control plane.

0.1 is the first public release. The goal is correctness and honest framing, not completeness.

---

## What Works

- **Install**: fresh and existing project install, idempotent reinstall, selective adapter detection, adapter integrity lock.
- **Boot**: minimal context load — global preferences, project identity, current progress, command index. Starter placeholders skipped.
- **`ml load <query>`**: ranked index-first retrieval, no false ranking on metadata alone.
- **`ml status`**: per-file health check with correct duplicate detection and W4 false-positive filtering.
- **`ml diff`**: memory changes since the last session commit, with correct archive and rename handling.
- **`ml save`**: approval-gated writes to the nearest index.
- **`ml clean`**: hierarchical archive/delete with approval.
- **`ml session`**: context cost report and compact/fresh-session recommendation.
- **`ml script`**: Signal → Cut → Refine → Implement → Prove → Transfer lifecycle commands.
- **Test suite**: install, behavior contract, and CLI contract tests. All pass on a clean clone.
- **Lint**: 0 errors, 1 known pre-existing warning (`script-v4.md` line budget).

---

## Known Limitations

- **No pip package.** Install via `install.sh` only. `mindlayer` is already taken on PyPI; rename pending.
- **No Python CI matrix.** CI runs on Python 3.12 only. 3.9–3.11 compatibility is untested.
- **No macOS CI.** Bash 3.2 compatibility on macOS is unverified.
- **`ml script` is partial.** The lifecycle commands work but the user-facing `ml script` walkthrough feature is deferred to 0.2.
- **No boot-weight guard.** Boot token cost is not regression-tested yet.
- **Fresh-user rough edges.** The install-to-first-useful-session path works but has gaps documented in open issues.

---

## Installing

```sh
curl -fsSL https://raw.githubusercontent.com/sunilpradhan83-creator/mindlayer/main/install.sh | bash
```

See [`README.md`](README.md) for full install and usage instructions.

---

## Feedback

Open an issue on GitHub. See [`CONTRIBUTING.md`](CONTRIBUTING.md) before submitting a PR.
