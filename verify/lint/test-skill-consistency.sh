#!/usr/bin/env bash
# Guards cross-agent skill standardization: every agent that ships repo-local skills
# exposes the same canonical trio (architect, implement, review), each SKILL.md's
# frontmatter name matches its directory, and each carries the canonical section
# structure. Agent-specific subagent wiring under "## Agents" is allowed to differ.

set -u

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"

printf "MindLayer cross-agent skill consistency\n"
printf "=======================================\n"

PYTHONPATH="" python3 - "$ROOT_DIR" <<'PY'
import re, sys
from pathlib import Path

root = Path(sys.argv[1])
agent_skill_dirs = {
    "codex": root / ".agents/skills",
    "claude": root / ".claude/skills",
}
CANON = {"architect", "implement", "review"}
SECTIONS = ["## Workflow", "## Agents", "## Output", "## Token Rules"]

passc = failc = 0
def pas(m):
    global passc; passc += 1; print(f"PASS  {m}")
def fail(m):
    global failc; failc += 1; print(f"FAIL  {m}")

for agent, base in agent_skill_dirs.items():
    if not base.is_dir():
        fail(f"{agent}: skills dir {base} missing"); continue
    present = {p.name for p in base.iterdir() if p.is_dir()}
    if present == CANON:
        pas(f"{agent}: exposes canonical trio {sorted(CANON)}")
    else:
        fail(f"{agent}: skill set {sorted(present)} != canonical {sorted(CANON)}")
    for name in sorted(present & CANON):
        skill = base / name / "SKILL.md"
        if not skill.is_file():
            fail(f"{agent}/{name}: SKILL.md missing"); continue
        text = skill.read_text()
        m = re.search(r"^name:\s*(\S+)\s*$", text, re.M)
        if m and m.group(1) == name:
            pas(f"{agent}/{name}: frontmatter name matches directory")
        else:
            fail(f"{agent}/{name}: frontmatter name != '{name}'")
        missing = [s for s in SECTIONS if s not in text]
        if not missing:
            pas(f"{agent}/{name}: has canonical sections")
        else:
            fail(f"{agent}/{name}: missing sections {missing}")

print(f"\nSummary: {passc} passed, {failc} failed")
sys.exit(0 if failc == 0 else 1)
PY
