#!/usr/bin/env bash
# Contract tests for MindLayer ranked load behavior.
#
# Tests:
#   1. ml load is the primary command and ml retrieve is an alias
#   2. ranked matches include score and reason
#   3. title/tag/importance/recency/archive behavior is deterministic
#   4. live/global-template load specs stay synced

set -u

PASS_COUNT=0
FAIL_COUNT=0
CURRENT_SCENARIO=""

pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf "PASS  %s\n" "$1"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); printf "FAIL  %s\n" "$1"; }
scenario() { CURRENT_SCENARIO="$1"; printf "\n## %s\n" "$CURRENT_SCENARIO"; }

TMPDIR_LOCAL="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_LOCAL"' EXIT

assert_load_primary_command() {
  grep -Fq "# ml load" "$1" &&
    grep -Fq "ml load <query>" "$1" &&
    grep -Fq "Alias: \`ml retrieve <query>\`" "$1"
}

assert_no_template_retrieve_spec() {
  [ ! -e "global-template/memory-system/commands/retrieve.md" ]
}

assert_ranked_matches_present() {
  grep -Eq "^1\. .+ \(.+\) — score [0-9]+ — .+" "$1"
}

assert_first_match_title() {
  file="$1"
  title="$2"
  first=$(grep -E "^1\. " "$file" | head -1)
  printf "%s\n" "$first" | grep -Fq "$title"
}

assert_reason_mentions() {
  file="$1"
  reason="$2"
  grep -E "^1\. .+ — score [0-9]+ — .*$reason" "$file" >/dev/null 2>&1
}

assert_archived_absent() {
  ! grep -Fq "Archived Memory" "$1"
}

assert_archived_present_downranked() {
  grep -Fq "Archived Memory" "$1" &&
    grep -Fq "archived requested" "$1" &&
    grep -Fq "archived penalty" "$1"
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
  local file="$3"
  local arg="$4"
  if $fn "$file" "$arg" 2>/dev/null; then
    pass "$CURRENT_SCENARIO: $label"
  else
    fail "$CURRENT_SCENARIO: $label"
  fi
}

printf "MindLayer Ranked Load Contracts\n"
printf "===============================\n"

scenario "command naming — ml load primary, retrieve alias"
check "load.md declares primary command and alias" assert_load_primary_command "global-template/memory-system/commands/load.md"
if assert_no_template_retrieve_spec 2>/dev/null; then
  pass "$CURRENT_SCENARIO: retrieve.md removed from template commands"
else
  fail "$CURRENT_SCENARIO: retrieve.md still exists in template commands"
fi

scenario "ranking — title match outranks summary-only match"
f="$TMPDIR_LOCAL/title_vs_summary.txt"
cat > "$f" <<'EOF'
Query:
router enforcement

Matches:
1. Router Enforcement Gap (ml-20260507-003) — score 85 — exact title phrase, tag match, high importance, recent update
2. V1 Trust and Quality Risks (ml-20260430-006) — score 20 — summary keyword match

Retrieved context:
Loaded Router Enforcement Gap.
EOF

check "ranked matches present" assert_ranked_matches_present "$f"
check2 "title match ranks first" assert_first_match_title "$f" "Router Enforcement Gap"
check2 "reason names title match" assert_reason_mentions "$f" "exact title phrase"

scenario "ranking — tag match and importance influence score"
f="$TMPDIR_LOCAL/tag_importance.txt"
cat > "$f" <<'EOF'
Query:
onboard migration

Matches:
1. ml onboard Three-Phase Migration Flow (ml-20260507-010) — score 75 — partial title keyword, tag match, high importance
2. Starter Project Context (ml-onboard-complete) — score 20 — summary keyword match, low importance
EOF

check "ranked matches present" assert_ranked_matches_present "$f"
check2 "high-importance tagged match ranks first" assert_first_match_title "$f" "ml onboard Three-Phase Migration Flow"
check2 "reason names tag match" assert_reason_mentions "$f" "tag match"

scenario "ranking — recency breaks ties"
f="$TMPDIR_LOCAL/recency_tie.txt"
cat > "$f" <<'EOF'
Query:
memory quality

Matches:
1. Current Phase — V3 Memory Quality + Smarter Retrieval (ml-20260505-006) — score 45 — summary keyword match, high importance, recent update
2. Product Design Philosophy (ml-20260430-004) — score 45 — summary keyword match, high importance
EOF

check "ranked matches present" assert_ranked_matches_present "$f"
check2 "newer tied match ranks first" assert_first_match_title "$f" "Current Phase"
check2 "reason names recent update" assert_reason_mentions "$f" "recent update"

scenario "archive handling — skipped unless explicitly requested"
f="$TMPDIR_LOCAL/archive_skipped.txt"
cat > "$f" <<'EOF'
Query:
installer seed

Matches:
1. V1 Memory Architecture Decisions (ml-20260430-003) — score 40 — summary keyword match, high importance

Skipped:
- Archived entries skipped because query did not request archived/history content.
EOF

check "archived match absent by default" assert_archived_absent "$f"

scenario "archive handling — included with penalty when requested"
f="$TMPDIR_LOCAL/archive_requested.txt"
cat > "$f" <<'EOF'
Query:
archived installer seed

Matches:
1. V1 Memory Architecture Decisions (ml-20260430-003) — score 40 — summary keyword match, high importance
2. Archived Memory — Installer-First V1 Seed (ml-20260430-002) — score 35 — archived requested, exact title phrase, archived penalty
EOF

check "archived match present and downranked when requested" assert_archived_present_downranked "$f"

scenario "spec sync — live and global-template load specs match"
if [ -f "$HOME/.mindlayer/memory-system/commands/load.md" ]; then
  check2 "live load synced with global-template" assert_files_match "$HOME/.mindlayer/memory-system/commands/load.md" "global-template/memory-system/commands/load.md"
fi

printf "\nSummary: %s passed, %s failed\n" "$PASS_COUNT" "$FAIL_COUNT"

if [ "$FAIL_COUNT" -ne 0 ]; then
  exit 1
fi

exit 0
