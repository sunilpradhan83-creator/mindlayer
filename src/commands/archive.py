"""Guarded memory archive/delete command."""

from __future__ import annotations

from dataclasses import dataclass
import re
from pathlib import Path

from ._paths import archive_file, display_memory_path, is_protected, memory_dir_for, read_text, resolve_memory_file
from ._write import approved

ARCHIVE_PROTECTED = frozenset({
    "archive.md",
    "index.md",
    "index-full.md",
    "boot.md",
    "router.md",
})


@dataclass(frozen=True)
class CleanCandidate:
    title: str
    file: str
    section: str
    reason: str
    action: str
    detail: str
    confidence: str = "medium"
    index_only: bool = False


def _index_entries(index_path: Path) -> list[dict[str, str]]:
    if not index_path.is_file():
        return []
    text = read_text(index_path)
    entries: list[dict[str, str]] = []
    current: dict[str, str] | None = None
    for raw in text.splitlines():
        if raw.startswith("- id: "):
            if current:
                entries.append(current)
            current = {"id": raw.removeprefix("- id: ").strip()}
            continue
        if current is None or not raw.startswith("  ") or ":" not in raw:
            continue
        key, value = raw.strip().split(":", 1)
        current[key] = value.strip()
    if current:
        entries.append(current)
    return entries


def _remove_full_index_entry(index_path: Path, entry_id: str) -> None:
    if not index_path.is_file():
        return
    lines = read_text(index_path).splitlines()
    result: list[str] = []
    idx = 0
    while idx < len(lines):
        line = lines[idx]
        if line == f"- id: {entry_id}":
            idx += 1
            while idx < len(lines) and not lines[idx].startswith("- id: "):
                idx += 1
            while result and not result[-1].strip():
                result.pop()
            if idx < len(lines):
                result.append("")
            continue
        result.append(line)
        idx += 1
    index_path.write_text("\n".join(result).rstrip("\n") + "\n", encoding="utf-8")


def _update_full_index_archived(index_path: Path, entry_id: str) -> None:
    if not index_path.is_file():
        return
    lines = read_text(index_path).splitlines()
    in_entry = False
    for idx, line in enumerate(lines):
        if line.startswith("- id: "):
            in_entry = line == f"- id: {entry_id}"
            continue
        if in_entry and line.startswith("  file: "):
            lines[idx] = "  file: pipeline/archive/archive.md"
        elif in_entry and line.startswith("  status: "):
            lines[idx] = "  status: archived"
    index_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def _find_section_bounds(lines: list[str], section: str) -> tuple[int, int] | None:
    heading_re = re.compile(r"^(#{1,6})\s+(.+?)\s*$")
    start = None
    level = None
    for idx, line in enumerate(lines):
        m = heading_re.match(line)
        if m and m.group(2).strip() == section:
            start = idx
            level = len(m.group(1))
            break
    if start is None:
        return None
    end = len(lines)
    for idx in range(start + 1, len(lines)):
        m = heading_re.match(lines[idx])
        if m and len(m.group(1)) <= level:
            end = idx
            break
    return start, end


def _append_to_archive(archive_path: Path, block_lines: list[str]) -> None:
    if not archive_path.is_file():
        archive_path.write_text("# Archive\n\n", encoding="utf-8")
    existing = read_text(archive_path)
    separator = "\n" if existing.strip() else ""
    content = "\n".join(block_lines).strip()
    archive_path.write_text(existing.rstrip("\n") + "\n\n" + content + "\n", encoding="utf-8")


def _update_index_archived(index_path: Path, section: str, archive_file: str) -> None:
    if not index_path.is_file():
        return
    lines = index_path.read_text(encoding="utf-8").splitlines()
    result: list[str] = []
    for line in lines:
        if f"| {section} |" in line or line.strip().endswith(f"| {section}"):
            parts = [p.strip() for p in line.lstrip("- ").split("|")]
            if len(parts) >= 4:
                line = f"- {parts[0]} | {parts[1]} | {archive_file} | {' | '.join(parts[3:])}"
        result.append(line)
    index_path.write_text("\n".join(result) + "\n", encoding="utf-8")


