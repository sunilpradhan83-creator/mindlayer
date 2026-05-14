#!/usr/bin/env bash
# CLI contract tests for `ml save`.

set -u

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
SANDBOX="${TMPDIR:-/tmp}/mindlayer-ml-save-test.$$"
PASS_COUNT=0
FAIL_COUNT=0
CURRENT_SCENARIO=""

pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf "PASS  %s\n" "$1"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); printf "FAIL  %s\n" "$1"; }
scenario() { CURRENT_SCENARIO="$1"; printf "\n## %s\n" "$CURRENT_SCENARIO"; }
assert_contains() { grep -Fq "$2" "$1"; }
assert_file_contains() { grep -Fq "$2" "$1"; }

cleanup() { rm -rf "$SANDBOX"; }
trap cleanup EXIT

printf "MindLayer ml save contract\n"
printf "==========================\n"

# --- create new section ---
scenario "create new section"
mkdir -p "$SANDBOX/create/.mindlayer" "$SANDBOX/create/.mindlayer/knowledge" "$SANDBOX/create/.mindlayer/pipeline" "$SANDBOX/create/.mindlayer/pipeline/archive" "$SANDBOX/create/.mindlayer/knowledge/sessions"
printf "# Context\n" > "$SANDBOX/create/.mindlayer/knowledge/context.md"
output="$SANDBOX/create.out"
if (cd "$SANDBOX/create" && python3 "$ROOT_DIR/src/ml" save \
    --file context.md --section "My Entry" --content "Hello world." \
    --action create > "$output"); then
  pass "$CURRENT_SCENARIO: command exits 0"
else
  fail "$CURRENT_SCENARIO: command exits 0"
fi
if assert_contains "$output" "Memory Candidate:"; then pass "$CURRENT_SCENARIO: proposal printed"; else fail "$CURRENT_SCENARIO: proposal printed"; fi
if assert_contains "$output" "Pending approval"; then pass "$CURRENT_SCENARIO: pending approval printed"; else fail "$CURRENT_SCENARIO: pending approval printed"; fi
if ! grep -Fq "## My Entry" "$SANDBOX/create/.mindlayer/knowledge/context.md"; then pass "$CURRENT_SCENARIO: no write before approval"; else fail "$CURRENT_SCENARIO: no write before approval"; fi
if (cd "$SANDBOX/create" && python3 "$ROOT_DIR/src/ml" save \
    --file context.md --section "My Entry" --content "Hello world." \
    --action create --approve > "$output"); then
  pass "$CURRENT_SCENARIO: approved command exits 0"
else
  fail "$CURRENT_SCENARIO: approved command exits 0"
fi
if assert_contains "$output" "Written:"; then pass "$CURRENT_SCENARIO: Written printed"; else fail "$CURRENT_SCENARIO: Written printed"; fi
if assert_contains "$output" "created section"; then pass "$CURRENT_SCENARIO: created section in output"; else fail "$CURRENT_SCENARIO: created section in output"; fi
if assert_file_contains "$SANDBOX/create/.mindlayer/knowledge/context.md" "## My Entry"; then pass "$CURRENT_SCENARIO: section heading in file"; else fail "$CURRENT_SCENARIO: section heading in file"; fi
if assert_file_contains "$SANDBOX/create/.mindlayer/knowledge/context.md" "Hello world."; then pass "$CURRENT_SCENARIO: content in file"; else fail "$CURRENT_SCENARIO: content in file"; fi

# --- update existing section ---
scenario "update existing section"
mkdir -p "$SANDBOX/update/.mindlayer" "$SANDBOX/update/.mindlayer/knowledge" "$SANDBOX/update/.mindlayer/pipeline" "$SANDBOX/update/.mindlayer/pipeline/archive" "$SANDBOX/update/.mindlayer/knowledge/sessions"
printf "# Context\n\n## My Entry\n\nOld content.\n" > "$SANDBOX/update/.mindlayer/knowledge/context.md"
output="$SANDBOX/update.out"
if (cd "$SANDBOX/update" && python3 "$ROOT_DIR/src/ml" save \
    --file context.md --section "My Entry" --content "New content." \
    --action update --approve > "$output"); then
  pass "$CURRENT_SCENARIO: command exits 0"
else
  fail "$CURRENT_SCENARIO: command exits 0"
