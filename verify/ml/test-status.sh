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
assert_not_contains() { ! grep -Fq -- "$2" "$1"; }

cleanup() { rm -rf "$SANDBOX"; }
trap cleanup EXIT

mkdir -p "$SANDBOX/project/.mindlayer" "$SANDBOX/project/.mindlayer/knowledge" "$SANDBOX/project/.mindlayer/pipeline" "$SANDBOX/project/.mindlayer/pipeline/archive" "$SANDBOX/project/.mindlayer/knowledge/sessions"
cat > "$SANDBOX/project/.mindlayer/index.md" <<'EOF'
# Project Memory Index
EOF
cat > "$SANDBOX/project/.mindlayer/pipeline/progress.md" <<'EOF'
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
} > "$SANDBOX/project/.mindlayer/knowledge/context.md"

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

scenario "starter progress is not surfaced"
cat > "$SANDBOX/project/.mindlayer/pipeline/progress.md" <<'EOF'
# Progress

## Current State

### Summary
<!-- ml:starter:progress.summary -->
Current phase and immediate next step.

### Details
<!-- ml:starter:progress.details -->
- Current phase:
- Completed:
- Active:
- Next step:
EOF
starter_output="$SANDBOX/status-starter.out"
if (cd "$SANDBOX/project" && python3 "$ROOT_DIR/src/ml" status > "$starter_output"); then
  pass "$CURRENT_SCENARIO: command exits successfully"
else
  fail "$CURRENT_SCENARIO: command exits successfully"
fi
if assert_contains "$starter_output" "- current progress: not recorded"; then pass "$CURRENT_SCENARIO: starter progress suppressed"; else fail "$CURRENT_SCENARIO: starter progress suppressed"; fi
if assert_not_contains "$starter_output" "ml:starter:progress.summary"; then pass "$CURRENT_SCENARIO: sentinel not leaked"; else fail "$CURRENT_SCENARIO: sentinel not leaked"; fi
if assert_not_contains "$starter_output" "Current phase and immediate next step."; then pass "$CURRENT_SCENARIO: starter summary not leaked"; else fail "$CURRENT_SCENARIO: starter summary not leaked"; fi

scenario "standard subheadings are not duplicate entries"
cat > "$SANDBOX/project/.mindlayer/knowledge/context.md" <<'EOF'
# Context

## First Entry

### Summary
First summary.

## Second Entry

### Summary
Second summary.
EOF
subheading_output="$SANDBOX/status-subheadings.out"
if (cd "$SANDBOX/project" && python3 "$ROOT_DIR/src/ml" status > "$subheading_output"); then
  pass "$CURRENT_SCENARIO: command exits successfully"
else
  fail "$CURRENT_SCENARIO: command exits successfully"
fi
if assert_contains "$subheading_output" "context.md    OK"; then pass "$CURRENT_SCENARIO: repeated Summary headings allowed"; else fail "$CURRENT_SCENARIO: repeated Summary headings allowed"; fi
if assert_not_contains "$subheading_output" "near-identical entries"; then pass "$CURRENT_SCENARIO: no duplicate false positive"; else fail "$CURRENT_SCENARIO: no duplicate false positive"; fi

scenario "duplicate entry headings are flagged"
cat > "$SANDBOX/project/.mindlayer/knowledge/context.md" <<'EOF'
# Context

## Same Entry

### Summary
First summary.

## Same Entry

### Summary
Second summary.
EOF
duplicate_output="$SANDBOX/status-duplicate.out"
if (cd "$SANDBOX/project" && python3 "$ROOT_DIR/src/ml" status > "$duplicate_output"); then
  pass "$CURRENT_SCENARIO: command exits successfully"
else
  fail "$CURRENT_SCENARIO: command exits successfully"
fi
if assert_contains "$duplicate_output" "context.md    CRITICAL"; then pass "$CURRENT_SCENARIO: duplicate entry heading flagged"; else fail "$CURRENT_SCENARIO: duplicate entry heading flagged"; fi
if assert_contains "$duplicate_output" "near-identical entries"; then pass "$CURRENT_SCENARIO: duplicate issue reported"; else fail "$CURRENT_SCENARIO: duplicate issue reported"; fi

printf "\nSummary: %s passed, %s failed\n" "$PASS_COUNT" "$FAIL_COUNT"
[ "$FAIL_COUNT" -eq 0 ]
