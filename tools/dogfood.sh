#!/usr/bin/env bash
# MindLayer dogfood check — verifies agent boot behavior against a sandboxed project.
#
# Simulates real multi-turn chat to verify MindLayer boots correctly, respects
# source boundaries, maintains session continuity, and does not write memory
# without approval.
#
# Isolation: project memory is fully sandboxed (fresh install in /tmp).
# Global memory (~/.mindlayer/) and agent auth use the real HOME — this is a
# live health check against your installed config, not a fully isolated product gate.
#
# Session continuity (scenario 3) is skipped automatically for single-turn runners
# like Codex that do not support multi-turn sessions.
#
# Usage:
#   tools/dogfood.sh
#   AGENT_RUNNER=tools/dogfood-runners/codex.sh tools/dogfood.sh
#
# Options (env vars):
#   AGENT_RUNNER     Path to runner script (default: tools/dogfood-runners/claude.sh)
#   KEEP_TEST_DIR=1  Keep sandbox after run for inspection
#   CLAUDE_BIN       Override claude binary path (default: claude)

set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
SANDBOX="${TMPDIR:-/tmp}/mindlayer-live.$$"
KEEP_TEST_DIR="${KEEP_TEST_DIR:-0}"
AGENT_RUNNER="${AGENT_RUNNER:-tools/dogfood-runners/claude.sh}"

export SANDBOX
export REAL_HOME="$HOME"
export AGENT_HOME_DIR="$SANDBOX/home"
export AGENT_CWD="$SANDBOX/project"

# ── helpers ──────────────────────────────────────────────────────────────────

cleanup() {
  if [ "$KEEP_TEST_DIR" = "1" ]; then
    printf "\nKept sandbox: %s\n" "$SANDBOX"
  else
    rm -rf "$SANDBOX"
  fi
}

pass() { printf "PASS  %s\n" "$1"; }
fail() { printf "FAIL  %s\n" "$1" >&2; }

assert_contains() {
  file="$1"; pattern="$2"
  grep -Fq "$pattern" "$file"
}

assert_not_contains() {
  file="$1"; pattern="$2"
  ! grep -Fq "$pattern" "$file"
}

run_turn() {
  local session_id="$1"
  local prompt="$2"
  local output_file="$3"
  local log_file="$4"
  bash "$AGENT_RUNNER" "$prompt" "$output_file" "$log_file" "$session_id"
}

# ── preflight ─────────────────────────────────────────────────────────────────

if [ ! -f "$ROOT_DIR/$AGENT_RUNNER" ] && [ ! -f "$AGENT_RUNNER" ]; then
  printf "ERROR  Runner not found: %s\n" "$AGENT_RUNNER" >&2
  exit 1
fi

if [ -f "$ROOT_DIR/$AGENT_RUNNER" ]; then
  AGENT_RUNNER="$ROOT_DIR/$AGENT_RUNNER"
fi

AGENT_NAME="$(basename "$AGENT_RUNNER" .sh)"

trap cleanup EXIT
mkdir -p "$SANDBOX/home" "$SANDBOX/project"

printf "MindLayer Dogfood Check\n"
printf "=======================\n"
printf "Agent:   %s\n" "$AGENT_NAME"
printf "Runner:  %s\n" "$AGENT_RUNNER"
printf "Sandbox: %s\n\n" "$SANDBOX"

# ── install MindLayer into sandbox project only ───────────────────────────────

HOME="$SANDBOX/home" bash "$ROOT_DIR/install.sh" \
  --project "$SANDBOX/project" \
  --no-onboard >/dev/null

# Inject test fixtures into sandbox project only
FIXTURES_DIR="$ROOT_DIR/tools/dogfood-fixtures"
cp "$FIXTURES_DIR/project.md" "$SANDBOX/project/.mindlayer/knowledge/project.md"
cp "$FIXTURES_DIR/index.md"   "$SANDBOX/project/.mindlayer/index.md"
pass "MindLayer installed into sandbox project (global reads from real ~/.mindlayer/)"

# ── scenario 1: greeting does not trigger boot ────────────────────────────────

printf "\nScenario 1: Greeting does not trigger MindLayer boot\n"
printf "%s\n" "-----------------------------------------------------"

s1_response="$SANDBOX/s1-hi.md"
s1_log="$SANDBOX/s1-hi.log"

SESSION_ID=$(run_turn "" "hi" "$s1_response" "$s1_log") || {
  fail "agent call failed for greeting"
  [ -f "$s1_log" ] && sed -n '1,40p' "$s1_log" >&2 || true
  exit 1
}
pass "agent responded to greeting"

if assert_not_contains "$s1_response" "MindLayer context loaded."; then
  pass "greeting did not emit MindLayer boot receipt"
else
  fail "greeting emitted MindLayer boot receipt (should not boot on plain greeting)"
  sed -n '1,60p' "$s1_response" >&2
  exit 1
fi

# ── scenario 2: project question triggers boot (continues session 1) ──────────

printf "\nScenario 2: Project question triggers boot receipt\n"
printf "%s\n" "--------------------------------------------------"

s2_response="$SANDBOX/s2-project.md"
s2_log="$SANDBOX/s2-project.log"

