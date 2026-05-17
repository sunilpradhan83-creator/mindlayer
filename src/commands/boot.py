"""Boot receipt command."""

from __future__ import annotations

from pathlib import Path

from ._paths import count_words, global_memory_dir, knowledge_file, pipeline_file, read_text, sessions_dir
from .diff import memory_diff

EMPTY_PROJECT_IDENTITY = "No substantive project identity saved yet."
EMPTY_PROJECT_PROGRESS = "No substantive project progress has been saved yet."
STARTER_SENTINEL_PREFIX = "<!-- ml:starter:"
# Compatibility shims for installs created before starter sentinels existed.
KNOWN_STARTER_STRINGS = frozenset({
    "Short summary.",
    "Short summary of this version or phase.",
    "Useful details.",
    "Current phase and immediate next step.",
    "Starter Preferences",
    "Use MindLayer memory cautiously.",
    "No user preferences saved yet.",
    "Add durable cross-project preferences here only after explicit approval.",
    "Skip this section during boot until real user preferences are saved.",
    "When this project context matters.",
})
# Preference file boilerplate is ignored unless authored content appears in a section.
PERSONAL_BOILERPLATE = frozenset({
    "# Personal Preferences",
    "User-owned cross-project preferences for how AI coding agents should work with you.",
    "This file is git-backed at `~/.mindlayer/preferences/`. Add a remote to back it up:",
    "`git -C ~/.mindlayer/preferences remote add origin <your-private-repo>`",
    "Do not store secrets, raw conversations, or project-specific facts here.",
})


def _read_if_file(path: Path) -> tuple[str, int]:
    if not path.is_file():
        return "", 0
    text = read_text(path)
    return text, count_words(text)


def _is_starter_sentinel(line: str) -> bool:
    stripped = line.strip()
    return stripped.startswith(STARTER_SENTINEL_PREFIX) and stripped.endswith("-->")


def _is_known_starter(line: str) -> bool:
    return line.strip() in KNOWN_STARTER_STRINGS


def _first_summary(path: Path) -> str:
    text, _ = _read_if_file(path)
    lines = text.splitlines()
    for idx, line in enumerate(lines):
        if line.strip() == "### Summary":
            for candidate in lines[idx + 1 :]:
                stripped = candidate.strip()
                if stripped.startswith("### "):
                    break
                if not stripped or _is_starter_sentinel(stripped):
                    continue
                if _is_known_starter(stripped):
                    return EMPTY_PROJECT_IDENTITY
                return stripped
    return EMPTY_PROJECT_IDENTITY


def _is_empty_bullet_label(line: str) -> bool:
    stripped = line.strip()
    return stripped.startswith("- ") and stripped.endswith(":")


def _progress_summary(path: Path) -> str:
    text, _ = _read_if_file(path)
    lines = text.splitlines()
    for idx, line in enumerate(lines):
        if line.strip() == "### Details":
            details = []
            for candidate in lines[idx + 1 :]:
                stripped = candidate.strip()
                if stripped.startswith("### "):
                    break
                if not stripped:
                    continue
                if _is_starter_sentinel(stripped) or _is_known_starter(stripped) or _is_empty_bullet_label(stripped):
                    continue
                details.append(stripped.strip("- ").strip())
            if details:
                return " ".join(details[:2])
    summary = _first_summary(path)
    if summary == EMPTY_PROJECT_IDENTITY:
        return EMPTY_PROJECT_PROGRESS
    return summary


def _personal_is_substantive(text: str) -> bool:
    """Return True only when personal preferences contain authored content."""
    in_content_section = False
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        if stripped.startswith("### "):
            in_content_section = True
            continue
        if stripped.startswith("#"):
            in_content_section = False
            continue
        if _is_starter_sentinel(stripped) or _is_known_starter(stripped):
            continue
        if stripped in PERSONAL_BOILERPLATE:
            continue
        if stripped.startswith("<!--"):
            continue
        if not in_content_section and ":" in stripped and stripped.split(":", 1)[0].replace("_", "-").replace("-", "").isalnum():
            continue
        return True
    return False


