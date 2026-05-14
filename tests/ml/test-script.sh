#!/usr/bin/env bash
# CLI contract tests for `ml script`.

set -u

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
SANDBOX="${TMPDIR:-/tmp}/mindlayer-ml-script-test.$$"
PASS_COUNT=0
FAIL_COUNT=0
CURRENT_SCENARIO=""

pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf "PASS  %s\n" "$1"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); printf "FAIL  %s\n" "$1"; }
scenario() { CURRENT_SCENARIO="$1"; printf "\n## %s\n" "$CURRENT_SCENARIO"; }
assert_contains() { grep -Fq -- "$2" "$1"; }

cleanup() { rm -rf "$SANDBOX"; }
trap cleanup EXIT

printf "MindLayer ml script contract\n"
printf "============================\n"

scenario "script help lists status"
mkdir -p "$SANDBOX/help/.mindlayer" "$SANDBOX/help/.mindlayer/knowledge" "$SANDBOX/help/.mindlayer/pipeline" "$SANDBOX/help/.mindlayer/pipeline/archive" "$SANDBOX/help/.mindlayer/knowledge/sessions"
output="$SANDBOX/help.out"
if (cd "$SANDBOX/help" && python3 "$ROOT_DIR/src/ml" script --help > "$output"); then
  pass "$CURRENT_SCENARIO: command exits 0"
else
  fail "$CURRENT_SCENARIO: command exits 0"
fi
if assert_contains "$output" "status"; then pass "$CURRENT_SCENARIO: status shown"; else fail "$CURRENT_SCENARIO: status shown"; fi
if assert_contains "$output" "SCRIPT"; then pass "$CURRENT_SCENARIO: SCRIPT shown"; else fail "$CURRENT_SCENARIO: SCRIPT shown"; fi

scenario "status before pipeline exists is read-only empty state"
mkdir -p "$SANDBOX/no-pipeline/.mindlayer"
output="$SANDBOX/no-pipeline.out"
before="$SANDBOX/no-pipeline.before"
after="$SANDBOX/no-pipeline.after"
(cd "$SANDBOX/no-pipeline" && find .mindlayer -type f -print | sort > "$before")
if (cd "$SANDBOX/no-pipeline" && python3 "$ROOT_DIR/src/ml" script status > "$output"); then
  pass "$CURRENT_SCENARIO: command exits 0"
else
  fail "$CURRENT_SCENARIO: command exits 0"
fi
(cd "$SANDBOX/no-pipeline" && find .mindlayer -type f -print | sort > "$after")
if assert_contains "$output" "SCRIPT Status:"; then pass "$CURRENT_SCENARIO: status header"; else fail "$CURRENT_SCENARIO: status header"; fi
if assert_contains "$output" "not initialized"; then pass "$CURRENT_SCENARIO: not initialized message"; else fail "$CURRENT_SCENARIO: not initialized message"; fi
if cmp -s "$before" "$after"; then pass "$CURRENT_SCENARIO: no files written"; else fail "$CURRENT_SCENARIO: no files written"; fi
if [ ! -d "$SANDBOX/no-pipeline/.mindlayer/pipeline" ]; then pass "$CURRENT_SCENARIO: pipeline not created"; else fail "$CURRENT_SCENARIO: pipeline not created"; fi

scenario "status with empty pipeline reports no active work"
mkdir -p "$SANDBOX/empty-pipeline/.mindlayer/pipeline"
output="$SANDBOX/empty-pipeline.out"
if (cd "$SANDBOX/empty-pipeline" && python3 "$ROOT_DIR/src/ml" script status > "$output"); then
  pass "$CURRENT_SCENARIO: command exits 0"
else
  fail "$CURRENT_SCENARIO: command exits 0"
fi
if assert_contains "$output" "No active SCRIPT work."; then pass "$CURRENT_SCENARIO: no active work message"; else fail "$CURRENT_SCENARIO: no active work message"; fi
if assert_contains "$output" "Signals: 0"; then pass "$CURRENT_SCENARIO: signal count"; else fail "$CURRENT_SCENARIO: signal count"; fi
if assert_contains "$output" "Stories: 0 ready, 0 in-progress"; then pass "$CURRENT_SCENARIO: story counts"; else fail "$CURRENT_SCENARIO: story counts"; fi

scenario "unknown script command fails cleanly"
mkdir -p "$SANDBOX/unknown/.mindlayer" "$SANDBOX/unknown/.mindlayer/knowledge" "$SANDBOX/unknown/.mindlayer/pipeline" "$SANDBOX/unknown/.mindlayer/pipeline/archive" "$SANDBOX/unknown/.mindlayer/knowledge/sessions"
output="$SANDBOX/unknown.out"
if ! (cd "$SANDBOX/unknown" && python3 "$ROOT_DIR/src/ml" script nope > "$output" 2>&1); then
  pass "$CURRENT_SCENARIO: exits non-zero"
else
  fail "$CURRENT_SCENARIO: exits non-zero"
fi
if assert_contains "$output" "invalid choice"; then pass "$CURRENT_SCENARIO: argparse error"; else fail "$CURRENT_SCENARIO: argparse error"; fi

scenario "existing status command still works"
mkdir -p "$SANDBOX/existing/.mindlayer" "$SANDBOX/existing/.mindlayer/knowledge" "$SANDBOX/existing/.mindlayer/pipeline" "$SANDBOX/existing/.mindlayer/pipeline/archive" "$SANDBOX/existing/.mindlayer/knowledge/sessions"
printf "# Project Memory Index\n" > "$SANDBOX/existing/.mindlayer/index.md"
output="$SANDBOX/existing.out"
if (cd "$SANDBOX/existing" && python3 "$ROOT_DIR/src/ml" status > "$output"); then
  pass "$CURRENT_SCENARIO: command exits 0"
else
  fail "$CURRENT_SCENARIO: command exits 0"
fi
if assert_contains "$output" "Per-File Health:"; then pass "$CURRENT_SCENARIO: existing status output"; else fail "$CURRENT_SCENARIO: existing status output"; fi

printf "\nSummary: %s passed, %s failed\n" "$PASS_COUNT" "$FAIL_COUNT"
[ "$FAIL_COUNT" -eq 0 ]
