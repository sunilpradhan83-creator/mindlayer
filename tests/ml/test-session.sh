#!/usr/bin/env bash
# CLI contract tests for `ml session`.

set -u

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
SANDBOX="${TMPDIR:-/tmp}/mindlayer-ml-session-test.$$"
PASS_COUNT=0
FAIL_COUNT=0
CURRENT_SCENARIO=""

pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf "PASS  %s\n" "$1"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); printf "FAIL  %s\n" "$1"; }
scenario() { CURRENT_SCENARIO="$1"; printf "\n## %s\n" "$CURRENT_SCENARIO"; }

cleanup() { rm -rf "$SANDBOX"; }
trap cleanup EXIT

mkdir -p "$SANDBOX/project/.mindlayer"
printf "# Index\n" > "$SANDBOX/project/.mindlayer/index.md"

printf "MindLayer ml session contract\n"
printf "=============================\n"

scenario "thresholds"
heavy="$SANDBOX/heavy.out"
light="$SANDBOX/light.out"
if (cd "$SANDBOX/project" && python3 "$ROOT_DIR/src/ml" session --words 100000 > "$heavy"); then
  pass "$CURRENT_SCENARIO: heavy command exits successfully"
else
  fail "$CURRENT_SCENARIO: heavy command exits successfully"
fi
if (cd "$SANDBOX/project" && python3 "$ROOT_DIR/src/ml" session --words 100 > "$light"); then
  pass "$CURRENT_SCENARIO: light command exits successfully"
else
  fail "$CURRENT_SCENARIO: light command exits successfully"
fi
if grep -Eq "Heavy|Critical" "$heavy"; then pass "$CURRENT_SCENARIO: 100000 words is heavy or critical"; else fail "$CURRENT_SCENARIO: 100000 words is heavy or critical"; fi
if grep -Fq "Light" "$light"; then pass "$CURRENT_SCENARIO: 100 words is light"; else fail "$CURRENT_SCENARIO: 100 words is light"; fi

printf "\nSummary: %s passed, %s failed\n" "$PASS_COUNT" "$FAIL_COUNT"
[ "$FAIL_COUNT" -eq 0 ]
