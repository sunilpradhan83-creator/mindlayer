#!/usr/bin/env bash
# CLI contract tests for `ml archive`.

set -u

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
SANDBOX="${TMPDIR:-/tmp}/mindlayer-ml-archive-test.$$"
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

printf "MindLayer ml archive contract\n"
printf "=============================\n"

# --- archive section ---
scenario "archive section"
mkdir -p "$SANDBOX/archive/.mindlayer" "$SANDBOX/archive/.mindlayer/knowledge" "$SANDBOX/archive/.mindlayer/pipeline" "$SANDBOX/archive/.mindlayer/pipeline/archive" "$SANDBOX/archive/.mindlayer/knowledge/sessions"
printf "# Context\n\n## Old Entry\n\nStale content.\n\n## Live Entry\n\nCurrent.\n" \
  > "$SANDBOX/archive/.mindlayer/knowledge/context.md"
printf "# Project Memory Index\n- ml-old-001 | Old Entry | context.md | Stale content.\n- ml-live-001 | Live Entry | context.md | Current.\n" \
  > "$SANDBOX/archive/.mindlayer/index.md"
output="$SANDBOX/archive.out"
if (cd "$SANDBOX/archive" && python3 "$ROOT_DIR/src/ml" archive \
    --file context.md --section "Old Entry" --action archive > "$output"); then
  pass "$CURRENT_SCENARIO: command exits 0"
else
  fail "$CURRENT_SCENARIO: command exits 0"
fi
if assert_contains "$output" "Archive Candidate:"; then pass "$CURRENT_SCENARIO: proposal printed"; else fail "$CURRENT_SCENARIO: proposal printed"; fi
if assert_contains "$output" "approve all"; then pass "$CURRENT_SCENARIO: approval prompt printed"; else fail "$CURRENT_SCENARIO: approval prompt printed"; fi
if assert_file_contains "$SANDBOX/archive/.mindlayer/knowledge/context.md" "Old Entry"; then pass "$CURRENT_SCENARIO: no archive before approval"; else fail "$CURRENT_SCENARIO: no archive before approval"; fi
if (cd "$SANDBOX/archive" && python3 "$ROOT_DIR/src/ml" archive \
    --file context.md --section "Old Entry" --action archive --approve-all > "$output"); then
  pass "$CURRENT_SCENARIO: approved command exits 0"
else
  fail "$CURRENT_SCENARIO: approved command exits 0"
fi
if assert_contains "$output" "Archived:"; then pass "$CURRENT_SCENARIO: Archived printed"; else fail "$CURRENT_SCENARIO: Archived printed"; fi
if ! grep -Fq "Old Entry" "$SANDBOX/archive/.mindlayer/knowledge/context.md"; then pass "$CURRENT_SCENARIO: section removed from source"; else fail "$CURRENT_SCENARIO: section removed from source"; fi
if assert_file_contains "$SANDBOX/archive/.mindlayer/pipeline/archive/archive.md" "Old Entry"; then pass "$CURRENT_SCENARIO: section in archive.md"; else fail "$CURRENT_SCENARIO: section in archive.md"; fi
if assert_file_contains "$SANDBOX/archive/.mindlayer/pipeline/archive/archive.md" "Stale content."; then pass "$CURRENT_SCENARIO: content in archive.md"; else fail "$CURRENT_SCENARIO: content in archive.md"; fi
if assert_file_contains "$SANDBOX/archive/.mindlayer/knowledge/context.md" "Live Entry"; then pass "$CURRENT_SCENARIO: live entry preserved"; else fail "$CURRENT_SCENARIO: live entry preserved"; fi

# --- delete section ---
scenario "delete section"
mkdir -p "$SANDBOX/delete/.mindlayer" "$SANDBOX/delete/.mindlayer/knowledge" "$SANDBOX/delete/.mindlayer/pipeline" "$SANDBOX/delete/.mindlayer/pipeline/archive" "$SANDBOX/delete/.mindlayer/knowledge/sessions"
printf "# Context\n\n## Ephemeral\n\nTemp content.\n\n## Keeper\n\nStays.\n" \
  > "$SANDBOX/delete/.mindlayer/knowledge/context.md"
printf "# Project Memory Index\n- ml-eph-001 | Ephemeral | context.md | Temp.\n" \
  > "$SANDBOX/delete/.mindlayer/index.md"
output="$SANDBOX/delete.out"
if (cd "$SANDBOX/delete" && python3 "$ROOT_DIR/src/ml" archive \
    --file context.md --section "Ephemeral" --action delete --approve-all > "$output"); then
  pass "$CURRENT_SCENARIO: command exits 0"
else
  fail "$CURRENT_SCENARIO: command exits 0"
