"""Read-only adapter status detector.

Hashes frozen adapter files against `.mindlayer/adapters.lock` and reports drift.
This performs NO writes: no diff against canonical templates, no `ml save` routing,
no restore, no lock rewrites. Restore/routing stays in the boot markdown flow
(see `~/.mindlayer/boot.md` Adapter Guard) until a later migration slice.
"""

from __future__ import annotations

from dataclasses import dataclass
from hashlib import sha256
from pathlib import Path

# Frozen adapters, matching the boot.md Adapter Guard list.
FROZEN_ADAPTERS = (
    "AGENTS.md",
    "CLAUDE.md",
    "GEMINI.md",
    ".github/copilot-instructions.md",
    ".cursor/rules/mindlayer.md",
    ".windsurf/rules/mindlayer.md",
)


@dataclass
class AdapterStatus:
    name: str
    state: str  # "match" | "mismatch" | "unverified" | "absent"


def _hash_file(path: Path) -> str:
    return sha256(path.read_bytes()).hexdigest()


def _parse_lock(lock_path: Path) -> dict[str, str]:
    """Parse the `NAME=hash` lines of adapters.lock. Missing file -> empty map."""
    entries: dict[str, str] = {}
    if not lock_path.is_file():
        return entries
    for raw in lock_path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        name, value = line.split("=", 1)
        entries[name.strip()] = value.strip()
    return entries


def adapter_status(project_root: Path) -> list[AdapterStatus]:
    """Classify each frozen adapter as match / mismatch / unverified / absent."""
    lock = _parse_lock(project_root / ".mindlayer" / "adapters.lock")
    results: list[AdapterStatus] = []
    for name in FROZEN_ADAPTERS:
        path = project_root / name
        if not path.is_file():
            results.append(AdapterStatus(name, "absent"))
            continue
        expected = lock.get(name)
        if expected is None:
            results.append(AdapterStatus(name, "unverified"))
        elif expected == _hash_file(path):
            results.append(AdapterStatus(name, "match"))
        else:
            results.append(AdapterStatus(name, "mismatch"))
    return results
