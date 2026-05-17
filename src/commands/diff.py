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
            ["git", "diff", "--no-renames", f"{sha}..HEAD", "--", ".mindlayer/"],
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
    archived_ids: set[str] = set()
    status_archived_ids: set[str] = set()
    old_file = ""
    new_file = ""
    current_entry_id = ""
    archive_path = ".mindlayer/" + str(archive_file(Path(".mindlayer"))).split(".mindlayer/", 1)[1]

    def usable(path: str) -> bool:
        if not path or not path.startswith(".mindlayer/"):
            return False
        if any(part in path for part in ("/knowledge/sessions/", "/cache/", "/tmp/", "/private/")):
            return False
        return path != ".mindlayer/local.md"

    def is_archive(path: str) -> bool:
        return path == archive_path or "/archive/" in path

    for raw in diff_text.splitlines():
        if raw.startswith("--- a/"):
            old_file = raw[6:]
            continue
        if raw.startswith("+++ b/"):
            new_file = raw[6:]
            current_entry_id = ""
            continue
        if raw.startswith("+++ /dev/null"):
            new_file = ""
            current_entry_id = ""
            continue

        line = raw[1:].strip() if raw[:1] in "+-" else ""
        context_line = raw[1:].strip() if raw[:1] in "+- " else ""
        if re.match(r"id:\s*\S+", context_line):
            current_entry_id = context_line.split(":", 1)[1].strip()
        if raw.startswith("+") and re.match(r"id:\s*\S+", line):
            if not usable(new_file):
                continue
            entry_id = line.split(":", 1)[1].strip()
            if is_archive(new_file):
                archived_ids.add(entry_id)
            else:
                new_ids.setdefault(new_file, set()).add(entry_id)
        elif raw.startswith("-") and re.match(r"id:\s*\S+", line):
            if not usable(old_file):
                continue
            entry_id = line.split(":", 1)[1].strip()
            if not is_archive(old_file):
                removed_ids.setdefault(old_file, set()).add(entry_id)
        elif raw.startswith("+") and line == "status: archived":
            if usable(new_file) and current_entry_id:
                status_archived_ids.add(current_entry_id)

    all_new = {entry_id for ids in new_ids.values() for entry_id in ids}
    all_removed = {entry_id for ids in removed_ids.values() for entry_id in ids}
    updated = all_new & all_removed
    archived_count = len((archived_ids & all_removed) | status_archived_ids)

    new_files = sorted(file for file, ids in new_ids.items() if ids - updated)
    updated_files = sorted(file for file, ids in new_ids.items() if ids & updated)
    new_count = sum(len(ids - updated) for ids in new_ids.values())
    updated_count = sum(len(ids & updated) for ids in new_ids.values())

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
