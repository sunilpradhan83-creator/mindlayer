#!/usr/bin/env bash
# Verifies the read-only adapter status detector (_adapters): match / mismatch /
# unverified classification against adapters.lock, and that it performs NO writes.

set -u

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
SANDBOX="${TMPDIR:-/tmp}/mindlayer-adapter-guard.$$"
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

astatus() {
  PYTHONPATH="$ROOT_DIR/src" python3 -c \
    "import sys; from pathlib import Path; from commands._adapters import adapter_status
for s in adapter_status(Path(sys.argv[1])):
    print(s.name, s.state)" "$1"
}

P="$SANDBOX/project"
mkdir -p "$P/.mindlayer"
printf 'AGENTS adapter\n' > "$P/AGENTS.md"
printf 'CLAUDE adapter\n' > "$P/CLAUDE.md"

write_lock() {
  {
    printf "AGENTS.md=%s\n" "$(sha256sum "$P/AGENTS.md" | cut -d' ' -f1)"
    printf "CLAUDE.md=%s\n" "$(sha256sum "$P/CLAUDE.md" | cut -d' ' -f1)"
  } > "$P/.mindlayer/adapters.lock"
}

printf "MindLayer adapter status detector\n"
printf "=================================\n"

scenario "matching adapters report match"
write_lock
out="$SANDBOX/match.out"
astatus "$P" > "$out"
check "AGENTS.md match" assert_contains "$out" "AGENTS.md match"
check "CLAUDE.md match" assert_contains "$out" "CLAUDE.md match"
check "absent adapter reported absent" assert_contains "$out" "GEMINI.md absent"

scenario "tampered adapter reports mismatch"
printf 'CLAUDE adapter TAMPERED\n' > "$P/CLAUDE.md"
out="$SANDBOX/mismatch.out"
astatus "$P" > "$out"
check "CLAUDE.md mismatch" assert_contains "$out" "CLAUDE.md mismatch"
check "AGENTS.md still match" assert_contains "$out" "AGENTS.md match"

scenario "missing lock entry reports unverified"
write_lock
printf 'AGENTS.md=%s\n' "$(sha256sum "$P/AGENTS.md" | cut -d' ' -f1)" > "$P/.mindlayer/adapters.lock"
out="$SANDBOX/unverified.out"
astatus "$P" > "$out"
check "CLAUDE.md unverified" assert_contains "$out" "CLAUDE.md unverified"

scenario "detector performs no writes"
write_lock
before_lock="$(sha256sum "$P/.mindlayer/adapters.lock" | cut -d' ' -f1)"
before_agents="$(sha256sum "$P/AGENTS.md" | cut -d' ' -f1)"
astatus "$P" > /dev/null
after_lock="$(sha256sum "$P/.mindlayer/adapters.lock" | cut -d' ' -f1)"
after_agents="$(sha256sum "$P/AGENTS.md" | cut -d' ' -f1)"
check "adapters.lock unchanged" test "$before_lock" = "$after_lock"
check "AGENTS.md unchanged" test "$before_agents" = "$after_agents"

scenario "status surfaces adapter drift read-only"
mkdir -p "$SANDBOX/home/.mindlayer/memory-system" "$SANDBOX/home/.mindlayer/preferences"
: > "$SANDBOX/home/.mindlayer/boot.md"
: > "$SANDBOX/home/.mindlayer/router.md"
: > "$SANDBOX/home/.mindlayer/memory-system/per-turn.md"
mkdir -p "$P/.mindlayer/knowledge" "$P/.mindlayer/pipeline"
cat > "$P/.mindlayer/index.md" <<'EOF'
# Project Memory Index
EOF
cat > "$P/.mindlayer/knowledge/project.md" <<'EOF'
# Project

## Project Identity

### Summary
Adapter drift project.
EOF
cat > "$P/.mindlayer/pipeline/progress.md" <<'EOF'
# Progress

## Current Phase

### Summary
Progress.
EOF
printf 'CLAUDE adapter TAMPERED\n' > "$P/CLAUDE.md"
write_lock
printf 'CLAUDE adapter DRIFTED\n' > "$P/CLAUDE.md"
status_out="$SANDBOX/status.out"
(cd "$P" && HOME="$SANDBOX/home" python3 "$ROOT_DIR/src/ml" status > "$status_out" 2>/dev/null)
check "status prints Adapters block" assert_contains "$status_out" "Adapters:"
check "status flags mismatch" assert_contains "$status_out" "MISMATCH: CLAUDE.md"

printf "\nSummary: %s passed, %s failed\n" "$PASS_COUNT" "$FAIL_COUNT"
[ "$FAIL_COUNT" -eq 0 ]