fi
if assert_contains "$output" "Deleted:"; then pass "$CURRENT_SCENARIO: Deleted printed"; else fail "$CURRENT_SCENARIO: Deleted printed"; fi
if ! grep -Fq "Ephemeral" "$SANDBOX/delete/.mindlayer/knowledge/context.md"; then pass "$CURRENT_SCENARIO: section removed from source"; else fail "$CURRENT_SCENARIO: section removed from source"; fi
if ! [ -f "$SANDBOX/delete/.mindlayer/pipeline/archive/archive.md" ] || ! grep -Fq "Ephemeral" "$SANDBOX/delete/.mindlayer/pipeline/archive/archive.md"; then
  pass "$CURRENT_SCENARIO: section not in archive.md"
else
  fail "$CURRENT_SCENARIO: section not in archive.md"
fi
if ! grep -Fq "ml-eph-001" "$SANDBOX/delete/.mindlayer/index.md"; then pass "$CURRENT_SCENARIO: index entry removed"; else fail "$CURRENT_SCENARIO: index entry removed"; fi

# --- section not found fails ---
scenario "missing section exits non-zero"
mkdir -p "$SANDBOX/missing/.mindlayer" "$SANDBOX/missing/.mindlayer/knowledge" "$SANDBOX/missing/.mindlayer/pipeline" "$SANDBOX/missing/.mindlayer/pipeline/archive" "$SANDBOX/missing/.mindlayer/knowledge/sessions"
printf "# Context\n\n## Only Entry\n\nContent.\n" > "$SANDBOX/missing/.mindlayer/knowledge/context.md"
output="$SANDBOX/missing.out"
if ! (cd "$SANDBOX/missing" && python3 "$ROOT_DIR/src/ml" archive \
    --file context.md --section "Nonexistent" --action archive > "$output" 2>&1); then
  pass "$CURRENT_SCENARIO: exits non-zero"
else
  fail "$CURRENT_SCENARIO: exits non-zero"
fi
if assert_contains "$output" "not found"; then pass "$CURRENT_SCENARIO: error message printed"; else fail "$CURRENT_SCENARIO: error message printed"; fi

# --- archive.md itself is protected ---
scenario "cannot archive from archive.md"
mkdir -p "$SANDBOX/selfarch/.mindlayer" "$SANDBOX/selfarch/.mindlayer/knowledge" "$SANDBOX/selfarch/.mindlayer/pipeline" "$SANDBOX/selfarch/.mindlayer/pipeline/archive" "$SANDBOX/selfarch/.mindlayer/knowledge/sessions"
printf "# Archive\n\n## Old\n\nArchived.\n" > "$SANDBOX/selfarch/.mindlayer/pipeline/archive/archive.md"
output="$SANDBOX/selfarch.out"
if ! (cd "$SANDBOX/selfarch" && python3 "$ROOT_DIR/src/ml" archive \
    --file archive.md --section "Old" --action archive > "$output" 2>&1); then
  pass "$CURRENT_SCENARIO: exits non-zero"
else
  fail "$CURRENT_SCENARIO: exits non-zero"
fi
if assert_contains "$output" "protected"; then pass "$CURRENT_SCENARIO: protected error message"; else fail "$CURRENT_SCENARIO: protected error message"; fi

# --- archive.md created with heading if absent ---
scenario "archive.md created on first archive"
mkdir -p "$SANDBOX/newarchive/.mindlayer" "$SANDBOX/newarchive/.mindlayer/knowledge" "$SANDBOX/newarchive/.mindlayer/pipeline" "$SANDBOX/newarchive/.mindlayer/pipeline/archive" "$SANDBOX/newarchive/.mindlayer/knowledge/sessions"
printf "# Decisions\n\n## Old Decision\n\nWas decided.\n" > "$SANDBOX/newarchive/.mindlayer/knowledge/decisions.md"
output="$SANDBOX/newarchive.out"
if (cd "$SANDBOX/newarchive" && python3 "$ROOT_DIR/src/ml" archive \
    --file decisions.md --section "Old Decision" --action archive --approve-all > "$output"); then
  pass "$CURRENT_SCENARIO: command exits 0"
else
  fail "$CURRENT_SCENARIO: command exits 0"
fi
if assert_file_contains "$SANDBOX/newarchive/.mindlayer/pipeline/archive/archive.md" "# Archive"; then pass "$CURRENT_SCENARIO: archive.md has heading"; else fail "$CURRENT_SCENARIO: archive.md has heading"; fi

printf "\nSummary: %s passed, %s failed\n" "$PASS_COUNT" "$FAIL_COUNT"
[ "$FAIL_COUNT" -eq 0 ]
