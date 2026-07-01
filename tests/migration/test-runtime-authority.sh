#!/usr/bin/env bash
# ADR-0001 runtime authority guard: core `ml` commands must work from executable
# runtime + project memory even when global markdown control-plane files are absent.

set -u

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
SANDBOX="${TMPDIR:-/tmp}/mindlayer-runtime-authority.$$"
SEED="$ROOT_DIR/seed/project"
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

P="$SANDBOX/project"
HOME_DIR="$SANDBOX/home"
mkdir -p "$P/.mindlayer" "$HOME_DIR/.mindlayer/preferences"
cp -R "$SEED/." "$P/.mindlayer/"

run_ml() { (cd "$P" && HOME="$HOME_DIR" python3 "$ROOT_DIR/src/ml" "$@"); }

printf "MindLayer executable runtime authority\n"
printf "======================================\n"

scenario "core commands run without global runtime markdown"
boot_out="$SANDBOX/boot.out"
status_out="$SANDBOX/status.out"
load_out="$SANDBOX/load.out"
session_out="$SANDBOX/session.out"

run_ml boot > "$boot_out" 2>&1
check "boot exits 0" test $? -eq 0
run_ml status > "$status_out" 2>&1
check "status exits 0" test $? -eq 0
run_ml load "Current State" > "$load_out" 2>&1
check "load exits 0" test $? -eq 0
run_ml session --words 1000 > "$session_out" 2>&1
check "session exits 0" test $? -eq 0

check "boot reports project context" assert_contains "$boot_out" "MindLayer context loaded."
check "boot cites target current work" assert_contains "$boot_out" ".mindlayer/work/current.md"
check "boot treats missing globals as non-fatal" assert_contains "$boot_out" "~/.mindlayer/boot.md"
check "boot has no traceback" assert_not_contains "$boot_out" "Traceback"
check "status reports target archive path" assert_contains "$status_out" "in archive/archive.md"
check "load resolves current state" assert_contains "$load_out" "Current State"
check "session reports context" assert_contains "$session_out" "Session context:"

scenario "global runtime markdown remains absent"
check "no global boot.md required" test ! -e "$HOME_DIR/.mindlayer/boot.md"
check "no global router.md required" test ! -e "$HOME_DIR/.mindlayer/router.md"
check "no global memory-system required" test ! -d "$HOME_DIR/.mindlayer/memory-system"

printf "\nSummary: %s passed, %s failed\n" "$PASS_COUNT" "$FAIL_COUNT"
[ "$FAIL_COUNT" -eq 0 ]
