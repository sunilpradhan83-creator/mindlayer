#!/usr/bin/env bash
# Deterministic contract tests for MindLayer first-interaction behavior.
#
# This does not call a live model. It validates the response shape that adapters
# require agents to produce after automatic first-interaction initialization.

set -u

PASS_COUNT=0
FAIL_COUNT=0
CURRENT_SCENARIO=""

pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  printf "PASS  %s\n" "$1"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  printf "FAIL  %s\n" "$1"
}

scenario() {
  CURRENT_SCENARIO="$1"
  printf "\n## %s\n" "$CURRENT_SCENARIO"
}

assert_valid_receipt() {
  file="$1"
  [ -f "$file" ] || return 1

  grep -Fq "MindLayer context loaded." "$file" || return 1
  grep -Fq "Loaded:" "$file" || return 1
  grep -Fq "Skipped:" "$file" || return 1
  grep -Fq "Missing:" "$file" || return 1
  grep -Fq "Current understanding:" "$file" || return 1
  grep -Fq "Current progress:" "$file" || return 1
  grep -Fq "Context cost:" "$file" || return 1
  grep -Fq "Ready." "$file" || return 1

  grep -Fq 'README.md`, `docs/`, and tool adapters as memory sources' "$file" || return 1
  grep -Eq 'Approx\. [0-9][0-9,]*-[0-9][0-9,]* words loaded|Approx\. [0-9][0-9,]* words loaded' "$file" || return 1

  if awk '
    /^Loaded:/ { in_loaded = 1; next }
    /^[[:alpha:]][[:alpha:] ]*:/ { in_loaded = 0 }
    in_loaded && /(README\.md|docs\/|AGENTS\.md|CLAUDE\.md|copilot-instructions\.md)/ { bad = 1 }
    END { exit bad ? 0 : 1 }
  ' "$file"; then
    return 1
  fi
}

assert_invalid_receipt() {
  file="$1"
  if assert_valid_receipt "$file"; then
    return 1
  fi
}

check_valid() {
  file="$1"
  if assert_valid_receipt "$file"; then
    pass "$CURRENT_SCENARIO: valid receipt accepted"
  else
    fail "$CURRENT_SCENARIO: valid receipt accepted"
  fi
}

check_invalid() {
  file="$1"
  label="$2"
  if assert_invalid_receipt "$file"; then
    pass "$CURRENT_SCENARIO: invalid receipt rejected ($label)"
  else
    fail "$CURRENT_SCENARIO: invalid receipt rejected ($label)"
  fi
}

SANDBOX="${TMPDIR:-/tmp}/mindlayer-agent-behavior-test.$$"
cleanup() {
  rm -rf "$SANDBOX"
}
trap cleanup EXIT
mkdir -p "$SANDBOX"

printf "MindLayer Agent Behavior Contract\n"
printf "=================================\n"

scenario "substantive project receipt"
substantive="$SANDBOX/substantive-receipt.md"
cat > "$substantive" <<'EOF'
MindLayer context loaded.

Loaded:
- Global: `~/.mindlayer/memory-system.md`, `~/.mindlayer/preferences.md`, `~/.mindlayer/index.md`
- Project: `.mindlayer/index.md`, `.mindlayer/project.md`, latest `.mindlayer/progress.md`

Skipped:
- `README.md`, `docs/`, and tool adapters as memory sources
- Empty scaffold files and `.mindlayer/local.md`
- Full memory files not needed for startup

Missing:
- None

Current understanding:
MindLayer is a markdown-first memory system for AI-native software developers. Durable memory lives in global and project `.mindlayer/` files; adapters stay thin.

Current progress:
Installer-first V1 is published. Recent work clarified deploy readiness, source boundaries, literal approval for writes, and transparent initialization receipts.

Context cost:
Approx. 900-1,400 words loaded from memory. Kept to command rules, preferences, indexes, project identity, and latest progress.

Ready.
What would you like to work on?
EOF
check_valid "$substantive"

scenario "starter project receipt"
starter="$SANDBOX/starter-receipt.md"
cat > "$starter" <<'EOF'
MindLayer context loaded.

Loaded:
- Global command rules and preferences
- Project memory index

Skipped:
- Starter-only project memory files
- `.mindlayer/local.md`
- `README.md`, `docs/`, and tool adapters as memory sources

Missing:
- Substantive project identity is not saved yet

Current understanding:
This project has MindLayer installed, but no durable project memory has been added yet.

Current progress:
No substantive project progress has been saved yet.

Context cost:
Approx. 300-600 words loaded.

Ready.
What would you like to work on?
EOF
check_valid "$starter"

scenario "receipt rejection cases"
missing_cost="$SANDBOX/missing-cost.md"
cat > "$missing_cost" <<'EOF'
MindLayer context loaded.

Loaded:
- Global command rules and preferences

Skipped:
- `README.md`, `docs/`, and tool adapters as memory sources

Missing:
- None

Current understanding:
Project memory is available.

Current progress:
No progress loaded.

Ready.
EOF
check_invalid "$missing_cost" "missing context cost"

loaded_docs="$SANDBOX/loaded-docs.md"
cat > "$loaded_docs" <<'EOF'
MindLayer context loaded.

Loaded:
- Global command rules and preferences
- README.md and docs/

Skipped:
- `README.md`, `docs/`, and tool adapters as memory sources

Missing:
- None

Current understanding:
Project memory is available.

Current progress:
No progress loaded.

Context cost:
Approx. 400-500 words loaded.

Ready.
EOF
check_invalid "$loaded_docs" "human docs loaded"

missing_skip="$SANDBOX/missing-skip.md"
cat > "$missing_skip" <<'EOF'
MindLayer context loaded.

Loaded:
- Global command rules and preferences

Missing:
- None

Current understanding:
Project memory is available.

Current progress:
No progress loaded.

Context cost:
Approx. 400-500 words loaded.

Ready.
EOF
check_invalid "$missing_skip" "missing skipped section"

screenshot_regression="$SANDBOX/screenshot-regression.md"
cat > "$screenshot_regression" <<'EOF'
Hi! MindLayer context initialized.

Loaded: global index, command rules, global preferences, project index, project identity, current progress.
Skipped: README/docs and other memory files not needed yet.
Missing/starter-only: project identity and progress are placeholders, so I don't have a real project summary yet.
Current understanding: use MindLayer cautiously, keep memory low-token, and never write memory without approval.
Approx cost: ~1k tokens.
EOF
check_invalid "$screenshot_regression" "screenshot-style loose receipt"

printf "\nMindLayer Agent Behavior Summary\n"
printf "Passed checks: %s\n" "$PASS_COUNT"
printf "Failed checks: %s\n" "$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  printf "Verdict: FIRST-INTERACTION CONTRACT READY\n"
  exit 0
fi

printf "Verdict: FIRST-INTERACTION CONTRACT FAILED\n"
exit 1
