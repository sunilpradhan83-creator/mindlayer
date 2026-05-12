"""Ranked memory loader."""

from __future__ import annotations

from pathlib import Path

from ._index import extract_section, load_indexes, rank_entries, summarize_section


def run(project_root: Path, query: str) -> int:
    entries = load_indexes(project_root)
    ranked, skipped = rank_entries(entries, query)
    top = ranked[:5]

    print(f"Query: {query}")
    print(f"Matches: {len(top)}")
    print("Ranking:")
    if top:
        for idx, item in enumerate(top, 1):
            why = "; ".join(item.reasons[:4])
            print(f"  {idx}. {item.entry.title} ({item.entry.id}) — score {item.score} — {why}")
    else:
        print("  None")

    print("Retrieved context:")
    sources: list[str] = []
    for item in top[:3]:
        entry = item.entry
        base = entry.source_index.parent if entry.source_index else project_root / ".mindlayer"
        if base.name == "preferences":
            source = base / entry.file
        else:
            source = project_root / ".mindlayer" / entry.file
        section = extract_section(source, entry.section or entry.title)
        print(f"- {entry.title}: {summarize_section(section)}")
        sources.append(str(source))

    print("Sources:")
    if sources:
        for source in dict.fromkeys(sources):
            print(f"- {source}")
    else:
        print("- None")

    print("Skipped:")
    skipped_archived = [entry for entry in skipped if entry.status == "archived"]
    if skipped_archived:
        print(f"- {len(skipped_archived)} archived entries excluded by default")
    else:
        print("- None")
    return 0
