"""Ranked memory loader."""

from __future__ import annotations

from pathlib import Path

from ._index import extract_section, load_indexes, rank_entries, summarize_section


def _source_for(project_root: Path, entry_file: str, source_index: Path | None) -> Path:
    relative = Path(entry_file)
    if relative.is_absolute():
        return relative

    if source_index and source_index.parent.name == "preferences":
        return source_index.parent / relative

    repo_source = project_root / relative
    if repo_source.is_file():
        return repo_source

    memory_source = project_root / ".mindlayer" / relative
    if memory_source.is_file():
        return memory_source

    if relative.parts and relative.parts[0] == "memory-system":
        template_source = project_root / "global-template" / relative
        if template_source.is_file():
            return template_source
        return Path.home() / ".mindlayer" / relative

    return memory_source


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
        source = _source_for(project_root, entry.file, entry.source_index)
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
