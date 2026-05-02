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

The installer creates missing memory files and directories. It does not overwrite existing memory files. Existing adapter files are updated only inside MindLayer marker blocks.

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
