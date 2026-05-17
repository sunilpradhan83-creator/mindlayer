"""Index parsing and deterministic ranking for MindLayer memory."""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import date
from pathlib import Path
import re

from ._paths import read_text

ARCHIVE_TERMS = {"archived", "archive", "old", "historical", "history", "retired", "completed"}
IMPORTANCE_SCORE = {"high": 2, "medium": 1, "low": 0}


@dataclass
class Entry:
    id: str
    title: str
    file: str
    summary: str = ""
    section: str = ""
    scope: str = ""
    type: str = ""
    status: str = "active"
    last_updated: str = ""
    tags: list[str] = field(default_factory=list)
    importance: str = "medium"
    source_index: Path | None = None
    order: int = 0


@dataclass
class RankedEntry:
    entry: Entry
    score: int
    reasons: list[str]


def words(value: str) -> list[str]:
    return re.findall(r"[a-z0-9]+", value.lower())


def parse_tags(value: str) -> list[str]:
    value = value.strip()
    if value.startswith("[") and value.endswith("]"):
        value = value[1:-1]
    return [part.strip().lower() for part in value.split(",") if part.strip()]


def parse_full_index(path: Path) -> list[Entry]:
    entries: list[Entry] = []
    current: dict[str, str] = {}
    order = 0

    def emit() -> None:
        nonlocal order, current
        if not current:
            return
        entry = Entry(
            id=current.get("id", ""),
            title=current.get("title", ""),
            file=current.get("file", ""),
            summary=current.get("summary", ""),
            section=current.get("section", current.get("title", "")),
            scope=current.get("scope", ""),
            type=current.get("type", ""),
            status=current.get("status", "active"),
            last_updated=current.get("last_updated", current.get("updated", "")),
            tags=parse_tags(current.get("tags", "")),
            importance=current.get("importance", "medium"),
            source_index=path,
            order=order,
        )
        if entry.id and entry.file:
            entries.append(entry)
            order += 1
        current = {}

    for raw in read_text(path).splitlines():
        if raw.startswith("- id:"):
            emit()
            current["id"] = raw.split(":", 1)[1].strip()
            continue
        match = re.match(r"\s+([a-zA-Z_]+):\s*(.*)$", raw)
        if match and current:
            current[match.group(1)] = match.group(2).strip()
    emit()
    return entries


def parse_summary_index(path: Path) -> list[Entry]:
    entries: list[Entry] = []
    for order, raw in enumerate(read_text(path).splitlines()):
        if not raw.startswith("- "):
            continue
        parts = [part.strip() for part in raw[2:].split("|")]
        if len(parts) < 4:
            continue
        entry_id, title, file_name, summary = parts[:4]
        entries.append(
            Entry(
                id=entry_id,
                title=title,
                file=file_name,
                summary=summary,
                section=title,
                source_index=path,
                order=order,
            )
        )
    return entries


def parse_index(path: Path) -> list[Entry]:
    if not path.is_file():
        return []
    text = read_text(path)
    if re.search(r"^\s*-\s+id:", text, re.MULTILINE):
        return parse_full_index(path)
    return parse_summary_index(path)


def _is_pointer(entry: Entry) -> bool:
    return entry.id.startswith("ml-index-ptr-") or (
        entry.file.endswith("/index.md") and "Index" in entry.title
    )


def _load_recursive(
    index_path: Path,
    mindlayer_dir: Path,
    seen: set[str],
    visited: set[Path],
) -> list[Entry]:
    resolved = index_path.resolve()
    if resolved in visited:
        return []
    visited.add(resolved)

    entries: list[Entry] = []
    for entry in parse_index(index_path):
        key = entry.id or f"{entry.file}:{entry.title}"
        if _is_pointer(entry):
            entries.extend(
                _load_recursive(mindlayer_dir / entry.file, mindlayer_dir, seen, visited)
            )
        else:
            if key not in seen:
                seen.add(key)
                entries.append(entry)
    return entries


def load_indexes(project_dir: Path) -> list[Entry]:
    seen: set[str] = set()
    entries: list[Entry] = []

    prefs_index = Path.home() / ".mindlayer" / "preferences" / "index.md"
    for entry in parse_index(prefs_index):
        key = entry.id or f"{entry.file}:{entry.title}"
        if key not in seen:
            seen.add(key)
            entries.append(entry)

    mindlayer_dir = project_dir / ".mindlayer"
    entries.extend(_load_recursive(mindlayer_dir / "index.md", mindlayer_dir, seen, set()))

    return entries


