#!/usr/bin/env bash
# Regression guard: every command refactored for the dual-layout seam still runs
# green on an existing (legacy) install. Proves Step 2a is byte-compatible for
# projects that have not migrated.

set -u

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
SANDBOX="${TMPDIR:-/tmp}/mindlayer-migration-compat.$$"
PASS_COUNT=0
FAIL_COUNT=0
CURRENT_SCENARIO=""

pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf "PASS  %s\n" "$1"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); printf "FAIL  %s\n" "$1"; }
scenario() { CURRENT_SCENARIO="$1"; printf "\n## %s\n" "$1"; }
assert_contains() { grep -Fq "$2" "$1"; }
check() {
  label="$1"; shift
  if "$@" 2>/dev/null; then pass "$CURRENT_SCENARIO: $label"; else fail "$CURRENT_SCENARIO: $label"; fi
}
cleanup() { rm -rf "$SANDBOX"; }
trap cleanup EXIT

mkdir -p "$SANDBOX/home/.mindlayer/memory-system" "$SANDBOX/home/.mindlayer/preferences"
: > "$SANDBOX/home/.mindlayer/boot.md"
: > "$SANDBOX/home/.mindlayer/router.md"
: > "$SANDBOX/home/.mindlayer/memory-system/per-turn.md"

P="$SANDBOX/project"
mkdir -p "$P/.mindlayer/knowledge/sessions" "$P/.mindlayer/pipeline/archive"
cat > "$P/.mindlayer/index.md" <<'EOF'
# Project Memory Index

- ml-project-test | Project Identity | project.md | Legacy compat project.
EOF
cat > "$P/.mindlayer/knowledge/project.md" <<'EOF'
# Project

## Project Identity

### Summary
Legacy compat project identity.
EOF
cat > "$P/.mindlayer/pipeline/progress.md" <<'EOF'
# Progress

## Current Phase

### Summary
Legacy progress.

- Next: keep shipping.
EOF
cat > "$P/.mindlayer/pipeline/backlog.md" <<'EOF'
# Backlog
EOF

run_ml() { (cd "$P" && HOME="$SANDBOX/home" python3 "$ROOT_DIR/src/ml" "$@"); }

printf "MindLayer legacy compatibility\n"
printf "==============================\n"

scenario "refactored commands exit 0 on a legacy install"
check "boot exits 0" run_ml boot
check "status exits 0" run_ml status
check "diff exits 0" run_ml diff
check "session exits 0" run_ml session --words 1000

scenario "boot output keeps the legacy shape"
out="$SANDBOX/boot.out"
run_ml boot > "$out" 2>/dev/null
check "loads pipeline/progress.md" assert_contains "$out" ".mindlayer/pipeline/progress.md"
check "loads pipeline/backlog.md" assert_contains "$out" ".mindlayer/pipeline/backlog.md"
check "context loaded banner" assert_contains "$out" "MindLayer context loaded."

scenario "session write targets the legacy sessions dir"
swrite="$SANDBOX/session-write.out"
run_ml session write --date 2026-07-01 --worked-on "compat" --next "next" > "$swrite" 2>/dev/null
check "destination is knowledge/sessions" assert_contains "$swrite" ".mindlayer/knowledge/sessions/2026-07-01.md"

scenario "write policy co-locates with legacy history even if target dir exists"
# Partial migration: an empty work/sessions/ must not capture new writes while
# legacy history exists. session_write_dir keeps writes with existing history.
mkdir -p "$P/.mindlayer/work/sessions"
swrite2="$SANDBOX/session-write2.out"
run_ml session write --date 2026-07-02 --worked-on "compat" --next "next" > "$swrite2" 2>/dev/null
check "destination stays knowledge/sessions" assert_contains "$swrite2" ".mindlayer/knowledge/sessions/2026-07-02.md"
rmdir "$P/.mindlayer/work/sessions" "$P/.mindlayer/work" 2>/dev/null || true

printf "\nSummary: %s passed, %s failed\n" "$PASS_COUNT" "$FAIL_COUNT"
[ "$FAIL_COUNT" -eq 0 ]
