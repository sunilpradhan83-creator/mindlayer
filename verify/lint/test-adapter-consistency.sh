#!/usr/bin/env bash
# Guards adapter-template single-source-of-truth and cross-agent standardization:
#   1. Each inline adapter_*_template fallback in install.sh exactly matches its
#      canonical seed template file (edits must land in both; curl|bash installs
#      rely on the inline copy, so it may never drift).
#   2. The five secondary adapters (CLAUDE, GEMINI, Copilot, Cursor, Windsurf) share
#      one identical body once the title line and backticked paths are normalized,
#      i.e. they stay thin pointers to AGENTS.md and never diverge in guidance.

set -u

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"

printf "MindLayer adapter template consistency\n"
printf "======================================\n"

PYTHONPATH="" python3 - "$ROOT_DIR" <<'PY'
import re, sys
from pathlib import Path

root = Path(sys.argv[1])
install = (root / "install.sh").read_text()
tpl_dir = root / "seed/adapters/memory-system/templates"

primary = "AGENTS.md"
secondaries = {
    "adapter_claude_template": "CLAUDE.md",
    "adapter_copilot_template": "copilot-instructions.md",
    "adapter_gemini_template": "GEMINI.md",
    "adapter_cursor_template": "cursor-mindlayer.md",
    "adapter_windsurf_template": "windsurf-mindlayer.md",
}
inline_vars = {"adapter_agents_template": primary, **secondaries}

passc = failc = 0
def pas(m):
    global passc; passc += 1; print(f"PASS  {m}")
def fail(m):
    global failc; failc += 1; print(f"FAIL  {m}")

# 1. Inline fallback == seed file, for every adapter.
for var, fname in inline_vars.items():
    m = re.search(re.escape(var) + r"='(.*?)'\n", install, re.S)
    if not m:
        fail(f"{var}: no inline definition found in install.sh"); continue
    inline = m.group(1)
    fpath = tpl_dir / fname
    if not fpath.exists():
        fail(f"{fname}: seed template file missing"); continue
    if inline == fpath.read_text().rstrip("\n"):
        pas(f"{var} matches seed {fname}")
    else:
        fail(f"{var} DRIFTED from seed {fname} (update both)")

# 2. Secondary adapters share one normalized body.
def normalize(text: str) -> str:
    lines = text.rstrip("\n").splitlines()
    body = lines[1:]  # drop "# <Agent> Adapter" title line
    joined = "\n".join(body)
    return re.sub(r"`[^`]*`", "`X`", joined)  # collapse backticked paths

norm = {f: normalize((tpl_dir / f).read_text()) for f in secondaries.values()}
baseline_name = "CLAUDE.md"
baseline = norm[baseline_name]
for fname, body in norm.items():
    if body == baseline:
        pas(f"{fname} body matches standardized secondary body")
    else:
        fail(f"{fname} body diverges from {baseline_name} standardized body")

print(f"\nSummary: {passc} passed, {failc} failed")
sys.exit(0 if failc == 0 else 1)
PY
