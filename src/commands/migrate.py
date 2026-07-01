"""Migrate a project's legacy `pipeline/` layout to the ADR-0001 `work/` layout.

ADR-0001 (accepted) consolidates current work state into `work/current.md`, keeps
sessions under `work/sessions/`, moves the roadmap into `knowledge/`, and lifts the
archive to a top-level `archive/`. This command performs that structural move for one
project's `.mindlayer/` directory. It is generic and deterministic: it never hardcodes
specific entry ids, only the structural shape (`## ` headings that carry an `id:` line).

`ml migrate` is a dry-run by default: it prints every planned action as "would ..."
and touches no files. `ml migrate --approve` executes the plan. The command is
idempotent — once `work/current.md` exists it reports "Already migrated" and stops.
"""

from __future__ import annotations

from pathlib import Path
import shutil
import subprocess

from ._paths import read_text
from ._write import approved

CONSOLIDATION_THRESHOLD = 240


def _display(memory_dir: Path, path: Path) -> str:
    try:
        return str(path.relative_to(memory_dir))
    except ValueError:
        return str(path)


def _in_git_worktree(path: Path) -> bool:
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--is-inside-work-tree"],
            cwd=path,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            check=True,
        )
    except (OSError, subprocess.SubprocessError):
        return False
    return result.stdout.strip() == "true"


def _entry_sections(text: str) -> list[str]:
    """Return each `## ` block that carries an `id:` line, verbatim.

    A block runs from a `## ` heading to the next `## ` (or lower) heading. Only
    blocks that contain an `id:` line somewhere below the heading are entries.
    """
    lines = text.splitlines()
    starts: list[int] = [idx for idx, line in enumerate(lines) if line.startswith("## ")]
    blocks: list[str] = []
    for pos, start in enumerate(starts):
        end = starts[pos + 1] if pos + 1 < len(starts) else len(lines)
        block = lines[start:end]
        if any(line.strip().startswith("id:") for line in block):
            blocks.append("\n".join(block).rstrip("\n"))
    return blocks


def _has_entries(path: Path) -> bool:
    if not path.is_file():
        return False
    return bool(_entry_sections(read_text(path)))


class Migration:
    """Collects planned actions; prints them (dry-run) or executes them (--approve)."""

    def __init__(self, memory_dir: Path, execute: bool) -> None:
        self.memory_dir = memory_dir
        self.execute = execute
        self.use_git = execute and _in_git_worktree(memory_dir)

    # -- action primitives ------------------------------------------------
    def _rel(self, path: Path) -> str:
        return _display(self.memory_dir, path)

    def write_file(self, path: Path, content: str) -> None:
        print(f"would write {self._rel(path)}")
        if self.execute:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8")

    def move(self, src: Path, dest: Path) -> None:
        print(f"would move {self._rel(src)} -> {self._rel(dest)}")
        if not self.execute:
            return
        dest.parent.mkdir(parents=True, exist_ok=True)
        if self.use_git and _git_move(self.memory_dir, src, dest):
            return
        shutil.move(str(src), str(dest))

    def remove_path(self, path: Path) -> None:
        print(f"would remove {self._rel(path)}")
        if not self.execute:
            return
        if self.use_git and _git_remove(self.memory_dir, path):
            return
        if path.is_dir():
            shutil.rmtree(path)
        elif path.exists():
            path.unlink()

    def remove_empty_dir(self, path: Path) -> None:
        """Remove `path` only when it is truly empty.

        Every child must already have been explicitly moved or removed. If the
        directory is not empty, do NOT force-delete it — print a warning listing
        the leftovers so an incomplete migration is visible instead of silent.
        """
        print(f"would remove empty dir {self._rel(path)}")
        if not self.execute:
            # Nothing has moved yet in dry-run; the dir is expected to be empty
            # only after the (planned) moves/removals above have executed.
            return
        if not path.is_dir():
            return
        # Prune empty leftover subdirectories first: git does not track directories,
        # so a `git mv` of the last file in e.g. `pipeline/archive/` leaves an empty
        # `archive/` behind on disk. These are safe to remove.
        for child in sorted(path.iterdir()):
            if child.is_dir() and not any(child.iterdir()):
                child.rmdir()
        leftovers = sorted(child.name for child in path.iterdir())
        if leftovers:
            print(
                f"warning: {self._rel(path)} is not empty; leaving it in place "
                f"(unexpected entries: {', '.join(leftovers)})"
            )
            return
        if self.use_git and _git_remove(self.memory_dir, path):
            return
        path.rmdir()