def _remove_from_index(index_path: Path, section: str) -> None:
    if not index_path.is_file():
        return
    lines = index_path.read_text(encoding="utf-8").splitlines()
    result = [line for line in lines if f"| {section} |" not in line]
    index_path.write_text("\n".join(result) + "\n", encoding="utf-8")


def _remove_section_from_source(target: Path, section: str) -> list[str] | None:
    lines = read_text(target).splitlines()
    bounds = _find_section_bounds(lines, section)
    if bounds is None:
        return None

    start, end = bounds
    block_lines = lines[start:end]
    trailing_blank = end < len(lines) and not lines[end].strip()
    remove_end = end + 1 if trailing_blank else end
    new_lines = lines[:start] + lines[remove_end:]
    while new_lines and not new_lines[-1].strip():
        new_lines.pop()
    target.write_text("\n".join(new_lines) + ("\n" if new_lines else ""), encoding="utf-8")
    return block_lines


def _scan_candidates(memory_dir: Path) -> list[CleanCandidate]:
    index_path = memory_dir / "index-full.md"
    candidates: list[CleanCandidate] = []
    for entry in _index_entries(index_path):
        title = entry.get("title") or entry.get("section") or entry.get("id", "(unknown)")
        file_name = entry.get("file", "")
        section = entry.get("section") or title
        status = entry.get("status", "")
        entry_type = entry.get("type", "")
        entry_id = entry.get("id", "")

        if not file_name or file_name in ARCHIVE_PROTECTED:
            continue

        source = resolve_memory_file(memory_dir, file_name)
        if status == "archived":
            if source.is_file():
                candidates.append(CleanCandidate(
                    title=title,
                    file=file_name,
                    section=section,
                    reason="entry is already status: archived but still lives outside pipeline/archive/archive.md",
                    action="archive",
                    detail="move to pipeline/archive/archive.md and update index-full.md",
                    confidence="high",
                ))
            else:
                candidates.append(CleanCandidate(
                    title=title,
                    file="index-full.md",
                    section=entry_id,
                    reason=f"archived index entry points to missing file {file_name}",
                    action="delete",
                    detail="remove stale index-full.md entry",
                    confidence="medium",
                    index_only=True,
                ))
        elif status in {"completed", "resolved", "mitigated"}:
            action = "archive" if entry_type in {"progress", "risk", "decision", "roadmap", "backlog"} else "keep"
            candidates.append(CleanCandidate(
                title=title,
                file=file_name,
                section=section,
                reason=f"{entry_type or 'entry'} is marked {status}",
                action=action,
                detail="move to pipeline/archive/archive.md" if action == "archive" else "no change",
                confidence="medium",
            ))
    return candidates


def _print_candidate(candidate: CleanCandidate) -> None:
    labels = {
        "archive": "Archive Candidate:",
        "delete": "Delete Candidate:",
        "keep": "Keep Candidate:",
    }
    label = labels.get(candidate.action, "Clean Candidate:")
    print(label)
    print(f"- Title: {candidate.title}")
    print(f"- File: {candidate.file} -> section: {candidate.section}")
    print(f"- Reason: {candidate.reason}")
    print(f"- Proposed action: {candidate.action}")
    print(f"- Action detail: {candidate.detail}")
    print(f"- Confidence: {candidate.confidence}")


def _apply_candidate(memory_dir: Path, candidate: CleanCandidate) -> tuple[str, str]:
    index_full = memory_dir / "index-full.md"
    index_path = memory_dir / "index.md"
    if candidate.index_only:
        _remove_full_index_entry(index_full, candidate.section)
        return "deleted", candidate.title

    target = resolve_memory_file(memory_dir, candidate.file).resolve()
    try:
        target.relative_to(memory_dir.resolve())
    except ValueError:
        return "kept", candidate.title

    block_lines = _remove_section_from_source(target, candidate.section)
    if block_lines is None:
        return "kept", candidate.title

    if candidate.action == "archive":
        _append_to_archive(archive_file(memory_dir), block_lines)
        _update_index_archived(index_path, candidate.section, "pipeline/archive/archive.md")
        for entry in _index_entries(index_full):
            if entry.get("title") == candidate.title or entry.get("section") == candidate.section:
                _update_full_index_archived(index_full, entry.get("id", ""))
                break
        return "archived", candidate.title

    if candidate.action == "delete":
        _remove_from_index(index_path, candidate.section)
        for entry in _index_entries(index_full):
            if entry.get("title") == candidate.title or entry.get("section") == candidate.section:
                _remove_full_index_entry(index_full, entry.get("id", ""))
                break
        return "deleted", candidate.title

    return "kept", candidate.title


