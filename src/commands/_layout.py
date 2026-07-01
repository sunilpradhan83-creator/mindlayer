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
    """Return "target" only when the ADR-0001 anchor `work/current.md` exists.

    Detection is file-based, not directory-based: an empty `work/` or top-level
    `archive/` directory (a partially-created or seeded skeleton) no longer counts
    as migrated. The single authoritative marker is the consolidated
    `work/current.md`; without it the layout is still "legacy".
    """
    if _target_current(memory_dir).is_file():
        return "target"
    return "legacy"


def resolve_memory_file(memory_dir: Path, file: str, prefer_existing: bool = True) -> Path:
    """Resolve a bare memory filename, preferring the ADR-0001 target layout.

    When the target file exists on disk it wins; otherwise this delegates to the
    legacy `_paths.resolve_memory_file`. Consolidation collapses progress/backlog
    into `work/current.md`, so several legacy names can resolve to the same file.
    """
    candidate = Path(file)
    if candidate.is_absolute() or len(candidate.parts) > 1:
        return _paths.resolve_memory_file(memory_dir, file, prefer_existing)

    name = candidate.name
    current = _target_current(memory_dir)
    backlog = _target_work_dir(memory_dir) / "backlog.md"
    roadmap = memory_dir / "knowledge" / "roadmap.md"

    if name in {"progress.md", "signals.md", "current.md"}:
        if current.is_file():
            return current
    elif name == "backlog.md":
        if backlog.is_file():
            return backlog
        if current.is_file():
            return current
    elif name == "roadmap.md":
        if roadmap.is_file():
            return roadmap
    elif name == "archive.md":
        return archive_file(memory_dir)

    return _paths.resolve_memory_file(memory_dir, file, prefer_existing)


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


def archive_dir(memory_dir: Path) -> Path:
    """Archive directory: top-level `archive/` (target) or `pipeline/archive/` (legacy)."""
    return archive_file(memory_dir).parent


def work_dir(memory_dir: Path) -> Path:
    """SCRIPT working-state base: `work/` in the target layout, else legacy `pipeline/`.

    Signals, stories, and backlog live under this base in both layouts. The archive
    (top-level in the target layout) is resolved separately via `archive_dir`.
    """
    target = _target_work_dir(memory_dir)
    target_anchors = [
        _target_current(memory_dir),
        target / "backlog.md",
        target / "signals",
        target / "stories",
    ]
    if any(path.exists() for path in target_anchors):
        return target

    legacy = _paths.pipeline_dir(memory_dir)
    if target.is_dir() and not legacy.is_dir():
        return target
    return legacy


def is_session_path(path: str) -> bool:
    """Layout-agnostic predicate: does this path point into a sessions folder?"""
    return "/knowledge/sessions/" in path or "/work/sessions/" in path


def is_archive_path(path: str) -> bool:
    """Layout-agnostic predicate: does this path point into an archive folder?"""
    return "/archive/" in path
