#!/usr/bin/env bash
# CLI contract tests for `ml session write`.

set -u

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
SANDBOX="${TMPDIR:-/tmp}/mindlayer-ml-session-write-test.$$"
PASS_COUNT=0
FAIL_COUNT=0
CURRENT_SCENARIO=""

pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf "PASS  %s\n" "$1"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); printf "FAIL  %s\n" "$1"; }
scenario() { CURRENT_SCENARIO="$1"; printf "\n## %s\n" "$CURRENT_SCENARIO"; }
assert_contains() { grep -Fq "$2" "$1"; }
assert_file_contains() { grep -Fq "$2" "$1"; }

cleanup() { rm -rf "$SANDBOX"; }
trap cleanup EXIT

printf "MindLayer ml session write contract\n"
printf "====================================\n"

# --- basic write ---
scenario "basic session write"
mkdir -p "$SANDBOX/basic/.mindlayer" "$SANDBOX/basic/.mindlayer/knowledge" "$SANDBOX/basic/.mindlayer/pipeline" "$SANDBOX/basic/.mindlayer/pipeline/archive" "$SANDBOX/basic/.mindlayer/knowledge/sessions"
output="$SANDBOX/basic.out"
if (cd "$SANDBOX/basic" && python3 "$ROOT_DIR/src/ml" session write \
    --date 2026-05-12 \
    --worked-on "Planned Phase 2" \
    --worked-on "Reviewed specs" \
    --decisions "Use repeated flags" \
    --completed "Phase 1 verified" \
    --next "Implement save" > "$output"); then
  pass "$CURRENT_SCENARIO: command exits 0"
else
  fail "$CURRENT_SCENARIO: command exits 0"
fi
SESSION_FILE="$SANDBOX/basic/.mindlayer/knowledge/sessions/2026-05-12.md"
if assert_contains "$output" "Session Write Candidate:"; then pass "$CURRENT_SCENARIO: proposal printed"; else fail "$CURRENT_SCENARIO: proposal printed"; fi
if assert_contains "$output" "Session summary ready"; then pass "$CURRENT_SCENARIO: approval prompt printed"; else fail "$CURRENT_SCENARIO: approval prompt printed"; fi
if [ ! -f "$SESSION_FILE" ]; then pass "$CURRENT_SCENARIO: no write before approval"; else fail "$CURRENT_SCENARIO: no write before approval"; fi
if (cd "$SANDBOX/basic" && python3 "$ROOT_DIR/src/ml" session write \
    --date 2026-05-12 \
    --worked-on "Planned Phase 2" \
    --worked-on "Reviewed specs" \
    --decisions "Use repeated flags" \
    --completed "Phase 1 verified" \
    --next "Implement save" \
    --approve > "$output"); then
  pass "$CURRENT_SCENARIO: approved command exits 0"
else
  fail "$CURRENT_SCENARIO: approved command exits 0"
fi
if assert_contains "$output" "Session written:"; then pass "$CURRENT_SCENARIO: Session written printed"; else fail "$CURRENT_SCENARIO: Session written printed"; fi
if [ -f "$SESSION_FILE" ]; then pass "$CURRENT_SCENARIO: session file created"; else fail "$CURRENT_SCENARIO: session file created"; fi
if assert_file_contains "$SESSION_FILE" "# Session: 2026-05-12"; then pass "$CURRENT_SCENARIO: heading present"; else fail "$CURRENT_SCENARIO: heading present"; fi
if assert_file_contains "$SESSION_FILE" "## Commit"; then pass "$CURRENT_SCENARIO: Commit section"; else fail "$CURRENT_SCENARIO: Commit section"; fi
if assert_file_contains "$SESSION_FILE" "## Worked on"; then pass "$CURRENT_SCENARIO: Worked on section"; else fail "$CURRENT_SCENARIO: Worked on section"; fi
if assert_file_contains "$SESSION_FILE" "## Decisions"; then pass "$CURRENT_SCENARIO: Decisions section"; else fail "$CURRENT_SCENARIO: Decisions section"; fi
if assert_file_contains "$SESSION_FILE" "## Completed"; then pass "$CURRENT_SCENARIO: Completed section"; else fail "$CURRENT_SCENARIO: Completed section"; fi
if assert_file_contains "$SESSION_FILE" "## Next"; then pass "$CURRENT_SCENARIO: Next section"; else fail "$CURRENT_SCENARIO: Next section"; fi
if assert_file_contains "$SESSION_FILE" "Planned Phase 2"; then pass "$CURRENT_SCENARIO: worked-on item 1"; else fail "$CURRENT_SCENARIO: worked-on item 1"; fi
if assert_file_contains "$SESSION_FILE" "Reviewed specs"; then pass "$CURRENT_SCENARIO: worked-on item 2"; else fail "$CURRENT_SCENARIO: worked-on item 2"; fi
if assert_file_contains "$SESSION_FILE" "Use repeated flags"; then pass "$CURRENT_SCENARIO: decisions item"; else fail "$CURRENT_SCENARIO: decisions item"; fi
if assert_file_contains "$SESSION_FILE" "Implement save"; then pass "$CURRENT_SCENARIO: next item"; else fail "$CURRENT_SCENARIO: next item"; fi

