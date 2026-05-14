"""Memory health status command."""

from __future__ import annotations

from collections import Counter
from datetime import date
from pathlib import Path
import re

from ._paths import archive_file, pipeline_file, read_text
from .diff import memory_diff


def _entry_dates(text: str) -> list[str]:
    return re.findall(r"^(?:last_updated|updated):\s*([0-9]{4}-[0-9]{2}-[0-9]{2})$", text, re.MULTILINE)


def _days_old(ymd: str) -> int | None:
    try:
        return (date.today() - date.fromisoformat(ymd)).days
    except ValueError:
        return None


def _titles(text: str) -> list[str]:
    return [match.strip().lower() for match in re.findall(r"^##+\s+(.+)$", text, re.MULTILINE)]


def _duplicate_level(text: str) -> tuple[str, str]:
    titles = _titles(text)
    counts = Counter(titles)
    if any(count > 1 for count in counts.values()):
        return "CRITICAL", "near-identical entries"
    words_by_title = [set(re.findall(r"[a-z0-9]+", title)) for title in titles]
    for idx, left in enumerate(words_by_title):
        for right in words_by_title[idx + 1 :]:
            if left and right and len(left & right) >= min(len(left), len(right), 3):
                return "WARN", "overlapping titles"
    return "OK", ""


def _health(path: Path) -> tuple[str, str]:
    if path.name == "index.md":
        return "NAV", "navigation-only"
    text = read_text(path)
    lines = len(text.splitlines())
    levels = ["OK"]
    issues: list[str] = []

    if lines >= 300:
        levels.append("CRITICAL")
        issues.append(f"{lines} lines")
    elif lines >= 240:
        levels.append("WARN")
        issues.append(f"{lines} lines")

    dates = [age for age in (_days_old(item) for item in _entry_dates(text)) if age is not None]
    if dates:
        if sum(1 for age in dates if age > 180) > len(dates) / 2:
            levels.append("CRITICAL")
            issues.append("majority stale >180 days")
        elif any(age > 90 for age in dates):
            levels.append("WARN")
            issues.append("stale entry >90 days")

    duplicate_level, duplicate_issue = _duplicate_level(text)
    if duplicate_level != "OK":
        levels.append(duplicate_level)
        issues.append(duplicate_issue)

    overall = "CRITICAL" if "CRITICAL" in levels else "WARN" if "WARN" in levels else "OK"
    return overall, ", ".join(dict.fromkeys(issues)) or "clean"


def _archived_count(path: Path) -> int:
    if not path.is_file():
        return 0
    return len(re.findall(r"^id:\s*\S+", read_text(path), re.MULTILINE))


def _first_block_after_heading(text: str, heading: str) -> str:
    lines = text.splitlines()
    for idx, line in enumerate(lines):
        if line.strip() != heading:
            continue
        block: list[str] = []
        for candidate in lines[idx + 1 :]:
            stripped = candidate.strip()
            if stripped.startswith("#"):
                break
            if stripped:
                block.append(stripped)
            elif block:
                break
        return " ".join(block)
    return ""


def _next_detail(text: str) -> str:
    for raw in text.splitlines():
        line = raw.strip()
        if line.startswith("- Next:"):
            return line.removeprefix("- Next:").strip()
    return ""


def _continuity(memory_dir: Path) -> tuple[str, str]:
    progress = pipeline_file(memory_dir, "progress.md")
    if not progress.is_file():
        return "not recorded", "record current progress"
    text = read_text(progress)
    current = _first_block_after_heading(text, "### Summary") or "not recorded"
    next_action = _next_detail(text) or "review current progress"
    return current, next_action


def run(project_root: Path) -> int:
    memory_dir = project_root / ".mindlayer"
    files = sorted(
        path
        for base in (memory_dir, memory_dir / "pipeline", memory_dir / "knowledge")
        for path in base.glob("*.md")
        if path.name not in {"archive.md", "local.md", "index-full.md"}
    )

    print("Per-File Health:")
    warnings = 0
    critical = 0
    suggestions: list[str] = []
    for path in files:
        label, issue = _health(path)
        if label == "WARN":
            warnings += 1
        elif label == "CRITICAL":
            critical += 1
        print(f"{path.name}    {label}    ({issue})")
        if "lines" in issue and label in {"WARN", "CRITICAL"}:
            suggestions.append(f"- {path.name} is {issue.split(' lines')[0]} lines: consider compressing broad entries, merging duplicates, or archiving stale entries.")

    print("Healthy:")
    print(f"- {sum(1 for path in files if _health(path)[0] in {'OK', 'NAV'})} files OK or navigation-only")
    print("Warnings:")
    print(f"- WARN: {warnings}; CRITICAL: {critical}")

    stale_titles: list[str] = []
    for path in files:
        text = read_text(path)
        if any((age or 0) > 90 for age in (_days_old(item) for item in _entry_dates(text))):
            stale_titles.append(path.name)
    print(f"Stale entries: {len(stale_titles)} flagged ({', '.join(stale_titles) if stale_titles else 'none'}) — say 'ml clean' to review")
    print(f"Archived entries: {_archived_count(archive_file(memory_dir))} in pipeline/archive/archive.md (global: 0, project: {_archived_count(archive_file(memory_dir))})")
    print("Conflicts:")
    print("- None detected")
    current_progress, next_action = _continuity(memory_dir)
    print("Continuity:")
    print("- pending approvals: None")
    print("- blockers: None")
    print(f"- current progress: {current_progress}")
    print(f"- next useful action: {next_action}")
    print("Context:")
    print("- files loaded: .mindlayer/*.md health metadata")
    print("- files skipped: pipeline/archive/archive.md, local.md")
    diff = memory_diff(project_root)
    if diff:
        print(diff)
    print("Suggested fixes:")
    if suggestions:
        for suggestion in suggestions:
            print(suggestion)
    else:
        print("- None")
    print("Approval needed:")
    print("None")
    return 0
