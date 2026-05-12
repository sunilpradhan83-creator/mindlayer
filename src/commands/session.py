"""Session context estimator."""

from __future__ import annotations

from pathlib import Path


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
        print("Memory: consider `ml archive` to trim stale entries before the next session")
    return 0
