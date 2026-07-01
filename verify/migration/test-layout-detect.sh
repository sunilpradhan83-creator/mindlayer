#!/usr/bin/env bash
# Verifies the dual-layout seam (_layout) detects and reads BOTH the legacy
# pipeline/ layout and the ADR-0001 target work/ layout. Step 2a: read support
# only, no file moves.

set -u

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
SANDBOX="${TMPDIR:-/tmp}/mindlayer-layout-detect.$$"
PASS_COUNT=0
FAIL_COUNT=0
CURRENT_SCENARIO=""

pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf "PASS  %s\n" "$1"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); printf "FAIL  %s\n" "$1"; }
scenario() { CURRENT_SCENARIO="$1"; printf "\n## %s\n" "$1"; }
assert_contains() { grep -Fq "$2" "$1"; }
assert_not_contains() { ! grep -Fq "$2" "$1"; }
check() {
  label="$1"; shift
  if "$@" 2>/dev/null; then pass "$CURRENT_SCENARIO: $label"; else fail "$CURRENT_SCENARIO: $label"; fi
}
cleanup() { rm -rf "$SANDBOX"; }
trap cleanup EXIT

detect() {
  PYTHONPATH="$ROOT_DIR/src" python3 -c \
    "import sys; from pathlib import Path; from commands import _layout; print(_layout.detect_layout(Path(sys.argv[1])))" "$1"
}

mkdir -p "$SANDBOX/home/.mindlayer/memory-system" "$SANDBOX/home/.mindlayer/preferences"
: > "$SANDBOX/home/.mindlayer/boot.md"
: > "$SANDBOX/home/.mindlayer/router.md"
: > "$SANDBOX/home/.mindlayer/memory-system/per-turn.md"

# --- legacy fixture ---
LEGACY="$SANDBOX/legacy"
mkdir -p "$LEGACY/.mindlayer/knowledge/sessions" "$LEGACY/.mindlayer/pipeline/archive"
cat > "$LEGACY/.mindlayer/index.md" <<'EOF'
# Project Memory Index

- ml-project-test | Project Identity | project.md | Legacy layout project.
EOF
cat > "$LEGACY/.mindlayer/knowledge/project.md" <<'EOF'
# Project

## Project Identity

### Summary
Legacy layout project identity.
EOF
cat > "$LEGACY/.mindlayer/pipeline/progress.md" <<'EOF'
# Progress

## Current Phase

### Summary
Legacy progress state.
EOF
cat > "$LEGACY/.mindlayer/pipeline/backlog.md" <<'EOF'
# Backlog
EOF

# --- target (ADR-0001) fixture ---
TARGET="$SANDBOX/target"
mkdir -p "$TARGET/.mindlayer/knowledge" "$TARGET/.mindlayer/work/sessions" "$TARGET/.mindlayer/archive"
cat > "$TARGET/.mindlayer/index.md" <<'EOF'
# Project Memory Index

- ml-project-test | Project Identity | project.md | Target layout project.
EOF
cat > "$TARGET/.mindlayer/knowledge/project.md" <<'EOF'
# Project

## Project Identity

### Summary
Target layout project identity.
EOF
cat > "$TARGET/.mindlayer/work/current.md" <<'EOF'
# Current Work

## Current Phase

### Summary
Consolidated work state in the target layout.
EOF
cat > "$TARGET/.mindlayer/archive/archive.md" <<'EOF'
# Archive
EOF

printf "MindLayer dual-layout detection\n"
printf "===============================\n"

scenario "detect_layout classifies each fixture"
check "legacy fixture detected as legacy" test "$(detect "$LEGACY/.mindlayer")" = "legacy"
check "target fixture detected as target" test "$(detect "$TARGET/.mindlayer")" = "target"

scenario "boot reads the legacy layout"
legacy_boot="$SANDBOX/legacy-boot.out"
(cd "$LEGACY" && HOME="$SANDBOX/home" python3 "$ROOT_DIR/src/ml" boot > "$legacy_boot" 2>/dev/null)
check "cites pipeline/progress.md" assert_contains "$legacy_boot" ".mindlayer/pipeline/progress.md"
check "does not cite work/current.md" assert_not_contains "$legacy_boot" ".mindlayer/work/current.md"

scenario "boot reads the target layout"
target_boot="$SANDBOX/target-boot.out"
(cd "$TARGET" && HOME="$SANDBOX/home" python3 "$ROOT_DIR/src/ml" boot > "$target_boot" 2>/dev/null)
check "cites work/current.md" assert_contains "$target_boot" ".mindlayer/work/current.md"
check "does not cite pipeline/progress.md" assert_not_contains "$target_boot" ".mindlayer/pipeline/progress.md"

scenario "empty target sessions dir does not shadow legacy history"
# Partial migration: a target work/sessions/ exists but is empty, while real
# session history still lives in legacy knowledge/sessions/. Reads must find it.
MIXED="$SANDBOX/mixed"
mkdir -p "$MIXED/.mindlayer/knowledge/sessions" "$MIXED/.mindlayer/work/sessions" "$MIXED/.mindlayer/pipeline/archive"
git -C "$MIXED" init -q
cat > "$MIXED/.mindlayer/index.md" <<'EOF'
# Project Memory Index

- ml-project-test | Project Identity | project.md | Mixed layout project.
EOF
cat > "$MIXED/.mindlayer/knowledge/project.md" <<'EOF'
# Project

## Project Identity

### Summary
Mixed layout project identity.
EOF
cat > "$MIXED/.mindlayer/pipeline/progress.md" <<'EOF'
# Progress

## Current Phase

### Summary
Mixed progress state.
EOF
: > "$MIXED/.mindlayer/pipeline/backlog.md"
cat > "$MIXED/.mindlayer/knowledge/sessions/2026-06-30.md" <<'EOF'
# Session: 2026-06-30

## Commit
0000000000000000000000000000000000000000

## Next
- resume the mixed-layout migration
EOF
mixed_boot="$SANDBOX/mixed-boot.out"
(cd "$MIXED" && HOME="$SANDBOX/home" python3 "$ROOT_DIR/src/ml" boot > "$mixed_boot" 2>/dev/null)
check "latest Next cue recovered from legacy history" assert_contains "$mixed_boot" "resume the mixed-layout migration"
check "session load line reports actual legacy source" assert_contains "$mixed_boot" 'latest `.mindlayer/knowledge/sessions/2026-06-30.md`'

scenario "status reports the resolved archive path per layout"
legacy_status="$SANDBOX/legacy-status.out"
target_status="$SANDBOX/target-status.out"
(cd "$LEGACY" && HOME="$SANDBOX/home" python3 "$ROOT_DIR/src/ml" status > "$legacy_status" 2>/dev/null)
(cd "$TARGET" && HOME="$SANDBOX/home" python3 "$ROOT_DIR/src/ml" status > "$target_status" 2>/dev/null)
check "legacy archive path" assert_contains "$legacy_status" "in pipeline/archive/archive.md"
check "target archive path" assert_contains "$target_status" "in archive/archive.md"

printf "\nSummary: %s passed, %s failed\n" "$PASS_COUNT" "$FAIL_COUNT"
[ "$FAIL_COUNT" -eq 0 ]
