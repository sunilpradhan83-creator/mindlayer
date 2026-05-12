"""Guarded memory archive/delete command."""

from __future__ import annotations

import re
from pathlib import Path

from ._paths import is_protected, memory_dir_for, read_text
from ._write import approved

ARCHIVE_PROTECTED = frozenset({
    "archive.md",
    "index.md",
    "index-full.md",
    "boot.md",
    "router.md",
})


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
    target = (memory_dir / file).resolve()

    try:
        target.relative_to(memory_dir.resolve())
    except ValueError:
        print(f"Error: {file} is outside the memory directory.")
        return 1

    if target.name in ARCHIVE_PROTECTED:
        print(f"Error: {file} is protected and cannot be archived or deleted by ml archive.")
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
    print(f"- Reason: explicit ml archive request")
    print(f"- Proposed action: {action}")
    detail = "move to archive.md" if action == "archive" else "remove entirely"
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
        archive_path = memory_dir / "archive.md"
        _append_to_archive(archive_path, block_lines)
        _update_index_archived(index_path, section, "archive.md")
        print(f"Archived: '{section}' from {file} → archive.md")
    elif action == "delete":
        _remove_from_index(index_path, section)
        print(f"Deleted: '{section}' from {file}")
    else:
        print(f"Error: unknown action '{action}'. Use archive or delete.")
        return 2

    return 0
