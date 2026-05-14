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


PROTECTED_FILES = frozenset({
    "index.md",
    "index-full.md",
    "archive.md",
    "boot.md",
    "router.md",
    "local.md",
})


def is_protected(path: Path) -> bool:
    if path.name in PROTECTED_FILES:
        return True
    parts = path.parts
    return any(part == "memory-system" for part in parts)


def memory_dir_for(root: Path, scope: str = "project") -> Path:
    if scope == "global":
        return Path.home() / ".mindlayer"
    return root / ".mindlayer"



PIPELINE_FILES = frozenset({
    "roadmap.md",
    "backlog.md",
    "progress.md",
})

KNOWLEDGE_FILES = frozenset({
    "project.md",
    "principles.md",
    "goals.md",
    "decisions.md",
    "risks.md",
    "context.md",
})


def pipeline_dir(memory_dir: Path) -> Path:
    return memory_dir / "pipeline"


def knowledge_dir(memory_dir: Path) -> Path:
    return memory_dir / "knowledge"


def pipeline_file(memory_dir: Path, name: str) -> Path:
    return pipeline_dir(memory_dir) / name


def knowledge_file(memory_dir: Path, name: str) -> Path:
    return knowledge_dir(memory_dir) / name


def archive_file(memory_dir: Path) -> Path:
    return pipeline_dir(memory_dir) / "archive" / "archive.md"


def sessions_dir(memory_dir: Path) -> Path:
    return knowledge_dir(memory_dir) / "sessions"


def resolve_memory_file(memory_dir: Path, file: str, prefer_existing: bool = True) -> Path:
    """Resolve a bare memory filename into the V4 layout with legacy fallback."""
    candidate = Path(file)
    if candidate.is_absolute():
        return candidate

    root_path = memory_dir / candidate
    if len(candidate.parts) > 1:
        return root_path

    name = candidate.name
    if name == "archive.md":
        v4_path = archive_file(memory_dir)
    elif name in PIPELINE_FILES:
        v4_path = pipeline_file(memory_dir, name)
    elif name in KNOWLEDGE_FILES:
        v4_path = knowledge_file(memory_dir, name)
    else:
        v4_path = root_path

    if prefer_existing and root_path.is_file() and not v4_path.is_file():
        return root_path
    return v4_path


def existing_memory_file(memory_dir: Path, file: str) -> Path:
    return resolve_memory_file(memory_dir, file, prefer_existing=True)


def display_memory_path(path: Path, memory_dir: Path) -> str:
    try:
        return f".mindlayer/{path.relative_to(memory_dir)}"
    except ValueError:
        return str(path)
