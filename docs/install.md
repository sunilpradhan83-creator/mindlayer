# Install

MindLayer installs markdown memory files and thin tool adapters.

Remote install:

```sh
curl -fsSL https://raw.githubusercontent.com/<USER>/mindlayer/main/install.sh | bash
```

Local install:

```sh
bash install.sh --project .
```

## Flags

- `--project <path>` installs project memory into the given path. Default: current directory.
- `--global-only` creates or updates only `~/.mindlayer/`.
- `--project-only` creates or updates only project `.mindlayer/` and adapters.
- `--no-adapters` skips `AGENTS.md`, `CLAUDE.md`, and Copilot instructions.
- `--no-gitignore` skips `.gitignore` updates.
- `--no-onboard` prints minimal output.
- `--tool all` installs all adapters. Default.
- `--tool codex` installs only `AGENTS.md`.
- `--tool claude` installs only `CLAUDE.md`.
- `--tool copilot` installs only `.github/copilot-instructions.md`.

## Safety

The installer creates missing memory files and directories. It may refresh managed MindLayer system instructions such as `~/.mindlayer/memory-system.md`, but it preserves user-owned memory such as `~/.mindlayer/preferences.md`. Existing adapter files are updated only inside MindLayer marker blocks.

## Session Boot

After install, MindLayer-aware adapters boot minimal context automatically when the host supports session preflight, or before the first project-relevant request as a fallback.

Boot reads `~/.mindlayer/memory-system.md` first when available, then indexes, substantive user preferences when present, project identity, and current progress. Starter-only preferences are skipped. `/m-init` remains a legacy/manual refresh alias while hosts migrate to automatic boot.

## Global Backup

Global memory lives outside project Git at `~/.mindlayer/`. This lets preferences work across projects and survive project deletion or recloning, but project commits do not back it up.

Back up `~/.mindlayer/` with your normal dotfiles, encrypted backup, or private personal repository if you want cross-project preferences preserved across machine loss. Do not store secrets, tokens, raw conversations, or project-specific facts in global preferences.

## Deploy Readiness

Run the full local validation suite before release or deploy:

```sh
tools/test.sh
```

This runs:

- `tools/lint.sh` for project memory and adapter invariants.
- `tests/local-install/test-install.sh` for sandboxed fresh-project and existing-project installer checks.

The readiness test overrides `HOME` inside temporary directories, so it does not write to the user's real `~/.mindlayer/`.

Expected final result:

```text
Verdict: READY TO DEPLOY
```
