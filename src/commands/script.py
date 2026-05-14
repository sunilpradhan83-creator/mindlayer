"""SCRIPT lifecycle command scaffold."""

from __future__ import annotations

from pathlib import Path
import re

from ._paths import read_text


def _count_signal_entries(path: Path) -> int:
    if not path.is_file():
        return 0
    return len(re.findall(r"^id:\s*ml-signal-\S+", read_text(path), re.MULTILINE))


def _story_status_counts(index_path: Path) -> tuple[int, int, int]:
    if not index_path.is_file():
        return 0, 0, 0
    text = read_text(index_path)
    ready = len(re.findall(r"\|\s*ready\s*(?:\||$)", text))
    in_progress = len(re.findall(r"\|\s*in-progress\s*(?:\||$)", text))
    done = len(re.findall(r"\|\s*done\s*(?:\||$)", text))
    return ready, in_progress, done


def status(project_root: Path) -> int:
    memory_dir = project_root / ".mindlayer"
    pipeline_dir = memory_dir / "pipeline"

    print("SCRIPT Status:")
    if not pipeline_dir.is_dir():
        print("- SCRIPT is not initialized yet.")
        print("- Pipeline: missing .mindlayer/pipeline/")
        print("- Next: run a future `ml script signal` or migration command to begin.")
        print("Approval needed:")
        print("None")
        return 0

    signal_count = _count_signal_entries(pipeline_dir / "signals.md")
    ready, in_progress, done = _story_status_counts(pipeline_dir / "stories" / "index.md")
    backlog_exists = (pipeline_dir / "backlog.md").is_file()
    roadmap_exists = (pipeline_dir / "roadmap.md").is_file()

    if signal_count == 0 and ready == 0 and in_progress == 0 and done == 0 and not backlog_exists:
        print("- No active SCRIPT work.")
    else:
        print("- Active SCRIPT work detected.")

    print(f"- Signals: {signal_count}")
    print(f"- Stories: {ready} ready, {in_progress} in-progress, {done} done")
    print(f"- Backlog: {'present' if backlog_exists else 'missing'}")
    print(f"- Roadmap: {'present' if roadmap_exists else 'missing'}")
    print("Approval needed:")
    print("None")
    return 0
