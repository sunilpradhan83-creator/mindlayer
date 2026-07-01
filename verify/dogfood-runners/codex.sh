#!/usr/bin/env bash
# Codex CLI runner for dogfood-boot.sh.
#
# Codex exec is always single-turn and ephemeral — no session continuity.
# Each call is a fresh session. Multi-turn scenarios run as separate sessions.
#
# Called as: codex.sh <prompt> <output_file> <log_file> [session_id]
# Prints empty string to stdout (no session continuity support).
#
# Required env (set by dogfood-boot.sh):
#   SANDBOX         - path to sandbox directory
#   AGENT_HOME_DIR  - HOME override (sandbox home for isolation)
#   AGENT_CWD       - working directory (sandbox project)

set -eu

PROMPT="$1"
OUTPUT_FILE="$2"
LOG_FILE="$3"
# session_id intentionally ignored — codex exec is always ephemeral

CODEX_BIN="${CODEX_BIN:-codex}"
CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"

if ! command -v "$CODEX_BIN" >/dev/null 2>&1; then
  printf "FAIL  Codex binary not found: %s\n" "$CODEX_BIN" >&2
  exit 1
fi

if [ "$(uname -s)" = "Linux" ] && ! command -v bwrap >/dev/null 2>&1; then
  printf "FAIL  Codex Linux sandbox requires bubblewrap (bwrap), but it was not found on PATH.\n" >&2
  printf "      Install it with your system package manager, for example:\n" >&2
  printf "      sudo apt install bubblewrap\n" >&2
  exit 1
fi

HOME="$AGENT_HOME_DIR" \
CODEX_HOME="$CODEX_HOME_DIR" \
"$CODEX_BIN" -a never exec \
  --cd "$AGENT_CWD" \
  --sandbox read-only \
  --ephemeral \
  --output-last-message "$OUTPUT_FILE" \
  "$PROMPT" > "$LOG_FILE" 2>&1

# No session ID — codex exec does not support multi-turn continuity
printf ""
