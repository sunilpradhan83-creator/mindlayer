#!/usr/bin/env bash
# Contract tests for MindLayer memory diff behavioral contracts.
#
# Tests three core contracts:
#   1. Baseline   — diff uses git SHA from latest session file ## Commit section
#   2. Output     — correct format when changes exist; silent when no changes
#   3. Fallback   — skip silently when no session file, no SHA, or git unavailable
#
# Deterministic — no live model required. Tests output shape of simulated
# agent responses against diff.md contract definitions.

set -u

PASS_COUNT=0
FAIL_COUNT=0
CURRENT_SCENARIO=""

pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf "PASS  %s\n" "$1"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); printf "FAIL  %s\n" "$1"; }
scenario() { CURRENT_SCENARIO="$1"; printf "\n## %s\n" "$CURRENT_SCENARIO"; }

TMPDIR_LOCAL="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_LOCAL"' EXIT

# ---------------------------------------------------------------------------
# Output format assertions
# ---------------------------------------------------------------------------

assert_diff_block_present() {
  grep -Eq "^Memory changes since last session:" "$1"
}

assert_diff_block_absent() {
  ! grep -Eq "^Memory changes since last session:" "$1"
}

assert_diff_has_new_line() {
  grep -Eq "^\s+New:\s+[0-9]+ entr" "$1"
}

assert_diff_has_updated_line() {
  grep -Eq "^\s+Updated:\s+[0-9]+ entr" "$1"
}

assert_diff_has_archived_line() {
  grep -Eq "^\s+Archived:\s+[0-9]+ entr" "$1"
}

assert_diff_no_zero_lines() {
  # Lines with count 0 must be omitted
  ! grep -Eq "^\s+(New|Updated|Archived):\s+0 entr" "$1"
}

assert_diff_has_file_names() {
  # When count > 0, must include file name in parentheses
  grep -Eq "^\s+(New|Updated):\s+[1-9][0-9]* entr.+\(.+\.md" "$1"
}

assert_diff_no_entry_titles() {
  # Must not list full entry titles (id: lines or long quoted strings)
  ! grep -Eq "^\s+- id: " "$1"
}

# ---------------------------------------------------------------------------
# Placement assertions
# ---------------------------------------------------------------------------

assert_diff_after_current_progress() {
  file="$1"
  progress_line=$(grep -n "^Current progress:" "$file" | head -1 | cut -d: -f1)
  diff_line=$(grep -n "^Memory changes since last session:" "$file" | head -1 | cut -d: -f1)
  [ -n "$progress_line" ] && [ -n "$diff_line" ] && [ "$diff_line" -gt "$progress_line" ]
}

assert_diff_before_context_cost() {
  file="$1"
  diff_line=$(grep -n "^Memory changes since last session:" "$file" | head -1 | cut -d: -f1)
  cost_line=$(grep -n "^Context cost:" "$file" | head -1 | cut -d: -f1)
  [ -n "$diff_line" ] && [ -n "$cost_line" ] && [ "$diff_line" -lt "$cost_line" ]
}

# ---------------------------------------------------------------------------
# Fallback assertions
# ---------------------------------------------------------------------------

assert_no_diff_error_message() {
  # Must not surface an error when diff is unavailable
  ! grep -Eq "(diff (unavailable|failed|error)|could not compute diff|git (not found|unavailable))" "$1"
}

assert_load_announced() {
  grep -Eq "^Loaded: .*diff\.md — .{3,}" "$1"
}

# ---------------------------------------------------------------------------
# Scenario: changes detected — full block
# ---------------------------------------------------------------------------

scenario "Output format — changes detected"

cat > "$TMPDIR_LOCAL/diff_with_changes.txt" <<'EOF'
MindLayer context loaded.

Loaded: ~/.mindlayer/boot.md — session start
Loaded: ~/.mindlayer/memory-system/commands/diff.md — boot step 11

Current understanding:
MindLayer is a markdown-first memory system.

Current progress:
V3 phase 2 in progress.

Memory changes since last session:
  New:      2 entries (decisions.md, index.md)
  Updated:  1 entry  (progress.md)

Context cost:
Approx. 1200 words loaded (~1560 est. tokens).

Ready.
What would you like to work on?

-------------------------------------------------------------
Token Burned:
  - Last turn: ~300 words, ~390 est. tokens
  - Session: ~300 words, ~390 est. tokens

