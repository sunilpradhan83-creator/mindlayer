#!/usr/bin/env bash
# CLI contract tests for `ml diff`.

set -u

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
SANDBOX="${TMPDIR:-/tmp}/mindlayer-ml-diff-test.$$"
PASS_COUNT=0
FAIL_COUNT=0
CURRENT_SCENARIO=""

pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf "PASS  %s\n" "$1"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); printf "FAIL  %s\n" "$1"; }
scenario() { CURRENT_SCENARIO="$1"; printf "\n## %s\n" "$CURRENT_SCENARIO"; }
assert_contains() { grep -Fq "$2" "$1"; }

cleanup() { rm -rf "$SANDBOX"; }
trap cleanup EXIT

printf "MindLayer ml diff contract\n"
printf "==========================\n"

scenario "new entry since session"
mkdir -p "$SANDBOX/project/.mindlayer/knowledge/sessions"
cd "$SANDBOX/project" || exit 1
git init >/dev/null 2>&1
git config user.email "test@example.com"
git config user.name "Test User"
cat > .mindlayer/knowledge/context.md <<'EOF'
# Context

## First
id: ml-first
status: active
EOF
git add .mindlayer/knowledge/context.md
git commit -m "base" >/dev/null 2>&1
base_sha=$(git rev-parse HEAD)
cat > .mindlayer/knowledge/sessions/2026-05-12.md <<EOF
# Session

## Commit
$base_sha
EOF
cat >> .mindlayer/knowledge/context.md <<'EOF'

## Second
id: ml-second
status: active
EOF
git add .mindlayer
git commit -m "add memory" >/dev/null 2>&1

output="$SANDBOX/diff.out"
if python3 "$ROOT_DIR/src/ml" diff > "$output"; then
  pass "$CURRENT_SCENARIO: command exits successfully"
else
  fail "$CURRENT_SCENARIO: command exits successfully"
fi
if assert_contains "$output" "New:      1 entries"; then
  pass "$CURRENT_SCENARIO: reports one new entry"
else
  fail "$CURRENT_SCENARIO: reports one new entry"
fi

printf "\nSummary: %s passed, %s failed\n" "$PASS_COUNT" "$FAIL_COUNT"
[ "$FAIL_COUNT" -eq 0 ]