def clean(project_root: Path, scope: str = "project", approve_all: bool = False) -> int:
    memory_dir = memory_dir_for(project_root, scope)
    candidates = _scan_candidates(memory_dir)

    if not candidates:
        print("No stale entries found. Memory is clean.")
        return 0

    for candidate in candidates:
        _print_candidate(candidate)

    archive_count = sum(1 for item in candidates if item.action == "archive")
    delete_count = sum(1 for item in candidates if item.action == "delete")
    keep_count = sum(1 for item in candidates if item.action == "keep")
    print(f"Summary: {archive_count} to archive, {delete_count} to delete, {keep_count} to keep")

    if not approve_all:
        print("Say 'approve all', approve by title, or adjust per entry.")
        return 0

    archived: list[str] = []
    deleted: list[str] = []
    kept: list[str] = []
    for candidate in candidates:
        result, title = _apply_candidate(memory_dir, candidate)
        if result == "archived":
            archived.append(title)
        elif result == "deleted":
            deleted.append(title)
        else:
            kept.append(title)

    print("Done.")
    print(f"- Archived: {', '.join(archived) if archived else '(none)'}")
    print(f"- Deleted: {', '.join(deleted) if deleted else '(none)'}")
    print(f"- Kept: {', '.join(kept) if kept else '(none)'}")
    return 0


def run(
    project_root: Path,
    file: str,
    section: str,
    action: str = "archive",
    scope: str = "project",
    approval: str = "",
    approve_all: bool = False,
) -> int:
    memory_dir = memory_dir_for(project_root, scope)
    target = resolve_memory_file(memory_dir, file).resolve()

    try:
        target.relative_to(memory_dir.resolve())
    except ValueError:
        print(f"Error: {file} is outside the memory directory.")
        return 1

    if target.name in ARCHIVE_PROTECTED:
        print(f"Error: {file} is protected and cannot be archived or deleted.")
        return 1

    if is_protected(target) and target.name not in ARCHIVE_PROTECTED:
        print(f"Error: {file} is protected and cannot be modified.")
        return 1

    if not target.is_file():
        print(f"Error: {file} not found.")
        return 1

    lines = read_text(target).splitlines()
    bounds = _find_section_bounds(lines, section)
    if bounds is None:
        print(f"Error: section '{section}' not found in {file}.")
        return 1

    start, end = bounds
    block_lines = lines[start:end]

    print("Archive Candidate:")
    print(f"- Title: {section}")
    print(f"- File: {file} -> section: {section}")
    print(f"- Reason: explicit internal archive request")
    print(f"- Proposed action: {action}")
    detail = "move to pipeline/archive/archive.md" if action == "archive" else "remove entirely"
    print(f"- Action detail: {detail}")
    print("- Confidence: medium")
    print(f"Summary: {1 if action == 'archive' else 0} to archive, {1 if action == 'delete' else 0} to delete, 0 to keep")

    if not approved(approval, approve_all):
        print("Say 'approve all', approve by title, or adjust per entry.")
        return 0

    trailing_blank = end < len(lines) and not lines[end].strip()
    remove_end = end + 1 if trailing_blank else end
    new_lines = lines[:start] + lines[remove_end:]
    while new_lines and not new_lines[-1].strip():
        new_lines.pop()
    target.write_text("\n".join(new_lines) + ("\n" if new_lines else ""), encoding="utf-8")

    index_path = memory_dir / "index.md"

    if action == "archive":
        archive_path = archive_file(memory_dir)
        _append_to_archive(archive_path, block_lines)
        _update_index_archived(index_path, section, "pipeline/archive/archive.md")
        print(f"Archived: '{section}' from {file} → pipeline/archive/archive.md")
    elif action == "delete":
        _remove_from_index(index_path, section)
        print(f"Deleted: '{section}' from {file}")
    else:
        print(f"Error: unknown action '{action}'. Use archive or delete.")
        return 2

    return 0
