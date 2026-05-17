# Security Policy

## Supported Versions

MindLayer is in **0.1 Developer Preview**. Only the latest commit on `main` is supported.

## Reporting a Vulnerability

Do not open a public GitHub issue for security vulnerabilities.

Email **sunilpradhan83@gmail.com** with:

- A description of the vulnerability
- Steps to reproduce
- Potential impact

You should receive a response within 72 hours. If the report is confirmed, a fix will be prioritized and a patched release will follow as soon as practical.

## Scope

MindLayer is a local tool. It does not run a server, make outbound network requests, or store data remotely. The main attack surface is the installer (`install.sh`) and the `ml` CLI commands, particularly:

- **`install.sh`**: writes files to `~/.mindlayer/` and the project directory. A malicious or tampered installer could overwrite arbitrary files.
- **`ml save` / `ml clean`**: write to or delete memory files under `.mindlayer/`. Both require explicit user approval before acting.
- **Memory files**: plain markdown committed to git. Do not store secrets, tokens, or credentials in `.mindlayer/`.

## Out of Scope

- Issues in AI tool providers (Claude, Codex, Cursor, Copilot) that MindLayer integrates with.
- Social engineering or phishing attacks.
- Vulnerabilities that require physical access to the machine.
