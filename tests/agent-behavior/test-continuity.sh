#!/usr/bin/env bash
# Deterministic contract tests for MindLayer session continuity handoff shape.

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

assert_valid_handoff() {
  file="$1"
  [ -f "$file" ] || return 1

  grep -Fq "Backlog item:" "$file" || return 1
  grep -Fq "Task:" "$file" || return 1
  grep -Fq "Last result:" "$file" || return 1
  grep -Fq "Next step:" "$file" || return 1
  grep -Fq "Status:" "$file" || return 1
  grep -Fq "Context:" "$file" || return 1
  grep -Fq "Continuity:" "$file" || return 1
  grep -Fq "Pending approvals:" "$file" || return 1
  grep -Fq "Blockers:" "$file" || return 1
  grep -Fq "Unfinished work:" "$file" || return 1
}

assert_invalid_handoff() {
  file="$1"
  if assert_valid_handoff "$file"; then
    return 1
  fi
}

check_valid() {
  file="$1"
  if assert_valid_handoff "$file"; then
    pass "$CURRENT_SCENARIO: valid handoff accepted"
  else
    fail "$CURRENT_SCENARIO: valid handoff accepted"
  fi
}

check_invalid() {
  file="$1"
  label="$2"
  if assert_invalid_handoff "$file"; then
    pass "$CURRENT_SCENARIO: invalid handoff rejected ($label)"
  else
    fail "$CURRENT_SCENARIO: invalid handoff rejected ($label)"
  fi
}

SANDBOX="${TMPDIR:-/tmp}/mindlayer-continuity-test.$$"
cleanup() {
  rm -rf "$SANDBOX"
}
trap cleanup EXIT
mkdir -p "$SANDBOX"

printf "MindLayer Continuity Contract\n"
printf "=============================\n"

scenario "handoff with pending approval"
pending="$SANDBOX/pending.md"
cat > "$pending" <<'EOF'
Backlog item: Session Continuity Tracking
Task: Implement pending memory-write approval reminders
  - Last result: Proposed memory update for `.mindlayer/progress.md`
  - Next step: Wait for explicit approval before writing memory
  - Status: paused

Context:
  - Task: ~40 words, ~55 est. tokens
  - Session: ~1,200 words, ~1,600 est. tokens

Continuity:
  - Pending approvals: memory write / `.mindlayer/progress.md` / update
  - Blockers: explicit approval is required
  - Unfinished work: apply approved memory update
EOF
check_valid "$pending"

scenario "handoff with no pending state"
none="$SANDBOX/none.md"
cat > "$none" <<'EOF'
Backlog item: Automatic Session Initialization
Task: Validate boot receipt contract
  - Last result: `tools/test.sh` passed
  - Next step: Commit changes
  - Status: completed

Context:
  - Task: ~25 words, ~35 est. tokens
  - Session: ~900 words, ~1,200 est. tokens

Continuity:
  - Pending approvals: None
  - Blockers: None
  - Unfinished work: None
EOF
check_valid "$none"

scenario "handoff rejection cases"
missing_continuity="$SANDBOX/missing-continuity.md"
cat > "$missing_continuity" <<'EOF'
Backlog item: Session Continuity Tracking
Task: Implement pending memory-write approval reminders
  - Last result: Proposed memory update
  - Next step: Wait for approval
  - Status: paused

Context:
  - Task: ~40 words, ~55 est. tokens
  - Session: ~1,200 words, ~1,600 est. tokens
EOF
check_invalid "$missing_continuity" "missing continuity section"

missing_pending="$SANDBOX/missing-pending.md"
cat > "$missing_pending" <<'EOF'
Backlog item: Session Continuity Tracking
Task: Implement pending memory-write approval reminders
  - Last result: Proposed memory update
  - Next step: Wait for approval
  - Status: paused

Context:
  - Task: ~40 words, ~55 est. tokens
  - Session: ~1,200 words, ~1,600 est. tokens

Continuity:
  - Blockers: explicit approval is required
  - Unfinished work: apply approved memory update
EOF
check_invalid "$missing_pending" "missing pending approvals"

printf "\nMindLayer Continuity Summary\n"
printf "Passed checks: %s\n" "$PASS_COUNT"
printf "Failed checks: %s\n" "$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  printf "Verdict: CONTINUITY CONTRACT READY\n"
  exit 0
fi

printf "Verdict: CONTINUITY CONTRACT FAILED\n"
exit 1