Next Step: Start memory diff implementation
--------------------------------------------------------------
EOF

assert_diff_block_present "$TMPDIR_LOCAL/diff_with_changes.txt" \
  && pass "diff block present when changes exist" \
  || fail "diff block missing when changes exist"

assert_diff_has_new_line "$TMPDIR_LOCAL/diff_with_changes.txt" \
  && pass "New: line present" \
  || fail "New: line missing"

assert_diff_has_updated_line "$TMPDIR_LOCAL/diff_with_changes.txt" \
  && pass "Updated: line present" \
  || fail "Updated: line missing"

assert_diff_no_zero_lines "$TMPDIR_LOCAL/diff_with_changes.txt" \
  && pass "zero-count lines omitted" \
  || fail "zero-count line found (must be omitted)"

assert_diff_has_file_names "$TMPDIR_LOCAL/diff_with_changes.txt" \
  && pass "file names included in parentheses" \
  || fail "file names missing from diff output"

assert_diff_no_entry_titles "$TMPDIR_LOCAL/diff_with_changes.txt" \
  && pass "entry titles not listed (counts only)" \
  || fail "entry titles incorrectly listed"

assert_load_announced "$TMPDIR_LOCAL/diff_with_changes.txt" \
  && pass "diff.md load announced" \
  || fail "diff.md load not announced"

# ---------------------------------------------------------------------------
# Scenario: changes detected — archived entries
# ---------------------------------------------------------------------------

scenario "Output format — archived entries"

cat > "$TMPDIR_LOCAL/diff_with_archived.txt" <<'EOF'
Current progress:
V3 phase 2 in progress.

Memory changes since last session:
  Archived: 2 entries

Context cost:
Approx. 900 words loaded (~1170 est. tokens).
EOF

assert_diff_has_archived_line "$TMPDIR_LOCAL/diff_with_archived.txt" \
  && pass "Archived: line present" \
  || fail "Archived: line missing"

assert_diff_no_zero_lines "$TMPDIR_LOCAL/diff_with_archived.txt" \
  && pass "no zero-count lines" \
  || fail "zero-count line found"

# ---------------------------------------------------------------------------
# Scenario: no changes — block omitted
# ---------------------------------------------------------------------------

scenario "Output format — no changes detected"

cat > "$TMPDIR_LOCAL/diff_no_changes.txt" <<'EOF'
MindLayer context loaded.

Loaded:
- ~/.mindlayer/memory-system/commands/diff.md — boot step 11

Current understanding:
MindLayer is a markdown-first memory system.

Current progress:
V3 phase 2 in progress.

Context cost:
Approx. 1200 words loaded (~1560 est. tokens).

Ready.
What would you like to work on?
EOF

assert_diff_block_absent "$TMPDIR_LOCAL/diff_no_changes.txt" \
  && pass "diff block absent when no changes" \
  || fail "diff block present when no changes (must be omitted)"

assert_no_diff_error_message "$TMPDIR_LOCAL/diff_no_changes.txt" \
  && pass "no error message when no changes" \
  || fail "error message surfaced (must be silent)"

# ---------------------------------------------------------------------------
# Scenario: no session file — skip silently
# ---------------------------------------------------------------------------

scenario "Fallback — no session file"

cat > "$TMPDIR_LOCAL/diff_no_session.txt" <<'EOF'
MindLayer context loaded.

Loaded:
- ~/.mindlayer/boot.md — session start

Current understanding:
Fresh install, no sessions yet.

Current progress:
No prior sessions.

Context cost:
Approx. 500 words loaded (~650 est. tokens).

Ready.
What would you like to work on?
EOF

assert_diff_block_absent "$TMPDIR_LOCAL/diff_no_session.txt" \
  && pass "diff block absent when no session file" \
  || fail "diff block present when no session file"

assert_no_diff_error_message "$TMPDIR_LOCAL/diff_no_session.txt" \
  && pass "no error message when no session file" \
  || fail "error message surfaced for missing session (must be silent)"

# ---------------------------------------------------------------------------
# Scenario: session file exists but no ## Commit line — skip silently
# ---------------------------------------------------------------------------

scenario "Fallback — session file without Commit SHA"

cat > "$TMPDIR_LOCAL/diff_no_sha.txt" <<'EOF'
Current progress:
V3 phase 2 in progress.