def _git_move(memory_dir: Path, src: Path, dest: Path) -> bool:
    try:
        subprocess.run(
            ["git", "mv", str(src), str(dest)],
            cwd=memory_dir,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=True,
        )
    except (OSError, subprocess.SubprocessError):
        return False
    return True


def _git_remove(memory_dir: Path, path: Path) -> bool:
    try:
        subprocess.run(
            ["git", "rm", "-r", "-q", str(path)],
            cwd=memory_dir,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=True,
        )
    except (OSError, subprocess.SubprocessError):
        return False
    return not path.exists()


def _rewrite_summary_file_field(line: str, backlog_target: str) -> str:
    """Rewrite the `<file>` field of a `- <id> | <Title> | <file> | <summary>` row."""
    if not line.startswith("- ") or "|" not in line:
        return line
    parts = [part.strip() for part in line[2:].split("|")]
    if len(parts) < 4:
        return line
    mapping = {
        "progress.md": "work/current.md",
        "backlog.md": backlog_target,
        "roadmap.md": "knowledge/roadmap.md",
    }
    parts[2] = mapping.get(parts[2], parts[2])
    return "- " + " | ".join(parts)


def _is_roadmap_row(line: str) -> bool:
    return line.startswith("- ") and "| roadmap.md |" in line


def _is_router_row(line: str) -> bool:
    return line.startswith("- ") and "| router.md |" in line


