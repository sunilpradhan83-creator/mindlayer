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
assert_not_contains() { ! grep -Fq "$2" "$1"; }
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

mkdir -p "$SANDBOX/home/.mindlayer/memory-system" "$SANDBOX/project/.mindlayer" "$SANDBOX/project/.mindlayer/knowledge" "$SANDBOX/project/.mindlayer/pipeline" "$SANDBOX/project/.mindlayer/pipeline/archive" "$SANDBOX/project/.mindlayer/knowledge/sessions"
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
cat > "$SANDBOX/project/.mindlayer/knowledge/project.md" <<'EOF'
# Project

## Project Identity

### Summary
Test project identity.
EOF
cat > "$SANDBOX/project/.mindlayer/pipeline/progress.md" <<'EOF'
# Progress

## Current Phase

### Summary
Command runner foundation.
EOF
cat > "$SANDBOX/project/.mindlayer/pipeline/backlog.md" <<'EOF'
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

scenario "starter sentinels do not leak"
cat > "$SANDBOX/home/.mindlayer/preferences/personal.md" <<'EOF'
# Personal Preferences

User-owned cross-project preferences for how AI coding agents should work with you.

This file is git-backed at `~/.mindlayer/preferences/`. Add a remote to back it up:
`git -C ~/.mindlayer/preferences remote add origin <your-private-repo>`

Do not store secrets, raw conversations, or project-specific facts here.

## User Preferences

id: ml-global-YYYYMMDD-001
created: YYYY-MM-DD
updated: YYYY-MM-DD
scope: global
type: preference
tags: [preferences]
confidence: medium
status: active
source: starter

### Summary
<!-- ml:starter:personal.summary -->
No user preferences saved yet.

### Details
<!-- ml:starter:personal.details -->
Add durable cross-project preferences here only after explicit approval.

### When to use
<!-- ml:starter:personal.when-to-use -->
Skip this section during boot until real user preferences are saved.

### Related
EOF
cat > "$SANDBOX/project/.mindlayer/knowledge/project.md" <<'EOF'
# Project Memory

## Entry Template

### Summary
<!-- ml:starter:project.summary -->
Short summary.

### Details
<!-- ml:starter:project.details -->
Useful details.
EOF
cat > "$SANDBOX/project/.mindlayer/pipeline/progress.md" <<'EOF'
# Progress

## Current State

### Summary
Current phase and immediate next step.

### Details
- Current phase:
- Completed:
- Active:
- Next step:
EOF
sentinel_output="$SANDBOX/boot-sentinel.out"
if (cd "$SANDBOX/project" && HOME="$SANDBOX/home" python3 "$ROOT_DIR/src/ml" boot > "$sentinel_output"); then
  pass "$CURRENT_SCENARIO: command exits successfully"
else
  fail "$CURRENT_SCENARIO: command exits successfully"
fi

check "starter personal preferences skipped" assert_contains "$sentinel_output" '`~/.mindlayer/preferences/personal.md` (missing or starter-only)'
check "starter project summary suppressed" assert_contains "$sentinel_output" "No substantive project identity saved yet."
check "starter project summary not leaked" assert_not_contains "$sentinel_output" "Short summary."
check "starter progress suppressed" assert_contains "$sentinel_output" "No substantive project progress has been saved yet."
check "starter progress labels not leaked" assert_not_contains "$sentinel_output" "Current phase: Completed:"

scenario "legacy starter strings do not leak"
cat > "$SANDBOX/home/.mindlayer/preferences/personal.md" <<'EOF'
# Personal Preferences

User-owned cross-project preferences for how AI coding agents should work with you.

This file is git-backed at `~/.mindlayer/preferences/`. Add a remote to back it up:
`git -C ~/.mindlayer/preferences remote add origin <your-private-repo>`

Do not store secrets, raw conversations, or project-specific facts here.

## User Preferences

id: ml-global-YYYYMMDD-001
created: YYYY-MM-DD
updated: YYYY-MM-DD
scope: global
type: preference
tags: [preferences]
confidence: medium
status: active
source: starter

### Summary
No user preferences saved yet.

### Details
Add durable cross-project preferences here only after explicit approval.

### When to use
Skip this section during boot until real user preferences are saved.

### Related
EOF
cat > "$SANDBOX/project/.mindlayer/knowledge/project.md" <<'EOF'
# Project Memory

## Entry Template

### Summary
Short summary.

### Details
Useful details.
EOF
cat > "$SANDBOX/project/.mindlayer/pipeline/progress.md" <<'EOF'
# Progress

## Current State

### Summary
Current phase and immediate next step.

### Details
- Current phase:
- Completed:
- Active:
- Next step:
EOF
legacy_output="$SANDBOX/boot-legacy.out"
if (cd "$SANDBOX/project" && HOME="$SANDBOX/home" python3 "$ROOT_DIR/src/ml" boot > "$legacy_output"); then
  pass "$CURRENT_SCENARIO: command exits successfully"
else
  fail "$CURRENT_SCENARIO: command exits successfully"
fi

check "legacy personal preferences skipped" assert_contains "$legacy_output" '`~/.mindlayer/preferences/personal.md` (missing or starter-only)'
check "legacy project summary suppressed" assert_contains "$legacy_output" "No substantive project identity saved yet."
check "legacy project summary not leaked" assert_not_contains "$legacy_output" "Short summary."
check "legacy progress suppressed" assert_contains "$legacy_output" "No substantive project progress has been saved yet."
check "legacy progress labels not leaked" assert_not_contains "$legacy_output" "Current phase: Completed:"

printf "\nSummary: %s passed, %s failed\n" "$PASS_COUNT" "$FAIL_COUNT"
[ "$FAIL_COUNT" -eq 0 ]