def explicit_archive_query(query: str) -> bool:
    return bool(set(words(query)) & ARCHIVE_TERMS)


def _days_old(ymd: str) -> int | None:
    try:
        then = date.fromisoformat(ymd)
    except ValueError:
        return None
    return (date.today() - then).days


def score_entry(entry: Entry, query: str) -> RankedEntry:
    q = query.lower().strip()
    query_words = words(query)
    title = entry.title.lower()
    summary_words = words(entry.summary)
    score = 0
    matched = False
    reasons: list[str] = []

    if q and q in title:
        score += 50
        matched = True
        reasons.append("exact title phrase")

    title_words = set(words(entry.title))
    title_hits = title_words & set(query_words)
    if title_hits:
        score += 25
        matched = True
        reasons.append("title keywords: " + ", ".join(sorted(title_hits)))

    for tag in entry.tags:
        tag_words = set(words(tag))
        if tag == q or tag_words & set(query_words):
            score += 20
            matched = True
            reasons.append(f"tag: {tag}")

    summary_hits = set(summary_words) & set(query_words)
    for hit in sorted(summary_hits):
        score += 10
        matched = True
        reasons.append(f"summary: {hit}")

    if entry.type.lower() in query_words:
        score += 5
        matched = True
        reasons.append(f"type: {entry.type}")
    if entry.status.lower() in query_words:
        score += 5
        matched = True
        reasons.append(f"status: {entry.status}")

    if matched:
        if entry.importance == "high":
            score += 10
            reasons.append("high importance")
        elif entry.importance == "medium":
            score += 5
            reasons.append("medium importance")

        age = _days_old(entry.last_updated)
        if age is not None:
            if age <= 30:
                score += 5
                reasons.append("updated within 30 days")
            elif age <= 90:
                score += 2
                reasons.append("updated within 90 days")

    if entry.status == "archived":
        score -= 10
        reasons.append("archived penalty")

    return RankedEntry(entry=entry, score=score, reasons=reasons or ["metadata match"])


def rank_entries(entries: list[Entry], query: str) -> tuple[list[RankedEntry], list[Entry]]:
    include_archived = explicit_archive_query(query)
    skipped: list[Entry] = []
    ranked: list[RankedEntry] = []
    for entry in entries:
        if entry.status == "archived" and not include_archived:
            skipped.append(entry)
            continue
        result = score_entry(entry, query)
        if result.score > 0:
            ranked.append(result)

    ranked.sort(
        key=lambda item: (
            -item.score,
            item.entry.last_updated,
            -IMPORTANCE_SCORE.get(item.entry.importance, 0),
            item.entry.order,
        )
    )
    ranked.sort(key=lambda item: item.entry.last_updated, reverse=True)
    ranked.sort(key=lambda item: -item.score)
    return ranked, skipped


def extract_section(path: Path, section: str) -> str:
    if not path.is_file():
        return ""
    lines = read_text(path).splitlines()
    if not section:
        return "\n".join(lines[:40])
    start = None
    heading_re = re.compile(r"^#{1,6}\s+(.+?)\s*$")
    for idx, line in enumerate(lines):
        match = heading_re.match(line)
        if match and match.group(1).strip() == section:
            start = idx
            break
    if start is None:
        return ""
    end = len(lines)
    for idx in range(start + 1, len(lines)):
        if heading_re.match(lines[idx]):
            end = idx
            break
    return "\n".join(lines[start:end])


def summarize_section(text: str) -> str:
    if not text:
        return "Section not found."
    summary_lines: list[str] = []
    capture_next = False
    for line in text.splitlines():
        if line.startswith("### Summary"):
            capture_next = True
            continue
        if capture_next:
            if line.startswith("### "):
                break
            if line.strip():
                summary_lines.append(line.strip())
    if summary_lines:
        return " ".join(summary_lines)
    compact = " ".join(line.strip() for line in text.splitlines() if line.strip())
    return compact[:320] + ("..." if len(compact) > 320 else "")
