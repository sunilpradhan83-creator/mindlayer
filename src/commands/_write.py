"""Guarded write helpers for MindLayer commands."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date
from pathlib import Path
import re

from ._index import Entry, parse_index
from ._paths import read_text

APPROVALS = {"approve", "approved", "go ahead", "approve all", "save session"}


@dataclass
class SaveRequest:
    title: str
    content: str
    memory_type: str
    destination: str
    scope: str = "project"
    summary: str = ""
    tags: str = ""


def approved(value: str | None, flag: bool = False) -> bool:
    if flag:
        return True
    return (value or "").strip().lower() in APPROVALS


def today() -> str:
    return date.today().isoformat()


def slug(value: str) -> str:
    bits = re.findall(r"[a-z0-9]+", value.lower())
    return "-".join(bits[:6]) or "entry"


def next_id(memory_dir: Path, title: str) -> str:
    prefix = f"ml-{date.today().strftime('%Y%m%d')}-{slug(title)}"
    entries = parse_index(memory_dir / "index-full.md") + parse_index(memory_dir / "index.md")
    existing = {entry.id for entry in entries}
    if prefix not in existing:
        return prefix
    counter = 2
    while f"{prefix}-{counter}" in existing:
        counter += 1
    return f"{prefix}-{counter}"


def duplicate_for(memory_dir: Path, title: str) -> Entry | None:
    title_key = title.strip().lower()
    for entry in parse_index(memory_dir / "index-full.md") + parse_index(memory_dir / "index.md"):
        if entry.title.strip().lower() == title_key:
            return entry
    return None
