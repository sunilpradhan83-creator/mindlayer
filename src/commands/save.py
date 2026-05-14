"""Guarded memory write command."""

from __future__ import annotations

import re
from pathlib import Path

from ._paths import display_memory_path, is_protected, memory_dir_for, read_text, resolve_memory_file
from ._write import approved


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


def _build_block(section: str, content: str) -> str:
    block = f"## {section}\n\n{content.strip()}\n"
    return block


def _update_index(index_path: Path, entry_line: str) -> None:
    existing = read_text(index_path).splitlines() if index_path.is_file() else []
    parts = [p.strip() for p in entry_line.split("|")]
    entry_id = parts[0] if parts else ""
    updated = False
    result: list[str] = []
    for line in existing:
        if entry_id and line.startswith(f"- {entry_id} |"):
            result.append(f"- {entry_line}")
            updated = True
        else:
            result.append(line)
    if not updated:
        if result and result[-1].strip():
            result.append("")
        result.append(f"- {entry_line}")
    index_path.write_text("\n".join(result) + "\n", encoding="utf-8")


def run(
    project_root: Path,
    file: str,
    section: str,
    content: str,
    action: str = "create",
    index_entry: str = "",
    scope: str = "project",
    approval: str = "",
    approve: bool = False,
) -> int:
    memory_dir = memory_dir_for(project_root, scope)
    target = resolve_memory_file(memory_dir, file).resolve()

    try:
        target.relative_to(memory_dir.resolve())
    except ValueError:
        print(f"Error: {file} is outside the memory directory.")
        return 1

    if is_protected(target):
        print(f"Error: {file} is protected and cannot be written by ml save.")
        return 1

    print("Memory Candidate:")
    print(f"- Title: {section}")
    print(f"- Content: {content}")
    print(f"- Scope: {scope}")
    print("- Type: memory")
    print(f"- Destination: {scope} {display_memory_path(target, memory_dir)}")
    print(f"- Action: {action}")
    print("- Reason: explicit ml save request")
    print("- Duplicate check: section existence checked before write")
    print("- Confidence: medium")
    print("- Approval needed: yes")

    existing_text = read_text(target) if target.is_file() else ""
    lines = existing_text.splitlines()
    block = _build_block(section, content)
    bounds = _find_section_bounds(lines, section)

    if action == "create" and bounds is not None:
        print(f"Error: section '{section}' already exists in {file}. Use --action update.")
        return 1
    if action == "update" and bounds is None:
        print(f"Error: section '{section}' not found in {file}. Use --action create.")
        return 1
    if not approved(approval, approve):
        print("Pending approval. Re-run with `--approve` or `--approval approve` to write.")
        return 0

    target.parent.mkdir(parents=True, exist_ok=True)

    if action == "create":
        new_text = existing_text.rstrip("\n") + ("\n\n" if existing_text.strip() else "") + block
        target.write_text(new_text, encoding="utf-8")
        print(f"Written: {file} — created section '{section}' ({len(block)} bytes)")
    elif action == "update":
        start, end = bounds
        new_lines = lines[:start] + block.splitlines() + ([""] if end < len(lines) else []) + lines[end:]
        target.write_text("\n".join(new_lines) + "\n", encoding="utf-8")
        print(f"Written: {file} — updated section '{section}' ({len(block)} bytes)")
    else:
        print(f"Error: unknown action '{action}'. Use create or update.")
        return 2

    if index_entry:
        index_path = memory_dir / "index.md"
        if index_path.is_file() or action == "create":
            _update_index(index_path, index_entry)
            print(f"Index: updated {index_path.name}")

    return 0