def run(project_root: Path, approve: bool = False) -> int:
    memory_dir = project_root / ".mindlayer"
    pipeline = memory_dir / "pipeline"
    work = memory_dir / "work"
    current = work / "current.md"

    if current.is_file():
        print("Already migrated (work/current.md present).")
        return 0
    if not pipeline.is_dir():
        print("Nothing to migrate.")
        return 0

    execute = approved("", approve)
    plan = Migration(memory_dir, execute)
    if execute:
        print("Migrating legacy pipeline/ layout to ADR-0001 work/ layout.")
    else:
        print("Dry run: planned actions (no files changed). Re-run with --approve to execute.")

    # 1. Size-aware consolidation -------------------------------------------------
    progress = pipeline / "progress.md"
    backlog = pipeline / "backlog.md"
    signals_note = pipeline / "signals.md"

    # Sources consumed by consolidation are removed explicitly (git-aware) after
    # the writes, so the plan announces the deletions and a git worktree stages
    # them via `git rm` rather than leaving unstaged wipes.
    consumed: list[Path] = []

    current_lines = ["# Current Work"]
    if _has_entries(progress):
        current_lines.append("")
        for block in _entry_sections(read_text(progress)):
            current_lines.append(block)
            current_lines.append("")
        consumed.append(progress)
    elif progress.is_file():
        print(f"skipping non-entry file pipeline/{progress.name}")

    if signals_note.is_file() and not _has_entries(signals_note):
        print("skipping non-entry file pipeline/signals.md")
        consumed.append(signals_note)

    backlog_blocks = _entry_sections(read_text(backlog)) if _has_entries(backlog) else []
    backlog_target = "work/current.md"
    backlog_file = work / "backlog.md"

    if backlog_blocks:
        # Count physical lines, not list elements: each block is a multi-line string.
        current_line_count = sum(block.count("\n") + 1 for block in current_lines)
        backlog_line_count = sum(block.count("\n") + 2 for block in backlog_blocks)
        projected = current_line_count + backlog_line_count
        if projected < CONSOLIDATION_THRESHOLD:
            for block in backlog_blocks:
                current_lines.append(block)
                current_lines.append("")
        else:
            backlog_lines = ["# Backlog", ""]
            for block in backlog_blocks:
                backlog_lines.append(block)
                backlog_lines.append("")
            plan.write_file(backlog_file, "\n".join(backlog_lines).rstrip("\n") + "\n")
            backlog_target = "work/backlog.md"
        consumed.append(backlog)
    elif backlog.is_file():
        print(f"skipping non-entry file pipeline/{backlog.name}")

    plan.write_file(current, "\n".join(current_lines).rstrip("\n") + "\n")

    # Remove every consumed source now that its content lives in work/.
    for source in consumed:
        plan.remove_path(source)

    # 2. Moves --------------------------------------------------------------------
    roadmap = pipeline / "roadmap.md"
    if roadmap.is_file():
        plan.move(roadmap, memory_dir / "knowledge" / "roadmap.md")

    signals_dir = pipeline / "signals"
    if signals_dir.is_dir():
        plan.move(signals_dir, work / "signals")

    pipeline_archive = pipeline / "archive"
    top_archive = memory_dir / "archive"
    archive_index_provided = False
    if pipeline_archive.is_dir():
        for child in sorted(pipeline_archive.iterdir()):
            if child.name == "index.md":
                archive_index_provided = True
            plan.move(child, top_archive / child.name)

    legacy_sessions = memory_dir / "knowledge" / "sessions"
    if legacy_sessions.is_dir():
        plan.move(legacy_sessions, work / "sessions")

    # 3. Lazy-drop stories --------------------------------------------------------
    stories = pipeline / "stories"
    if stories.is_dir():
        story_index = stories / "index.md"
        children = sorted(stories.iterdir())
        only_index = children == [story_index] and story_index.is_file()
        has_rows = story_index.is_file() and any(
            line.startswith("| ml-") for line in read_text(story_index).splitlines()
        )
        if only_index and not has_rows:
            plan.remove_path(stories)
        else:
            plan.move(stories, work / "stories")

    # 4. Index rewrites -----------------------------------------------------------
    pipeline_index = pipeline / "index.md"
    root_index = memory_dir / "index.md"
    knowledge_index = memory_dir / "knowledge" / "index.md"

    router_rows: list[str] = []
    roadmap_rows: list[str] = []
    work_index_lines: list[str] = []
    if pipeline_index.is_file():
        for line in read_text(pipeline_index).splitlines():
            rewritten = _rewrite_summary_file_field(line, backlog_target)
            if _is_router_row(line):
                router_rows.append(rewritten)
                continue
            if _is_roadmap_row(line):
                roadmap_rows.append(rewritten)
                # roadmap rows migrate to knowledge/index.md, not work/index.md
                continue
            work_index_lines.append(rewritten)
        plan.write_file(work / "index.md", "\n".join(work_index_lines).rstrip("\n") + "\n")
        plan.remove_path(pipeline_index)

    # Root index.md is pointer-only (each row must be `ml-index-ptr-* | … | */index.md`).
    # Only repoint the pipeline/index.md pointer to work/index.md; never add entry rows
    # here — the router/roadmap rows are relocated to knowledge/index.md below.
    if root_index.is_file():
        root_lines = read_text(root_index).splitlines()
        new_root: list[str] = []
        for line in root_lines:
            if line.startswith("- ") and "| pipeline/index.md |" in line:
                line = line.replace("| pipeline/index.md |", "| work/index.md |")
            new_root.append(line)
        plan.write_file(root_index, "\n".join(new_root).rstrip("\n") + "\n")

    # knowledge/index.md gains the repointed roadmap and router rows (project-config
    # entries have no home in the pointer-only root or the work/ subfolder index).
    relocated_rows = roadmap_rows + router_rows
    if relocated_rows:
        if knowledge_index.is_file():
            know_lines = read_text(knowledge_index).splitlines()
        else:
            know_lines = ["# Knowledge Index"]
        for row in relocated_rows:
            know_lines.append(row)
        plan.write_file(knowledge_index, "\n".join(know_lines).rstrip("\n") + "\n")

    # Top-level archive/index.md must exist. If the pipeline archive move already
    # provided one, it is preserved; otherwise create a minimal header.
    archive_index = top_archive / "index.md"
    if not archive_index_provided and not archive_index.is_file():
        plan.write_file(archive_index, "# Archive Index\n")

    # 5. Remove the now-empty pipeline/ directory --------------------------------
    if pipeline.is_dir():
        plan.remove_empty_dir(pipeline)

    if not execute:
        print("End of plan. No changes made.")
    else:
        print("Migration complete.")
    return 0