SESSION_ID=$(run_turn "$SESSION_ID" "what is this project?" "$s2_response" "$s2_log") || {
  fail "agent call failed for project question"
  [ -f "$s2_log" ] && sed -n '1,40p' "$s2_log" >&2 || true
  exit 1
}
pass "agent responded to project question"

if assert_contains "$s2_response" "MindLayer context loaded."; then
  pass "project question emitted MindLayer boot receipt"
else
  fail "project question did not emit MindLayer boot receipt"
  sed -n '1,80p' "$s2_response" >&2
  exit 1
fi

if assert_contains "$s2_response" "~/.mindlayer/boot.md"; then
  pass "boot receipt loaded ~/.mindlayer/boot.md"
else
  fail "boot receipt did not list ~/.mindlayer/boot.md"
  sed -n '1,80p' "$s2_response" >&2
  exit 1
fi

if assert_contains "$s2_response" "~/.mindlayer/router.md"; then
  pass "boot receipt loaded ~/.mindlayer/router.md"
else
  fail "boot receipt did not list ~/.mindlayer/router.md"
  sed -n '1,80p' "$s2_response" >&2
  exit 1
fi

if awk '
  /^(Loaded:|[*][*]Loaded:[*][*])/ { in_loaded=1; next }
  /^(Skipped:|Missing:|[*][*]Skipped:|[*][*]Missing:)/ { in_loaded=0 }
  in_loaded && /(README\.md|docs\/)/ { found=1 }
  END { exit found ? 1 : 0 }
' "$s2_response"; then
  pass "boot receipt did not load README.md or docs/ (source boundary respected)"
else
  fail "boot receipt loaded README.md or docs/ in Loaded section (source boundary violated)"
  sed -n '1,80p' "$s2_response" >&2
  exit 1
fi

# ── scenario 3: session continuity ───────────────────────────────────────────

printf "\nScenario 3: Session continuity across turns\n"
printf "%s\n" "-------------------------------------------"

if [ -z "$SESSION_ID" ]; then
  printf "SKIP  runner does not support multi-turn sessions (single-turn only)\n"
else
  s3_response="$SANDBOX/s3-memory.md"
  s3_log="$SANDBOX/s3-memory.log"

  SESSION_ID=$(run_turn "$SESSION_ID" "what did I ask you first in this session?" "$s3_response" "$s3_log") || {
    fail "agent call failed for continuity check"
    [ -f "$s3_log" ] && sed -n '1,40p' "$s3_log" >&2 || true
    exit 1
  }
  pass "agent responded to continuity question"

  if assert_contains "$s3_response" "hi"; then
    pass "agent remembered first message (session continuity working)"
  else
    fail "agent did not recall first message — session continuity broken"
    sed -n '1,60p' "$s3_response" >&2
    exit 1
  fi
fi

# ── scenario 4: fresh session boots correctly ─────────────────────────────────

printf "\nScenario 4: Fresh session — project question as first turn\n"
printf "%s\n" "----------------------------------------------------------"

s4_response="$SANDBOX/s4-fresh.md"
s4_log="$SANDBOX/s4-fresh.log"

FRESH_SESSION=$(run_turn "" "what is this project?" "$s4_response" "$s4_log") || {
  fail "agent call failed for fresh project question"
  [ -f "$s4_log" ] && sed -n '1,40p' "$s4_log" >&2 || true
  exit 1
}
pass "agent responded to fresh project question"

if assert_contains "$s4_response" "MindLayer context loaded."; then
  pass "fresh session booted on first project-relevant prompt"
else
  fail "fresh session did not boot on first project-relevant prompt"
  sed -n '1,80p' "$s4_response" >&2
  exit 1
fi

# ── scenario 5: no unsolicited memory write ───────────────────────────────────

printf "\nScenario 5: No unsolicited memory write\n"
printf "%s\n" "---------------------------------------"

s5_response="$SANDBOX/s5-nomemwrite.md"
s5_log="$SANDBOX/s5-nomemwrite.log"

snapshot_before=$(find "$REAL_HOME/.mindlayer" "$SANDBOX/project/.mindlayer" -type f 2>/dev/null | sort | xargs md5sum 2>/dev/null)

run_turn "$FRESH_SESSION" "show me the files in this project" "$s5_response" "$s5_log" >/dev/null || {
  fail "agent call failed for memory write check"
  [ -f "$s5_log" ] && sed -n '1,40p' "$s5_log" >&2 || true
  exit 1
}

snapshot_after=$(find "$REAL_HOME/.mindlayer" "$SANDBOX/project/.mindlayer" -type f 2>/dev/null | sort | xargs md5sum 2>/dev/null)

if [ "$snapshot_before" = "$snapshot_after" ]; then
  pass "no unsolicited memory write (file contents unchanged)"
else
  fail "agent modified memory without approval"
  diff <(echo "$snapshot_before") <(echo "$snapshot_after") >&2
  exit 1
fi

# ── verdict ───────────────────────────────────────────────────────────────────

printf "\nVerdict: MINDLAYER DOGFOOD PASSED (%s)\n" "$AGENT_NAME"
