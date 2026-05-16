"""SCRIPT lifecycle command."""

from __future__ import annotations

import re
import subprocess
from datetime import date
from pathlib import Path

from ._paths import pipeline_dir, read_text


# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------

def _today() -> str:
    return date.today().strftime("%Y-%m-%d")


def _git_head_sha() -> str:
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            capture_output=True, text=True, timeout=5,
        )
        sha = result.stdout.strip()
        return sha if sha else "unknown"
    except Exception:
        return "unknown"


def _ensure_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)


def _parse_signal_fields(text: str) -> dict[str, str]:
    fields: dict[str, str] = {}
    frontmatter = re.match(r"^---\n(.*?)\n---", text, re.DOTALL)
    lines = frontmatter.group(1).splitlines() if frontmatter else text.splitlines()
    for line in lines:
        if ":" not in line:
            continue
        key, _, val = line.partition(":")
        fields[key.strip()] = val.strip()
    return fields


def _legacy_signal_blocks(signals_path: Path) -> list[tuple[str, str, dict[str, str], str]]:
    if not signals_path.is_file():
        return []
    text = read_text(signals_path)
    pattern = re.compile(
        r"^##\s+(.+?)\n(.*?)(?=^##\s|\Z)", re.MULTILINE | re.DOTALL
    )
    results = []
    for m in pattern.finditer(text):
        title = m.group(1).strip()
        block = m.group(0)
        fields = _parse_signal_fields(block)
        sig_id = fields.get("id", "")
        if sig_id:
            results.append((sig_id, title, fields, block))
    return results


def _signal_records(pipeline_dir_path: Path) -> list[dict[str, str]]:
    records: list[dict[str, str]] = []
    seen: set[str] = set()

    signals_dir = pipeline_dir_path / "signals"
    if signals_dir.is_dir():
        for path in sorted(signals_dir.glob("ml-signal-*.md")):
            fields = _parse_signal_fields(read_text(path))
            sig_id = fields.get("id", "")
            if not sig_id or sig_id in seen:
                continue
            fields["source"] = str(path)
            records.append(fields)
            seen.add(sig_id)

    for sig_id, title, fields, _block in _legacy_signal_blocks(pipeline_dir_path / "signals.md"):
        if sig_id in seen:
            continue
        fields.setdefault("title", title)
        fields["source"] = str(pipeline_dir_path / "signals.md")
        records.append(fields)
        seen.add(sig_id)

    return records


# ---------------------------------------------------------------------------
# status
# ---------------------------------------------------------------------------

def _signal_status_counts(pipeline_dir_path: Path) -> tuple[int, int]:
    records = _signal_records(pipeline_dir_path)
    pending = sum(1 for record in records if record.get("status") == "pending")
    merged = sum(1 for record in records if record.get("status") == "merged")
    return pending, merged


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
    pipeline_dir_path = pipeline_dir(memory_dir)

    print("SCRIPT Status:")
    if not pipeline_dir_path.is_dir():
        print("- SCRIPT is not initialized yet.")
        print("- Pipeline: missing .mindlayer/pipeline/")
        print("- Next: run a future `ml script signal` or migration command to begin.")
        print("Approval needed:")
        print("None")
        return 0

    pending_signals, merged_signals = _signal_status_counts(pipeline_dir_path)
    ready, in_progress, done = _story_status_counts(pipeline_dir_path / "stories" / "index.md")
    backlog_exists = (pipeline_dir_path / "backlog.md").is_file()
    roadmap_exists = (pipeline_dir_path / "roadmap.md").is_file()

    if pending_signals == 0 and ready == 0 and in_progress == 0 and done == 0 and not backlog_exists:
        print("- No active SCRIPT work.")
    else:
        print("- Active SCRIPT work detected.")

    print(f"- Signals: {pending_signals} pending")
    if merged_signals:
        print(f"- Merged signals: {merged_signals}")
    print(f"- Stories: {ready} ready, {in_progress} in-progress, {done} done")
    print(f"- Backlog: {'present' if backlog_exists else 'missing'}")
    print(f"- Roadmap: {'present' if roadmap_exists else 'missing'}")
    print("Approval needed:")
    print("None")
    return 0


