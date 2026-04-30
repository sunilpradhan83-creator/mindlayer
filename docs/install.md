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

