#!/usr/bin/env bash
# Contract tests for MindLayer boot receipt fixtures.
#
# These tests validate the structural shape of representative boot receipts
# captured under tools/dogfood-fixtures/sessions/.

set -u

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
FIXTURE_DIR="$ROOT_DIR/tools/dogfood-fixtures/sessions"

PASS_COUNT=0
FAIL_COUNT=0
CURRENT_SCENARIO=""

pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf "PASS  %s\n" "$1"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); printf "FAIL  %s\n" "$1"; }
scenario() { CURRENT_SCENARIO="$1"; printf "\n## %s\n" "$CURRENT_SCENARIO"; }

assert_contains() {
  grep -Fq "$2" "$1"
}

assert_not_contains() {
  ! grep -Fq "$2" "$1"
}

assert_section_nonempty() {
  local file="$1"
  local section="$2"
  awk -v section="$section" '
    $0 == section { in_section = 1; next }
    in_section && /^[A-Z][A-Za-z ]*:$/ { exit }
    in_section && NF { found = 1 }
    END { exit found ? 0 : 1 }
  ' "$file"
}

assert_context_cost_nonzero() {
  grep -Eq "Approx\. [1-9][0-9,]* words loaded \(~[1-9][0-9,]* est\. tokens\)\." "$1"
}

check() {
  local label="$1"
  local fn="$2"
  local file="$3"
  local arg="${4:-}"
  if [ -n "$arg" ]; then
    if $fn "$file" "$arg" 2>/dev/null; then
      pass "$CURRENT_SCENARIO: $label"
    else
      fail "$CURRENT_SCENARIO: $label"
    fi
  else
    if $fn "$file" 2>/dev/null; then
      pass "$CURRENT_SCENARIO: $label"
    else
      fail "$CURRENT_SCENARIO: $label"
    fi
  fi
}

printf "MindLayer Boot Receipt Fixture Contracts\n"
printf "========================================\n"

fixtures=$(find "$FIXTURE_DIR" -maxdepth 1 -type f -name 'boot-receipt-*.txt' | sort)
fixture_count=$(printf "%s\n" "$fixtures" | sed '/^$/d' | wc -l | tr -d ' ')

if [ "$fixture_count" -ne 10 ]; then
  printf "FAIL  expected 10 boot receipt fixtures, found %s\n" "$fixture_count"
  exit 1
fi

for fixture in $fixtures; do
  scenario "$(basename "$fixture")"

  check "receipt starts with context loaded" assert_contains "$fixture" "MindLayer context loaded."
  check "Loaded section present" assert_contains "$fixture" "Loaded:"
  check "Loaded section non-empty" assert_section_nonempty "$fixture" "Loaded:"
  check "Skipped section present" assert_contains "$fixture" "Skipped:"
  check "Missing section present" assert_contains "$fixture" "Missing:"
  check "Current understanding present" assert_contains "$fixture" "Current understanding:"
  check "Current understanding non-empty" assert_section_nonempty "$fixture" "Current understanding:"
  check "Current progress present" assert_contains "$fixture" "Current progress:"
  check "Current progress non-empty" assert_section_nonempty "$fixture" "Current progress:"
  check "Context cost present" assert_contains "$fixture" "Context cost:"
  check "Context cost has nonzero estimates" assert_context_cost_nonzero "$fixture"
  check "Token strategy present" assert_contains "$fixture" "Token strategy:"
  check "Ready present" assert_contains "$fixture" "Ready."
  check "Onboarding line has no assumed language" assert_not_contains "$fixture" "assumed"

  case "$(basename "$fixture")" in
    boot-receipt-002.txt|boot-receipt-010.txt)
      check "Onboarding present when completion flag absent" assert_contains "$fixture" "Onboarding:"
      check "Onboarding pending line present" assert_contains "$fixture" "pending — ml onboard will run on first project-relevant request."
      ;;
    *)
      check "Onboarding absent when complete or not needed" assert_not_contains "$fixture" "Onboarding:"
      ;;
  esac

  case "$(basename "$fixture")" in
    boot-receipt-004.txt|boot-receipt-005.txt)
      check "Memory changes block present when changes exist" assert_contains "$fixture" "Memory changes since last session:"
      ;;
    *)
      check "Memory changes block absent when no changes" assert_not_contains "$fixture" "Memory changes since last session:"
      ;;
  esac
done

printf "\nSummary: %s passed, %s failed\n" "$PASS_COUNT" "$FAIL_COUNT"

if [ "$FAIL_COUNT" -ne 0 ]; then
  exit 1
fi

exit 0