# --- same-day continuation appends with separator ---
scenario "same-day continuation"
mkdir -p "$SANDBOX/sameday/.mindlayer/knowledge/sessions"
printf "# Session: 2026-05-12\n\n## Worked on\n- First session.\n\n## Decisions\n- (none)\n\n## Completed\n- (none)\n\n## Next\n- Continue.\n" \
  > "$SANDBOX/sameday/.mindlayer/knowledge/sessions/2026-05-12.md"
output="$SANDBOX/sameday.out"
if (cd "$SANDBOX/sameday" && python3 "$ROOT_DIR/src/ml" session write \
    --date 2026-05-12 \
    --worked-on "Second session" \
    --next "Done" \
    --approve > "$output"); then
  pass "$CURRENT_SCENARIO: command exits 0"
else
  fail "$CURRENT_SCENARIO: command exits 0"
fi
SESSION_FILE="$SANDBOX/sameday/.mindlayer/knowledge/sessions/2026-05-12.md"
if grep -Fq -- "---" "$SESSION_FILE"; then pass "$CURRENT_SCENARIO: separator present"; else fail "$CURRENT_SCENARIO: separator present"; fi
if assert_file_contains "$SESSION_FILE" "First session."; then pass "$CURRENT_SCENARIO: original content preserved"; else fail "$CURRENT_SCENARIO: original content preserved"; fi
if assert_file_contains "$SESSION_FILE" "Second session"; then pass "$CURRENT_SCENARIO: new content appended"; else fail "$CURRENT_SCENARIO: new content appended"; fi

# --- Next section parseable by boot._latest_next ---
scenario "Next section parseable by boot"
mkdir -p "$SANDBOX/bootnext/.mindlayer/knowledge/sessions"
(cd "$SANDBOX/bootnext" && python3 "$ROOT_DIR/src/ml" session write \
    --date 2026-05-01 \
    --worked-on "Something" \
    --next "Boot next step" \
    --approve > /dev/null)
SESSION_FILE="$SANDBOX/bootnext/.mindlayer/knowledge/sessions/2026-05-01.md"
if assert_file_contains "$SESSION_FILE" "## Next"; then pass "$CURRENT_SCENARIO: Next heading present"; else fail "$CURRENT_SCENARIO: Next heading present"; fi
if assert_file_contains "$SESSION_FILE" "Boot next step"; then pass "$CURRENT_SCENARIO: Next content present"; else fail "$CURRENT_SCENARIO: Next content present"; fi

# --- post-completion clean failure does not fail session write ---
scenario "completed session write tolerates clean failure"
mkdir -p "$SANDBOX/cleanfail/.mindlayer" "$SANDBOX/cleanfail/.mindlayer/knowledge" "$SANDBOX/cleanfail/.mindlayer/pipeline" "$SANDBOX/cleanfail/.mindlayer/pipeline/archive" "$SANDBOX/cleanfail/.mindlayer/knowledge/sessions"
printf "# Project Memory Index\n" > "$SANDBOX/cleanfail/.mindlayer/index-full.md"
chmod 000 "$SANDBOX/cleanfail/.mindlayer/index-full.md"
output="$SANDBOX/cleanfail.out"
if (cd "$SANDBOX/cleanfail" && python3 "$ROOT_DIR/src/ml" session write \
    --date 2026-05-12 \
    --completed "Backlog item done" \
    --next "Continue" \
    --approve > "$output"); then
  pass "$CURRENT_SCENARIO: command exits 0"
else
  fail "$CURRENT_SCENARIO: command exits 0"
fi
SESSION_FILE="$SANDBOX/cleanfail/.mindlayer/knowledge/sessions/2026-05-12.md"
if [ -f "$SESSION_FILE" ]; then pass "$CURRENT_SCENARIO: session file created"; else fail "$CURRENT_SCENARIO: session file created"; fi
if assert_contains "$output" "Memory check skipped:"; then pass "$CURRENT_SCENARIO: clean failure reported"; else fail "$CURRENT_SCENARIO: clean failure reported"; fi

printf "\nSummary: %s passed, %s failed\n" "$PASS_COUNT" "$FAIL_COUNT"
[ "$FAIL_COUNT" -eq 0 ]
