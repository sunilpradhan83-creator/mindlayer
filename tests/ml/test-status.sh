#!/usr/bin/env bash
# CLI contract tests for `ml status`.

set -u

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
SANDBOX="${TMPDIR:-/tmp}/mindlayer-ml-status-test.$$"
PASS_COUNT=0
FAIL_COUNT=0
CURRENT_SCENARIO=""

pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf "PASS  %s\n" "$1"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); printf "FAIL  %s\n" "$1"; }
scenario() { CURRENT_SCENARIO="$1"; printf "\n## %s\n" "$CURRENT_SCENARIO"; }
assert_contains() { grep -Fq -- "$2" "$1"; }

cleanup() { rm -rf "$SANDBOX"; }
trap cleanup EXIT

mkdir -p "$SANDBOX/project/.mindlayer"
cat > "$SANDBOX/project/.mindlayer/index.md" <<'EOF'
# Project Memory Index
EOF
cat > "$SANDBOX/project/.mindlayer/progress.md" <<'EOF'
# Progress

## Current Phase

### Summary
Dogfood polish is active.

### Details
- Next: verify status continuity from progress memory.
EOF
{
  printf "# Context\n\n## Oversized\nid: ml-oversized\nupdated: 2026-05-12\nstatus: active\n\n"
  i=1
  while [ "$i" -le 245 ]; do
    printf "line %s\n" "$i"
    i=$((i + 1))
  done
} > "$SANDBOX/project/.mindlayer/context.md"

printf "MindLayer ml status contract\n"
printf "============================\n"

scenario "health labels"
output="$SANDBOX/status.out"
if (cd "$SANDBOX/project" && python3 "$ROOT_DIR/src/ml" status > "$output"); then
  pass "$CURRENT_SCENARIO: command exits successfully"
else
  fail "$CURRENT_SCENARIO: command exits successfully"
fi
if assert_contains "$output" "Per-File Health:"; then pass "$CURRENT_SCENARIO: health table printed"; else fail "$CURRENT_SCENARIO: health table printed"; fi
if grep -Eq "OK|WARN|CRITICAL" "$output"; then pass "$CURRENT_SCENARIO: labels present"; else fail "$CURRENT_SCENARIO: labels present"; fi
if assert_contains "$output" "context.md    WARN"; then pass "$CURRENT_SCENARIO: oversized file warns"; else fail "$CURRENT_SCENARIO: oversized file warns"; fi
if assert_contains "$output" "- current progress: Dogfood polish is active."; then pass "$CURRENT_SCENARIO: progress continuity read"; else fail "$CURRENT_SCENARIO: progress continuity read"; fi
if assert_contains "$output" "- next useful action: verify status continuity from progress memory."; then pass "$CURRENT_SCENARIO: next action read"; else fail "$CURRENT_SCENARIO: next action read"; fi
if ! assert_contains "$output" "command runner foundation"; then pass "$CURRENT_SCENARIO: no hardcoded continuity"; else fail "$CURRENT_SCENARIO: no hardcoded continuity"; fi

printf "\nSummary: %s passed, %s failed\n" "$PASS_COUNT" "$FAIL_COUNT"
[ "$FAIL_COUNT" -eq 0 ]