def _latest_next(project_root: Path) -> str:
    sessions = sorted(sessions_dir(project_root / ".mindlayer").glob("????-??-??.md"))
    if not sessions:
        return ""
    text = read_text(sessions[-1])
    if "## Next" not in text:
        return ""
    return " ".join(line.strip("- ").strip() for line in text.split("## Next", 1)[1].splitlines() if line.strip())[:220]


def run(project_root: Path) -> int:
    global_dir = global_memory_dir()
    memory_dir = project_root / ".mindlayer"
    loaded: list[str] = []
    skipped: list[str] = []
    missing: list[str] = []
    word_total = 0
    global_words = 0
    project_words = 0

    for label, path, bucket in [
        ("`~/.mindlayer/boot.md`", global_dir / "boot.md", "global"),
        ("`~/.mindlayer/router.md`", global_dir / "router.md", "global"),
        ("`.mindlayer/router.md`", memory_dir / "router.md", "project"),
        ("`~/.mindlayer/memory-system/per-turn.md`", global_dir / "memory-system" / "per-turn.md", "global"),
        ("`.mindlayer/index.md`", memory_dir / "index.md", "project"),
        ("`.mindlayer/knowledge/project.md`", knowledge_file(memory_dir, "project.md"), "project"),
        ("`.mindlayer/pipeline/progress.md`", pipeline_file(memory_dir, "progress.md"), "project"),
        ("`.mindlayer/pipeline/backlog.md`", pipeline_file(memory_dir, "backlog.md"), "project"),
    ]:
        text, words = _read_if_file(path)
        if text:
            loaded.append(label)
            word_total += words
            if bucket == "global":
                global_words += words
            else:
                project_words += words
        else:
            missing.append(label)

    personal_text, personal_words = _read_if_file(global_dir / "preferences" / "personal.md")
    if personal_text and _personal_is_substantive(personal_text):
        loaded.append("`~/.mindlayer/preferences/personal.md`")
        word_total += personal_words
        global_words += personal_words
    else:
        skipped.append("`~/.mindlayer/preferences/personal.md` (missing or starter-only)")

    latest_next = _latest_next(project_root)
    if latest_next:
        loaded.append("latest `.mindlayer/knowledge/sessions/YYYY-MM-DD.md` `## Next`")
        project_words += len(latest_next.split())
        word_total += len(latest_next.split())
    else:
        skipped.append("`.mindlayer/knowledge/sessions/` (no latest Next section)")

    skipped.extend(
        [
            "deeper `.mindlayer/` index branches not needed for boot",
            "`.mindlayer/pipeline/archive/archive.md` and `.mindlayer/local.md`",
            "`README.md`, `docs/`, and adapters as memory sources",
        ]
    )

    understanding = _first_summary(knowledge_file(memory_dir, "project.md"))
    progress = _progress_summary(pipeline_file(memory_dir, "progress.md"))
    if latest_next:
        progress = f"{progress} Latest session cue: {latest_next}"

    diff = memory_diff(project_root)
    tokens = int(word_total * 1.3)
    global_share = round((global_words / word_total) * 100) if word_total else 0
    project_share = round((project_words / word_total) * 100) if word_total else 0

    print("MindLayer context loaded.\n")
    print("Loaded:")
    for item in loaded:
        print(f"- {item}")
    print("\nSkipped:")
    for item in skipped:
        print(f"- {item}")
    print("\nMissing:")
    if missing:
        for item in missing:
            print(f"- {item}")
    else:
        print("- None")
    print("\nCurrent understanding:")
    print(understanding)
    print("\nCurrent progress:")
    print(progress)
    if diff:
        print()
        print(diff)
    print("\nContext cost:")
    print(f"Approx. {word_total:,} words loaded (~{tokens:,} est. tokens).")
    print("\nContext share (approximate context share by source):")
    print(f"- Global memory: ~{global_share}%")
    print(f"- Project memory: ~{project_share}%")
    print("- Other sources: 0% (README.md, docs/, and adapters skipped)")
    print("\nToken strategy:")
    print("L0 boot: boot.md, router.md, per-turn.md, indexes, project identity, and latest progress only.")
    print("\nReady.")
    print("What would you like to work on?")
    return 0