Context cost:
Approx. 900 words loaded (~1170 est. tokens).
EOF

assert_diff_block_absent "$TMPDIR_LOCAL/diff_no_sha.txt" \
  && pass "diff block absent when no SHA in session file" \
  || fail "diff block present when SHA missing"

assert_no_diff_error_message "$TMPDIR_LOCAL/diff_no_sha.txt" \
  && pass "no error message when SHA missing" \
  || fail "error message surfaced for missing SHA (must be silent)"

# ---------------------------------------------------------------------------
# Scenario: git unavailable — skip silently
# ---------------------------------------------------------------------------

scenario "Fallback — git unavailable"

cat > "$TMPDIR_LOCAL/diff_no_git.txt" <<'EOF'
MindLayer context loaded.

Current progress:
V3 phase 2 in progress.

Context cost:
Approx. 900 words loaded (~1170 est. tokens).

Ready.
EOF

assert_diff_block_absent "$TMPDIR_LOCAL/diff_no_git.txt" \
  && pass "diff block absent when git unavailable" \
  || fail "diff block present when git unavailable"

assert_no_diff_error_message "$TMPDIR_LOCAL/diff_no_git.txt" \
  && pass "no error message when git unavailable" \
  || fail "error message surfaced for git unavailable (must be silent)"

# ---------------------------------------------------------------------------
# Scenario: placement in boot receipt
# ---------------------------------------------------------------------------

scenario "Placement — boot receipt"

cat > "$TMPDIR_LOCAL/diff_placement.txt" <<'EOF'
MindLayer context loaded.

Current understanding:
MindLayer is a markdown-first memory system.

Current progress:
V3 phase 2 in progress.

Memory changes since last session:
  New:      1 entry (decisions.md)

Context cost:
Approx. 1200 words loaded (~1560 est. tokens).

Ready.
EOF

assert_diff_after_current_progress "$TMPDIR_LOCAL/diff_placement.txt" \
  && pass "diff block appears after Current progress:" \
  || fail "diff block not after Current progress:"

assert_diff_before_context_cost "$TMPDIR_LOCAL/diff_placement.txt" \
  && pass "diff block appears before Context cost:" \
  || fail "diff block not before Context cost:"

# ---------------------------------------------------------------------------
# Scenario: ml status — diff included in Context section
# ---------------------------------------------------------------------------

scenario "ml status — diff in Context section"

cat > "$TMPDIR_LOCAL/diff_in_status.txt" <<'EOF'
Per-File Health:
  decisions.md    OK    (clean)
  progress.md     OK    (clean)

Healthy: 2 files
Warnings: none
Stale entries: 0 flagged
Archived entries: 0

Context:
  files loaded: 4
  files skipped: 2
  Memory diff: 1 new entry (decisions.md), 0 updated, 0 archived

Suggested fixes: none
Approval needed: None
EOF

grep -Eq "Memory diff:" "$TMPDIR_LOCAL/diff_in_status.txt" \
  && pass "Memory diff line present in ml status Context section" \
  || fail "Memory diff line missing from ml status Context section"

assert_no_diff_error_message "$TMPDIR_LOCAL/diff_in_status.txt" \
  && pass "no error message in status diff output" \
  || fail "error message in status diff output"

# ---------------------------------------------------------------------------
# Scenario: diff fires once per session
# ---------------------------------------------------------------------------

scenario "Once per session — not re-announced mid-session"

cat > "$TMPDIR_LOCAL/diff_mid_session.txt" <<'EOF'
Loaded: ~/.mindlayer/memory-system/commands/save.md — ml save invoked

Memory candidate: some decision → decisions.md — say 'save' or 'skip'

-------------------------------------------------------------
Token Burned:
  - Last turn: ~100 words, ~130 est. tokens
  - Session: ~2000 words, ~2600 est. tokens

Next Step: Approve memory candidate
--------------------------------------------------------------
EOF

assert_diff_block_absent "$TMPDIR_LOCAL/diff_mid_session.txt" \
  && pass "diff block not re-surfaced mid-session" \
  || fail "diff block surfaced mid-session (should fire once at boot only)"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

printf "\n====================\n"
printf "PASS: %d\n" "$PASS_COUNT"
printf "FAIL: %d\n" "$FAIL_COUNT"
printf "====================\n"

[ "$FAIL_COUNT" -eq 0 ]
