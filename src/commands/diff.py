"""Read-only memory diff command."""

from __future__ import annotations

from pathlib import Path
import re

from ._paths import archive_file, sessions_dir
import subprocess


def _latest_session(memory_dir: Path) -> Path | None:
    sessions = sorted(sessions_dir(memory_dir).glob("????-??-??.md"))
    return sessions[-1] if sessions else None


def _session_sha(path: Path) -> str | None:
    in_commit = False
    for raw in path.read_text(encoding="utf-8", errors="replace").splitlines():
        if raw.startswith("## "):
            in_commit = raw.strip() == "## Commit"
            continue
        if in_commit:
            match = re.search(r"\b[0-9a-fA-F]{7,40}\b", raw)
            if match:
                return match.group(0)
    return None


def memory_diff(project_root: Path) -> str:
    memory_dir = project_root / ".mindlayer"
    latest = _latest_session(memory_dir)
    if latest is None:
        return ""
    sha = _session_sha(latest)
    if not sha:
        return ""

    try:
        subprocess.run(
            ["git", "rev-parse", "--verify", f"{sha}^{{commit}}"],
            cwd=project_root,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=True,
        )
        result = subprocess.run(
            ["git", "diff", f"{sha}..HEAD", "--", ".mindlayer/"],
            cwd=project_root,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            check=False,
        )
    except (OSError, subprocess.SubprocessError):
        return ""

    if result.returncode not in (0, 1):
        return ""
    return summarize_diff(result.stdout)


def summarize_diff(diff_text: str) -> str:
    new_ids: dict[str, set[str]] = {}
    removed_ids: dict[str, set[str]] = {}
    added_status_archived: set[str] = set()
    removed_status_archived: set[str] = set()
    current_file = ""

    for raw in diff_text.splitlines():
        if raw.startswith("+++ b/"):
            current_file = raw[6:]
            continue
        if not current_file or not current_file.startswith(".mindlayer/"):
            continue
        if any(part in current_file for part in ("/knowledge/sessions/", "/cache/", "/tmp/", "/private/")):
            continue
        archive_path = ".mindlayer/" + str(archive_file(Path(".mindlayer"))).split(".mindlayer/", 1)[1]
        if current_file in {".mindlayer/local.md", archive_path}:
            archive_file_flag = current_file == archive_path
        else:
            archive_file_flag = False

        line = raw[1:].strip() if raw[:1] in "+-" else ""
        if raw.startswith("+") and re.match(r"id:\s*\S+", line):
            entry_id = line.split(":", 1)[1].strip()
            new_ids.setdefault(current_file, set()).add(entry_id)
            if archive_file_flag:
                added_status_archived.add(entry_id)
        elif raw.startswith("-") and re.match(r"id:\s*\S+", line):
            entry_id = line.split(":", 1)[1].strip()
            removed_ids.setdefault(current_file, set()).add(entry_id)
        elif raw.startswith("+") and line == "status: archived":
            added_status_archived.add(current_file)
        elif raw.startswith("-") and line == "status: archived":
            removed_status_archived.add(current_file)

    all_new = {entry_id for ids in new_ids.values() for entry_id in ids}
    all_removed = {entry_id for ids in removed_ids.values() for entry_id in ids}
    updated = all_new & all_removed
    archived_count = len((all_removed - all_new) & added_status_archived)
    if added_status_archived and not removed_status_archived:
        archived_count += len(added_status_archived & {".mindlayer/" + f for f in ()})

    new_files = sorted(file for file, ids in new_ids.items() if ids - updated and file != ".mindlayer/pipeline/archive/archive.md")
    updated_files = sorted(file for file, ids in new_ids.items() if ids & updated and file != ".mindlayer/pipeline/archive/archive.md")
    new_count = sum(len(ids - updated) for file, ids in new_ids.items() if file != ".mindlayer/pipeline/archive/archive.md")
    updated_count = sum(len(ids & updated) for file, ids in new_ids.items() if file != ".mindlayer/pipeline/archive/archive.md")

    lines = []
    if new_count or updated_count or archived_count:
        lines.append("Memory changes since last session:")
    if new_count:
        lines.append(f"  New:      {new_count} entries ({', '.join(new_files)})")
    if updated_count:
        lines.append(f"  Updated:  {updated_count} entries ({', '.join(updated_files)})")
    if archived_count:
        lines.append(f"  Archived: {archived_count} entries")
    return "\n".join(lines)


def run(project_root: Path) -> int:
    output = memory_diff(project_root)
    if output:
        print(output)
    return 0

