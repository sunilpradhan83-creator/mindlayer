#!/usr/bin/env bash
# Contract tests for MindLayer auto-summarization suggestion behavior.
#
# Tests:
#   1. Per-turn post-write size suggestions
#   2. ml status detailed cleanup suggestions
#   3. duplicate-warning avoidance
#   4. live/global-template spec sync
#
# Deterministic — no live model required. Tests output shape of simulated
# agent responses against per-turn.md and status.md contract definitions.

set -u

PASS_COUNT=0
FAIL_COUNT=0
CURRENT_SCENARIO=""

pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf "PASS  %s\n" "$1"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); printf "FAIL  %s\n" "$1"; }
scenario() { CURRENT_SCENARIO="$1"; printf "\n## %s\n" "$CURRENT_SCENARIO"; }

TMPDIR_LOCAL="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_LOCAL"' EXIT

assert_size_suggestion_present() {
  grep -Eq "^Memory size suggestion: .+\.md is [0-9]+ lines \((near limit|over limit)\) — consider .+" "$1"
}

assert_size_suggestion_absent() {
  ! grep -Eq "^Memory size suggestion:" "$1"
}

assert_size_suggestion_before_token_burned() {
  file="$1"
  suggestion_line=$(grep -n "^Memory size suggestion:" "$file" | head -1 | cut -d: -f1)
  token_line=$(grep -n "^Token Burned:" "$file" | head -1 | cut -d: -f1)
  [ -n "$suggestion_line" ] && [ -n "$token_line" ] && [ "$suggestion_line" -lt "$token_line" ]
}

assert_single_size_suggestion() {
  count=$(grep -Ec "^Memory size suggestion:" "$1" || true)
  [ "$count" -le 1 ]
}

assert_mentions_cleanup_options() {
  grep -Eq "(compress|merg|archive|split)" "$1"
}

assert_status_suggested_fix_present() {
  grep -Eq "^- .+\.md is [0-9]+ lines \((near limit|over limit)\): consider .+" "$1"
}

assert_status_no_per_turn_duplicate() {
  ! grep -Eq "^Memory size suggestion:" "$1"
}

assert_specs_define_thresholds() {
  file="$1"
  grep -Fq "240+ lines" "$file" && grep -Eq "30[01]\+ lines|300-line file budget" "$file"
}

assert_specs_prefer_cleanup_order() {
  file="$1"
  grep -Fq "compress" "$file" && grep -Fq "merg" "$file" && grep -Fq "archiv" "$file"
}

assert_files_match() {
  cmp -s "$1" "$2"
}

check() {
  local label="$1"
  local fn="$2"
  local file="$3"
  if $fn "$file" 2>/dev/null; then
    pass "$CURRENT_SCENARIO: $label"
  else
    fail "$CURRENT_SCENARIO: $label"
  fi
}

check2() {
  local label="$1"
  local fn="$2"
  local file_a="$3"
  local file_b="$4"
  if $fn "$file_a" "$file_b" 2>/dev/null; then
    pass "$CURRENT_SCENARIO: $label"
  else
    fail "$CURRENT_SCENARIO: $label"
  fi
}

printf "MindLayer Auto-Summarization Suggestion Contracts\n"
printf "=================================================\n"

scenario "per-turn — no suggestion below threshold"
f="$TMPDIR_LOCAL/no_suggestion.txt"
cat > "$f" <<'EOF'
Saved approved memory entry to context.md.

-------------------------------------------------------------
Token Burned:
  - Last turn: ~80 words, ~104 est. tokens
  - Session: ~2,400 words, ~3,120 est. tokens

Next Step: Continue current task.
--------------------------------------------------------------
EOF

check "no suggestion emitted" assert_size_suggestion_absent "$f"

scenario "per-turn — near limit suggestion after memory write"
f="$TMPDIR_LOCAL/near_limit.txt"
cat > "$f" <<'EOF'
Saved approved memory entry to decisions.md.

Memory size suggestion: decisions.md is 240 lines (near limit) — consider compressing long entries, merging overlapping entries, or archiving stale entries.

-------------------------------------------------------------
Token Burned:
  - Last turn: ~110 words, ~143 est. tokens
  - Session: ~2,800 words, ~3,640 est. tokens

Next Step: Review the memory size suggestion.
--------------------------------------------------------------
EOF

check "suggestion present" assert_size_suggestion_present "$f"
check "suggestion before Token Burned" assert_size_suggestion_before_token_burned "$f"
check "single suggestion only" assert_single_size_suggestion "$f"
check "cleanup options mentioned" assert_mentions_cleanup_options "$f"

scenario "per-turn — over limit suggestion after memory write"
f="$TMPDIR_LOCAL/over_limit.txt"
cat > "$f" <<'EOF'
Saved approved memory entry to context.md.

Memory size suggestion: context.md is 318 lines (over limit) — consider compressing long entries, merging overlapping entries, or archiving stale entries.

-------------------------------------------------------------
Token Burned:
  - Last turn: ~120 words, ~156 est. tokens
  - Session: ~3,200 words, ~4,160 est. tokens

Next Step: Decide whether to clean context.md.
--------------------------------------------------------------
EOF

check "over-limit suggestion present" assert_size_suggestion_present "$f"
check "cleanup options mentioned" assert_mentions_cleanup_options "$f"

scenario "ml status — detailed cleanup suggestion"
f="$TMPDIR_LOCAL/status_suggestion.txt"
cat > "$f" <<'EOF'
Per-File Health:
  decisions.md    WARN    (size near limit: 244 lines)

Suggested fixes:
- decisions.md is 244 lines (near limit): consider compressing Memory Diff Design Decisions, merging overlapping onboarding decisions, or archiving completed V1 entries.

Approval needed:
None
EOF

check "status suggested fix present" assert_status_suggested_fix_present "$f"
check "status does not duplicate per-turn size warning" assert_status_no_per_turn_duplicate "$f"
check "cleanup options mentioned" assert_mentions_cleanup_options "$f"

scenario "specs — thresholds and cleanup order documented"
check "global-template per-turn thresholds" assert_specs_define_thresholds "global-template/memory-system/per-turn.md"
check "global-template status thresholds" assert_specs_define_thresholds "global-template/memory-system/commands/status.md"
check "global-template per-turn cleanup options" assert_specs_prefer_cleanup_order "global-template/memory-system/per-turn.md"
check "global-template status cleanup options" assert_specs_prefer_cleanup_order "global-template/memory-system/commands/status.md"

if [ -f "$HOME/.mindlayer/memory-system/per-turn.md" ]; then
  check2 "live per-turn synced with global-template" assert_files_match "$HOME/.mindlayer/memory-system/per-turn.md" "global-template/memory-system/per-turn.md"
fi

if [ -f "$HOME/.mindlayer/memory-system/commands/status.md" ]; then
  check2 "live status synced with global-template" assert_files_match "$HOME/.mindlayer/memory-system/commands/status.md" "global-template/memory-system/commands/status.md"
fi

printf "\nSummary: %s passed, %s failed\n" "$PASS_COUNT" "$FAIL_COUNT"

if [ "$FAIL_COUNT" -ne 0 ]; then
  exit 1
fi

exit 0
