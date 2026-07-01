"""Layout resolution seam: read both the legacy and ADR-0001 target layouts.

ADR-0001 (accepted) moves current work state into `work/current.md`, sessions into
`work/sessions/`, and the archive to a top-level `archive/`. Step 2a makes the runtime
*read* both layouts, preferring existing files, before any files move (Step 2b). This
module is the single source of truth for where a domain lives; commands consult it
instead of hardcoding `pipeline/` or `knowledge/sessions/` paths. It composes the
legacy primitives in `_paths.py` and adds no file moves of its own.
"""

from __future__ import annotations

from pathlib import Path

from . import _paths


def _target_work_dir(memory_dir: Path) -> Path:
    return memory_dir / "work"


def _target_current(memory_dir: Path) -> Path:
    return _target_work_dir(memory_dir) / "current.md"


def _target_sessions(memory_dir: Path) -> Path:
    return _target_work_dir(memory_dir) / "sessions"


def _target_archive(memory_dir: Path) -> Path:
    return memory_dir / "archive" / "archive.md"


def detect_layout(memory_dir: Path) -> str:
    """Return "target" when ADR-0001 markers exist on disk, else "legacy"."""
    if _target_work_dir(memory_dir).is_dir() or _target_current(memory_dir).is_file():
        return "target"
    if (memory_dir / "archive").is_dir():
        return "target"
    return "legacy"


def current_state_files(memory_dir: Path) -> list[Path]:
    """Files holding current work state, resolved for the detected layout.

    Target consolidates progress + backlog into `work/current.md`; legacy keeps them
    split. Prefer the target file only when it exists on disk.
    """
    target = _target_current(memory_dir)
    if target.is_file():
        return [target]
    return [
        _paths.pipeline_file(memory_dir, "progress.md"),
        _paths.pipeline_file(memory_dir, "backlog.md"),
    ]


def progress_file(memory_dir: Path) -> Path:
    """Single file to read for current-progress summaries."""
    target = _target_current(memory_dir)
    if target.is_file():
        return target
    return _paths.pipeline_file(memory_dir, "progress.md")


def session_read_dirs(memory_dir: Path) -> list[Path]:
    """Existing session directories to scan for reads, target-preferred.

    Both layouts are scanned so a partial migration (e.g. an empty target
    `work/sessions/`) never shadows real history in legacy `knowledge/sessions/`.
    """
    dirs: list[Path] = []
    for candidate in (_target_sessions(memory_dir), _paths.sessions_dir(memory_dir)):
        if candidate.is_dir():
            dirs.append(candidate)
    return dirs


def session_files(memory_dir: Path) -> list[Path]:
    """Dated session journals across both layouts, ascending by date.

    Ties on the same date prefer the target layout, so `session_files(...)[-1]`
    is the newest journal, target-preferred.
    """
    target = _target_sessions(memory_dir)
    entries: list[tuple[str, bool, Path]] = []
    for directory in session_read_dirs(memory_dir):
        is_target = directory == target
        for path in directory.glob("????-??-??.md"):
            entries.append((path.name, is_target, path))
    entries.sort(key=lambda entry: (entry[0], entry[1]))
    return [entry[2] for entry in entries]


def session_write_dir(memory_dir: Path) -> Path:
    """Where a NEW session journal is written.

    Step 2a policy (named, not incidental): never fragment session history and
    never relocate it — the explicit migration command owns moving sessions.
    Existing legacy history wins when present; a migrated target dir wins only
    when legacy is absent; the default is legacy (the seed layout).
    """
    legacy = _paths.sessions_dir(memory_dir)
    if legacy.is_dir():
        return legacy
    target = _target_sessions(memory_dir)
    if target.is_dir():
        return target
    return legacy


def archive_file(memory_dir: Path) -> Path:
    """Archive file, preferring top-level `archive/archive.md` when present."""
    target = _target_archive(memory_dir)
    if target.is_file():
        return target
    return _paths.archive_file(memory_dir)


def is_session_path(path: str) -> bool:
    """Layout-agnostic predicate: does this path point into a sessions folder?"""
    return "/knowledge/sessions/" in path or "/work/sessions/" in path


def is_archive_path(path: str) -> bool:
    """Layout-agnostic predicate: does this path point into an archive folder?"""
    return "/archive/" in path