fi
if assert_contains "$output" "updated section"; then pass "$CURRENT_SCENARIO: updated section in output"; else fail "$CURRENT_SCENARIO: updated section in output"; fi
if assert_file_contains "$SANDBOX/update/.mindlayer/knowledge/context.md" "New content."; then pass "$CURRENT_SCENARIO: new content in file"; else fail "$CURRENT_SCENARIO: new content in file"; fi
if ! grep -Fq "Old content." "$SANDBOX/update/.mindlayer/knowledge/context.md"; then pass "$CURRENT_SCENARIO: old content removed"; else fail "$CURRENT_SCENARIO: old content removed"; fi

# --- create on existing section fails ---
scenario "create refuses duplicate section"
mkdir -p "$SANDBOX/dup/.mindlayer" "$SANDBOX/dup/.mindlayer/knowledge" "$SANDBOX/dup/.mindlayer/pipeline" "$SANDBOX/dup/.mindlayer/pipeline/archive" "$SANDBOX/dup/.mindlayer/knowledge/sessions"
printf "# Context\n\n## Already Here\n\nSome text.\n" > "$SANDBOX/dup/.mindlayer/knowledge/context.md"
output="$SANDBOX/dup.out"
if ! (cd "$SANDBOX/dup" && python3 "$ROOT_DIR/src/ml" save \
    --file context.md --section "Already Here" --content "New." \
    --action create > "$output" 2>&1); then
  pass "$CURRENT_SCENARIO: exits non-zero"
else
  fail "$CURRENT_SCENARIO: exits non-zero"
fi
if assert_contains "$output" "already exists"; then pass "$CURRENT_SCENARIO: error message printed"; else fail "$CURRENT_SCENARIO: error message printed"; fi

# --- protected file refused ---
scenario "protected file refused"
mkdir -p "$SANDBOX/protected/.mindlayer" "$SANDBOX/protected/.mindlayer/knowledge" "$SANDBOX/protected/.mindlayer/pipeline" "$SANDBOX/protected/.mindlayer/pipeline/archive" "$SANDBOX/protected/.mindlayer/knowledge/sessions"
output="$SANDBOX/protected.out"
if ! (cd "$SANDBOX/protected" && python3 "$ROOT_DIR/src/ml" save \
    --file index.md --section "Sneaky" --content "Nope." \
    --action create > "$output" 2>&1); then
  pass "$CURRENT_SCENARIO: exits non-zero"
else
  fail "$CURRENT_SCENARIO: exits non-zero"
fi
if assert_contains "$output" "protected"; then pass "$CURRENT_SCENARIO: protected error message"; else fail "$CURRENT_SCENARIO: protected error message"; fi

# --- index entry appended ---
scenario "index entry written"
mkdir -p "$SANDBOX/index/.mindlayer" "$SANDBOX/index/.mindlayer/knowledge" "$SANDBOX/index/.mindlayer/pipeline" "$SANDBOX/index/.mindlayer/pipeline/archive" "$SANDBOX/index/.mindlayer/knowledge/sessions"
printf "# Project Memory Index\n" > "$SANDBOX/index/.mindlayer/index.md"
printf "# Context\n" > "$SANDBOX/index/.mindlayer/knowledge/context.md"
output="$SANDBOX/index.out"
if (cd "$SANDBOX/index" && python3 "$ROOT_DIR/src/ml" save \
    --file context.md --section "My Entry" --content "Body text." \
    --action create --approve \
    --index-entry "ml-test-001 | My Entry | context.md | Body text." > "$output"); then
  pass "$CURRENT_SCENARIO: command exits 0"
else
  fail "$CURRENT_SCENARIO: command exits 0"
fi
if assert_file_contains "$SANDBOX/index/.mindlayer/index.md" "ml-test-001"; then pass "$CURRENT_SCENARIO: id in index"; else fail "$CURRENT_SCENARIO: id in index"; fi
if assert_file_contains "$SANDBOX/index/.mindlayer/index.md" "My Entry"; then pass "$CURRENT_SCENARIO: title in index"; else fail "$CURRENT_SCENARIO: title in index"; fi

printf "\nSummary: %s passed, %s failed\n" "$PASS_COUNT" "$FAIL_COUNT"
[ "$FAIL_COUNT" -eq 0 ]