# ---------------------------------------------------------------------------
# signal
# ---------------------------------------------------------------------------

def _next_signal_id(pipeline_dir_path: Path) -> str:
    today = _today().replace("-", "")
    records = _signal_records(pipeline_dir_path)
    existing = [
        record["id"]
        for record in records
        if record.get("id", "").startswith(f"ml-signal-{today}-")
    ]
    if not existing:
        return f"ml-signal-{today}-001"
    nums = [int(e.split("-")[-1]) for e in existing]
    return f"ml-signal-{today}-{max(nums) + 1:03d}"


def _signal_slug(title: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", title.lower()).strip("-")
    return slug[:48].strip("-") or "signal"


def _signal_path(signals_dir: Path, sig_id: str, title: str) -> Path:
    base = f"{sig_id}-{_signal_slug(title)}"
    path = signals_dir / f"{base}.md"
    if not path.exists():
        return path
    suffix = 2
    while True:
        candidate = signals_dir / f"{base}-{suffix}.md"
        if not candidate.exists():
            return candidate
        suffix += 1


def _write_signal_index(signals_dir: Path, records: list[dict[str, str]]) -> None:
    rows = [
        "# Signals Index",
        "",
        "| id | title | status | created | file |",
        "| -- | ----- | ------ | ------- | ---- |",
    ]
    for record in sorted(records, key=lambda item: item.get("id", "")):
        source_path = Path(record.get("source", ""))
        if source_path.parent != signals_dir:
            continue
        source = source_path.name
        rows.append(
            f"| {record.get('id', '')} | {record.get('title', '')} | "
            f"{record.get('status', '')} | {record.get('created', '')} | {source} |"
        )
    tmp_path = signals_dir / ".index.md.tmp"
    tmp_path.write_text("\n".join(rows) + "\n", encoding="utf-8")
    tmp_path.replace(signals_dir / "index.md")


def signal(project_root: Path, title: str, body: str) -> int:
    memory_dir = project_root / ".mindlayer"
    pd = pipeline_dir(memory_dir)
    _ensure_dir(pd)

    signals_dir = pd / "signals"
    _ensure_dir(signals_dir)
    sig_id = _next_signal_id(pd)
    signal_path = _signal_path(signals_dir, sig_id, title)
    created = _today()

    entry = (
        "---\n"
        f"id: {sig_id}\n"
        f"title: {title}\n"
        f"created: {created}\n"
        "status: pending\n"
        "---\n\n"
        f"{body}\n"
    )
    signal_path.write_text(entry, encoding="utf-8")
    _write_signal_index(signals_dir, _signal_records(pd))

    print(f"Signal recorded: {sig_id}")
    print("Status: pending signal processing")
    print("Approval needed: human review required before routing")
    return 0


# ---------------------------------------------------------------------------
# cut
# ---------------------------------------------------------------------------

def _find_signal_block(signals_path: Path, sig_id: str) -> tuple[str, str] | None:
    """Return (title, body) for a pending signal, or None if not found."""
    if not signals_path.is_file():
        return None
    text = read_text(signals_path)
    # Each block starts at "## title" and runs until next "## " or EOF
    pattern = re.compile(
        r"^##\s+(.+?)\n(.*?)(?=^##\s|\Z)", re.MULTILINE | re.DOTALL
    )
    for m in pattern.finditer(text):
        block = m.group(0)
        if f"id: {sig_id}" in block:
            title = m.group(1).strip()
            return title, block
    return None


def _update_signal_status(signals_path: Path, sig_id: str, new_status: str) -> None:
    text = read_text(signals_path)

    def replace_in_block(m: re.Match) -> str:
        block = m.group(0)
        if f"id: {sig_id}" not in block:
            return block
        return re.sub(r"^status: \S+", f"status: {new_status}", block, flags=re.MULTILINE)

    updated = re.sub(
        r"^##\s+.+?\n.*?(?=^##\s|\Z)",
        replace_in_block,
        text,
        flags=re.MULTILINE | re.DOTALL,
    )
    signals_path.write_text(updated, encoding="utf-8")


def cut(
    project_root: Path,
    sig_id: str,
    route: str,
    reason: str = "",
    approve: bool = False,
) -> int:
    memory_dir = project_root / ".mindlayer"
    pd = pipeline_dir(memory_dir)
    signals_path = pd / "signals.md"

    result = _find_signal_block(signals_path, sig_id)
    if result is None:
        print(f"Error: signal '{sig_id}' not found in signals.md", flush=True)
        return 1
    title, _block = result

    target_file = "roadmap.md" if route == "roadmap" else "backlog.md"
    plan = reason.strip()

    if not approve:
        print("Cut proposal:")
        print(f"Signal: {sig_id} ({title})")
        print(f"Route: {route}")
        if plan:
            print(f"Plan: {plan}")
        else:
            print("Plan: <provide --reason with the reviewed Cut plan>")
        print("Review: use Plan Mode review before approving this Cut")
        print("Approval needed: pass --approve to confirm")
        return 0

    if len(plan) < 20:
        print("Error: Cut plan required; provide --reason with the reviewed Cut plan before --approve")
        return 1

    # Approved: update signal status and append to target file
    _update_signal_status(signals_path, sig_id, "cut-approved")

    target_path = pd / target_file
    _ensure_dir(pd)
    line = f"\n- [{sig_id}] {title} — {plan}\n"
    with target_path.open("a", encoding="utf-8") as f:
        f.write(line)

    print(f"Cut approved: {sig_id} routed to {route}")
    print("Approval needed: None")
    return 0


# ---------------------------------------------------------------------------
# refine
# ---------------------------------------------------------------------------

_REQUIRED_FIELDS = ("id", "title", "status", "created", "parent")


def _parse_frontmatter(text: str) -> dict[str, str]:
    """Extract YAML-ish frontmatter fields from --- ... --- block."""
    m = re.match(r"^---\n(.*?)\n---", text, re.DOTALL)
    if not m:
        return {}
    fields: dict[str, str] = {}
    for line in m.group(1).splitlines():
        if ":" in line:
            key, _, val = line.partition(":")
            fields[key.strip()] = val.strip()
    return fields


def _strip_frontmatter(text: str) -> str:
    m = re.match(r"^---\n.*?\n---\n*", text, re.DOTALL)
    if m:
        return text[m.end():]
    return text


def refine_check(story_path: Path) -> int:
    if not story_path.is_file():
        print(f"Error: story file not found: {story_path}")
        return 1
    text = read_text(story_path)
    fields = _parse_frontmatter(text)
    errors = []
    for field in _REQUIRED_FIELDS:
        if field not in fields or not fields[field]:
            errors.append(f"missing field: {field}")
    body = _strip_frontmatter(text).strip()
    if not body:
        errors.append("body is empty — story must contain agent instructions")
    if errors:
        for e in errors:
            print(f"Error: {e}")
        return 1
    print("Story valid")
    return 0


def _next_story_id(stories_dir: Path) -> str:
    pipeline_dir_path = stories_dir.parent
    archive_dir = pipeline_dir_path / "archive"
    existing = []
    if stories_dir.is_dir():
        existing.extend(stories_dir.glob("ml-story-*.md"))
    if archive_dir.is_dir():
        existing.extend(archive_dir.glob("ml-story-*.md"))
    if not existing:
        return "ml-story-001"
    nums = []
    for p in existing:
        m = re.search(r"ml-story-(\d+)", p.name)
        if m:
            nums.append(int(m.group(1)))
    return f"ml-story-{max(nums) + 1:03d}"


def refine(
    project_root: Path,
    backlog_item: str,
    story_title: str,
    approve: bool = False,
    check_path: Path | None = None,
) -> int:
    if check_path is not None:
        return refine_check(check_path)

    memory_dir = project_root / ".mindlayer"
    pd = pipeline_dir(memory_dir)
    stories_dir = pd / "stories"

    story_id = _next_story_id(stories_dir)

    if not approve:
        print(f"Draft story: {story_id}")
        print(f"  title: {story_title}")
        print(f"  parent: {backlog_item}")
        print(f"  status: ready")
        print("Approval needed: pass --approve to confirm story creation")
        return 0

    _ensure_dir(stories_dir)

    story_content = (
        f"---\n"
        f"id: {story_id}\n"
        f"title: {story_title}\n"
        f"status: ready\n"
        f"created: {_today()}\n"
        f"parent: {backlog_item}\n"
        f"agent: any\n"
        f"---\n\n"
        f"You are implementing: {story_title}\n\n"
        f"Start by writing failing tests that verify the acceptance criteria.\n"
        f"Then implement until all tests pass.\n\n"
        f"Acceptance: all tests pass.\n"
    )

    story_path = stories_dir / f"{story_id}.md"
    story_path.write_text(story_content, encoding="utf-8")

    index_path = stories_dir / "index.md"
    index_row = f"| {story_id} | {story_title} | ready | {_today()} | {backlog_item} |\n"
    if not index_path.is_file():
        index_path.write_text(
            "# Stories Index\n\n"
            "| id | title | status | created | parent |\n"
            "| -- | ----- | ------ | ------- | ------ |\n"
            + index_row,
            encoding="utf-8",
        )
    else:
        with index_path.open("a", encoding="utf-8") as f:
            f.write(index_row)

    print(f"Story created: pipeline/stories/{story_id}.md")
    print(f"  title: {story_title}")
    print(f"  parent: {backlog_item}")
    print("Approval needed: None")
    return 0


# ---------------------------------------------------------------------------
# transfer
# ---------------------------------------------------------------------------

_LEARN_TARGETS = {
    "decisions": "decisions.md",
    "project": "project.md",
    "risks": "risks.md",
}


def _stories_for_backlog_item(stories_dir: Path, backlog_item: str) -> list[tuple[Path, str]]:
    """Return list of (story_path, status) for all stories with matching parent."""
    results = []
    if not stories_dir.is_dir():
        return results
    for p in sorted(stories_dir.glob("ml-story-*.md")):
        text = read_text(p)
        fields = _parse_frontmatter(text)
        if fields.get("parent", "").strip() == backlog_item:
            results.append((p, fields.get("status", "unknown")))
    return results


def _remove_index_rows(index_path: Path, story_ids: list[str]) -> None:
    if not index_path.is_file():
        return
    text = read_text(index_path)
    lines = text.splitlines(keepends=True)
    kept = [ln for ln in lines if not any(sid in ln for sid in story_ids)]
    index_path.write_text("".join(kept), encoding="utf-8")


def transfer(
    project_root: Path,
    backlog_item: str,
    approve: bool = False,
    learn: str = "",
    learn_target: str = "decisions",
    approve_learn: bool = False,
) -> int:
    memory_dir = project_root / ".mindlayer"
    pd = pipeline_dir(memory_dir)
    stories_dir = pd / "stories"
    archive_dir = pd / "archive"

    stories = _stories_for_backlog_item(stories_dir, backlog_item)

    not_done = [(p, s) for p, s in stories if s != "done"]
    if not_done and approve:
        for p, s in not_done:
            fields = _parse_frontmatter(read_text(p))
            print(f"Error: story '{fields.get('id', p.name)}' is not done (status: {s})")
        return 1

    story_ids = [_parse_frontmatter(read_text(p)).get("id", p.stem) for p, _ in stories]

    if not approve:
        print(f"Proposed transfer for backlog item: {backlog_item}")
        print(f"  Stories to archive: {len(stories)}")
        for p, s in stories:
            fields = _parse_frontmatter(read_text(p))
            print(f"    {fields.get('id', p.stem)} ({s})")
        if learn:
            print(f"  Learning ({learn_target}): {learn}")
            print("  Pass --approve-learn to confirm the knowledge write.")
        print("Approval needed: pass --approve to confirm")
        return 0

    # Write learning first (before archiving) if both flags present
    if learn and approve_learn:
        target_file = _LEARN_TARGETS.get(learn_target, "decisions.md")
        knowledge_dir = memory_dir / "knowledge"
        _ensure_dir(knowledge_dir)
        target_path = knowledge_dir / target_file
        entry = f"\n## Transfer: {backlog_item}\n\ncreated: {_today()}\nsource: transfer\n\n{learn}\n"
        if not target_path.is_file():
            target_path.write_text(f"# {target_file.replace('.md', '').title()}\n{entry}", encoding="utf-8")
        else:
            with target_path.open("a", encoding="utf-8") as f:
                f.write(entry)
        print(f"Learning written to knowledge/{target_file}")
    elif learn and not approve_learn:
        print(f"Learning ({learn_target}): {learn}")
        print("Approval needed: pass --approve-learn to confirm the knowledge write.")
        return 0

    # Archive stories
    _ensure_dir(archive_dir)
    for p, _ in stories:
        dest = archive_dir / p.name
        p.rename(dest)

    # Remove rows from index
    _remove_index_rows(stories_dir / "index.md", story_ids)

    print(f"Transfer complete: {len(stories)} stories archived for {backlog_item}")
    print("Approval needed: None")
    return 0


# ---------------------------------------------------------------------------
# story --start / --done
# ---------------------------------------------------------------------------

def _find_story_file(stories_dir: Path, story_id: str) -> Path | None:
    candidate = stories_dir / f"{story_id}.md"
    if candidate.is_file():
        return candidate
    # Also try glob for partial matches
    for p in stories_dir.glob("ml-story-*.md"):
        text = read_text(p)
        if f"id: {story_id}" in text:
            return p
    return None


def _update_story_status(
    story_path: Path,
    new_status: str,
    add_sha: bool = False,
    proved_by: str = "",
    proved_at: str = "",
) -> None:
    text = read_text(story_path)
    updated = re.sub(r"^status: \S+", f"status: {new_status}", text, flags=re.MULTILINE)
    if add_sha:
        sha = _git_head_sha()
        if "started_from:" not in updated:
            updated = re.sub(
                r"^(status: in-progress\n)",
                rf"\1started_from: {sha}\n",
                updated,
                flags=re.MULTILINE,
            )
    if proved_by and "proved_by:" not in updated:
        updated = re.sub(
            r"^(status: done\n)",
            rf"\1proved_by: {proved_by}\nproved_at: {proved_at}\n",
            updated,
            flags=re.MULTILINE,
        )
    story_path.write_text(updated, encoding="utf-8")


def _update_index_status(index_path: Path, story_id: str, new_status: str) -> None:
    if not index_path.is_file():
        return
    text = read_text(index_path)
    # Replace status column in the row matching story_id
    # Row format: | id | title | status | created | parent |
    def replace_row(m: re.Match) -> str:
        row = m.group(0)
        if story_id not in row:
            return row
        # Replace the status cell (3rd pipe-delimited column)
        parts = row.split("|")
        if len(parts) >= 4:
            parts[3] = f" {new_status} "
        return "|".join(parts)

    updated = re.sub(r"^\|.*\|.*$", replace_row, text, flags=re.MULTILINE)
    index_path.write_text(updated, encoding="utf-8")


def story_transition(project_root: Path, story_id: str, action: str, test_cmd: str = "") -> int:
    """action: 'start' or 'done'"""
    memory_dir = project_root / ".mindlayer"
    pd = pipeline_dir(memory_dir)
    stories_dir = pd / "stories"

    story_path = _find_story_file(stories_dir, story_id)
    if story_path is None:
        print(f"Error: story '{story_id}' not found in pipeline/stories/", flush=True)
        return 1

    text = read_text(story_path)
    fields = _parse_frontmatter(text)
    current_status = fields.get("status", "unknown")

    if action == "start":
        _update_story_status(story_path, "in-progress", add_sha=True)
        _update_index_status(stories_dir / "index.md", story_id, "in-progress")
        print(f"Story {story_id}: {current_status} → in-progress")
        print("Approval needed: None")
        return 0

    # action == "done"
    proved_by = ""
    proved_at = ""
    if test_cmd:
        result = subprocess.run(test_cmd, shell=True)
        if result.returncode != 0:
            print(f"Tests failed (exit {result.returncode}): {test_cmd}")
            print(f"Story {story_id} remains {current_status}.")
            return 1
        proved_by = test_cmd
        proved_at = _today()
    else:
        print(f"Warning: no --test-cmd provided; marking done without proof.")

    _update_story_status(story_path, "done", proved_by=proved_by, proved_at=proved_at)
    _update_index_status(stories_dir / "index.md", story_id, "done")

    print(f"Story {story_id}: {current_status} → done")
    print("Approval needed: None")
    return 0
