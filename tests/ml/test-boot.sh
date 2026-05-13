#!/usr/bin/env bash
# CLI contract tests for `ml boot`.

set -u

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
SANDBOX="${TMPDIR:-/tmp}/mindlayer-ml-boot-test.$$"
PASS_COUNT=0
FAIL_COUNT=0
CURRENT_SCENARIO=""

pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf "PASS  %s\n" "$1"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); printf "FAIL  %s\n" "$1"; }
scenario() { CURRENT_SCENARIO="$1"; printf "\n## %s\n" "$CURRENT_SCENARIO"; }

assert_contains() { grep -Fq "$2" "$1"; }
assert_not_contains_loaded_index_full() {
  awk '
    /^Loaded:/ { loaded = 1; next }
    /^[A-Z][A-Za-z ]*:/ { loaded = 0 }
    loaded && /index-full\.md/ { bad = 1 }
    END { exit bad ? 1 : 0 }
  ' "$1"
}

check() {
  label="$1"
  shift
  if "$@" 2>/dev/null; then
    pass "$CURRENT_SCENARIO: $label"
  else
    fail "$CURRENT_SCENARIO: $label"
  fi
}

cleanup() { rm -rf "$SANDBOX"; }
trap cleanup EXIT

mkdir -p "$SANDBOX/home/.mindlayer/memory-system" "$SANDBOX/project/.mindlayer"
mkdir -p "$SANDBOX/home/.mindlayer/preferences"
cat > "$SANDBOX/home/.mindlayer/boot.md" <<'EOF'
# Boot
EOF
cat > "$SANDBOX/home/.mindlayer/router.md" <<'EOF'
# Router
EOF
cat > "$SANDBOX/home/.mindlayer/memory-system/per-turn.md" <<'EOF'
# Per Turn
EOF
cat > "$SANDBOX/home/.mindlayer/preferences/personal.md" <<'EOF'
# Global Preferences

## Starter Preferences

### Summary
Use MindLayer memory cautiously.

## Plan-First Approval Before Implementation

### Summary
Show the plan and wait for explicit approval before implementing any non-trivial task.
EOF
cat > "$SANDBOX/project/.mindlayer/index.md" <<'EOF'
# Project Memory Index

- ml-project-test | Project Identity | project.md | Test project.
EOF
cat > "$SANDBOX/project/.mindlayer/index-full.md" <<'EOF'
# Full index must not load during boot.
EOF
cat > "$SANDBOX/project/.mindlayer/project.md" <<'EOF'
# Project

## Project Identity

### Summary
Test project identity.
EOF
cat > "$SANDBOX/project/.mindlayer/progress.md" <<'EOF'
# Progress

## Current Phase

### Summary
Command runner foundation.
EOF
cat > "$SANDBOX/project/.mindlayer/backlog.md" <<'EOF'
# Backlog
EOF

printf "MindLayer ml boot contract\n"
printf "==========================\n"

scenario "boot receipt"
output="$SANDBOX/boot.out"
if (cd "$SANDBOX/project" && HOME="$SANDBOX/home" python3 "$ROOT_DIR/src/ml" boot > "$output"); then
  pass "$CURRENT_SCENARIO: command exits successfully"
else
  fail "$CURRENT_SCENARIO: command exits successfully"
fi

check "receipt contains context loaded" assert_contains "$output" "MindLayer context loaded."
check "Loaded present" assert_contains "$output" "Loaded:"
check "Skipped present" assert_contains "$output" "Skipped:"
check "Missing present" assert_contains "$output" "Missing:"
check "Current understanding present" assert_contains "$output" "Current understanding:"
check "Context cost present" assert_contains "$output" "Context cost:"
check "Context share present" assert_contains "$output" "Context share"
check "Ready present" assert_contains "$output" "Ready."
check "index-full not loaded" assert_not_contains_loaded_index_full "$output"
check "substantive personal preferences loaded" assert_contains "$output" '`~/.mindlayer/preferences/personal.md`'

printf "\nSummary: %s passed, %s failed\n" "$PASS_COUNT" "$FAIL_COUNT"
[ "$FAIL_COUNT" -eq 0 ]
