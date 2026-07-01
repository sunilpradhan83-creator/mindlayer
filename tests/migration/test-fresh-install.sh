#!/usr/bin/env bash
# Guards that fresh project seeds use the ADR-0001 target work/ layout.
# Legacy pipeline/ fixtures remain covered by the migration compatibility tests.

set -u

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
SANDBOX="${TMPDIR:-/tmp}/mindlayer-fresh-install.$$"
SEED="$ROOT_DIR/seed/project"
PASS_COUNT=0
FAIL_COUNT=0
CURRENT_SCENARIO=""

pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf "PASS  %s\n" "$1"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); printf "FAIL  %s\n" "$1"; }
scenario() { CURRENT_SCENARIO="$1"; printf "\n## %s\n" "$1"; }
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

printf "MindLayer fresh-install layout guard\n"
printf "====================================\n"

scenario "shipped seed is target-shaped"
check "seed has work/current.md" test -f "$SEED/work/current.md"
check "seed has work/index.md" test -f "$SEED/work/index.md"
check "seed has archive/index.md" test -f "$SEED/archive/index.md"
check "seed has no pipeline/progress.md" test ! -f "$SEED/pipeline/progress.md"
check "seed has no pipeline/backlog.md" test ! -f "$SEED/pipeline/backlog.md"
check "seed has no pipeline/index.md" test ! -f "$SEED/pipeline/index.md"
check "seed has no pipeline/ dir" test ! -d "$SEED/pipeline"
check "seed has no archive/archive.md" test ! -f "$SEED/archive/archive.md"

scenario "a project built from the seed detects as target"
mkdir -p "$SANDBOX/home/.mindlayer/memory-system" "$SANDBOX/home/.mindlayer/preferences"
: > "$SANDBOX/home/.mindlayer/boot.md"
: > "$SANDBOX/home/.mindlayer/router.md"
: > "$SANDBOX/home/.mindlayer/memory-system/per-turn.md"
P="$SANDBOX/project"
mkdir -p "$P/.mindlayer"
cp -R "$SEED/." "$P/.mindlayer/"
check "detected as target" test "$(detect "$P/.mindlayer")" = "target"
check "boot exits 0 on fresh seed" sh -c "cd '$P' && HOME='$SANDBOX/home' python3 '$ROOT_DIR/src/ml' boot >/dev/null 2>&1"

printf "\nSummary: %s passed, %s failed\n" "$PASS_COUNT" "$FAIL_COUNT"
[ "$FAIL_COUNT" -eq 0 ]
