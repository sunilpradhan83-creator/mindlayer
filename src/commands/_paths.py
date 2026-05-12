"""Path helpers for the MindLayer CLI."""

from __future__ import annotations

from pathlib import Path


def project_root(start: Path | None = None) -> Path:
    """Return the nearest ancestor containing `.mindlayer/`, or cwd."""
    current = (start or Path.cwd()).resolve()
    for path in (current, *current.parents):
        if (path / ".mindlayer").is_dir():
            return path
    return current


def project_memory_dir(root: Path | None = None) -> Path:
    return (root or project_root()) / ".mindlayer"


def global_memory_dir() -> Path:
    return Path.home() / ".mindlayer"


def rel(path: Path, root: Path | None = None) -> str:
    base = root or project_root()
    try:
        return str(path.relative_to(base))
    except ValueError:
        return str(path)


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def count_words(text: str) -> int:
    return len(text.split())

