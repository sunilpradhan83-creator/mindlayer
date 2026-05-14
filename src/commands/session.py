"""Session context estimator and session journal writer."""

from __future__ import annotations

from datetime import date as _date
from pathlib import Path
import subprocess

from . import archive
from ._write import approved


def run(project_root: Path, words: int = 0, context_window: int = 200_000) -> int:
    conversation_tokens = int(words * 1.3)
    loaded_words = 0
    for path in [
        project_root / ".mindlayer" / "index.md",
        project_root / ".mindlayer" / "project.md",
        project_root / ".mindlayer" / "progress.md",
        project_root / ".mindlayer" / "backlog.md",
    ]:
        if path.is_file():
            loaded_words += len(path.read_text(encoding="utf-8", errors="replace").split())
    loaded_tokens = int(loaded_words * 1.3)
    total_tokens = conversation_tokens + loaded_tokens
    pct = int((total_tokens / context_window) * 100) if context_window else 0

    if pct > 80:
        status = "Critical"
        recommendation = "new session or compact now"
        reason = "context exceeds 80% of the window"
    elif pct >= 60:
        status = "Heavy"
        recommendation = "compact or new session"
        reason = "context is between 60% and 80% of the window"
    elif pct >= 30:
        status = "Moderate"
        recommendation = "continue"
        reason = "context is below the heavy threshold"
    else:
        status = "Light"
        recommendation = "continue"
        reason = "context is comfortably below 30% of the window"

    print("Session context:")
    print(f"- Conversation: ~{words:,} words, ~{conversation_tokens:,} est. tokens")
    print(f"- MindLayer memory loaded: ~{loaded_words:,} words, ~{loaded_tokens:,} est. tokens")
    print(f"- Total: ~{total_tokens:,} est. tokens (~{pct}% of context window)")
    print(f"Status: {status}")
    print(f"Recommendation: {recommendation}")
    print(f"Reason: {reason}")
    if status in {"Heavy", "Critical"}:
        print("Memory: consider `ml clean` to trim stale entries before the next session")
    return 0


def _bullets(items: list[str] | None) -> str:
    if not items:
        return "- (none)\n"
    return "".join(f"- {item}\n" for item in items)


def write(
    project_root: Path,
    session_date: str = "",
    worked_on: list[str] | None = None,
    decisions: list[str] | None = None,
    completed: list[str] | None = None,
    next_steps: list[str] | None = None,
    approval: str = "",
    approve: bool = False,
) -> int:
    date_str = session_date or str(_date.today())
    sessions_dir = project_root / ".mindlayer" / "sessions"
    session_file = sessions_dir / f"{date_str}.md"

    print("Session Write Candidate:")
    print(f"- Destination: .mindlayer/sessions/{date_str}.md")
    print("- Action: create or append")
    print(f"- Worked on: {', '.join(worked_on or ['(none)'])}")
    print(f"- Next: {', '.join(next_steps or ['(none)'])}")
    print("- Approval needed: yes")

    if not approved(approval, approve):
        print("Session summary ready — say 'save session' or re-run with `--approve` to write.")
        return 0

    sessions_dir.mkdir(parents=True, exist_ok=True)

    block = (
        f"# Session: {date_str}\n\n"
        f"## Commit\n{_git_sha(project_root)}\n\n"
        f"## Worked on\n{_bullets(worked_on)}\n"
        f"## Decisions\n{_bullets(decisions)}\n"
        f"## Completed\n{_bullets(completed)}\n"
        f"## Next\n{_bullets(next_steps)}"
    )

    if session_file.is_file():
        existing = session_file.read_text(encoding="utf-8")
        session_file.write_text(existing.rstrip("\n") + "\n\n---\n\n" + block + "\n", encoding="utf-8")
    else:
        session_file.write_text(block + "\n", encoding="utf-8")

    print(f"Session written: .mindlayer/sessions/{date_str}.md")
    if completed:
        print("Memory check:")
        try:
            archive.clean(project_root)
        except Exception as exc:
            print(f"Memory check skipped: {exc}")
    return 0


def _git_sha(project_root: Path) -> str:
    try:
        result = subprocess.run(
            ["git", "rev-parse", "HEAD"],
            cwd=project_root,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            check=True,
        )
    except (OSError, subprocess.SubprocessError):
        return "unavailable"
    return result.stdout.strip()
