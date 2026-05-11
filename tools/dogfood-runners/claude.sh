#!/usr/bin/env bash
# Claude Code runner for dogfood-boot.sh (product gate).
#
# Supports true multi-turn sessions via --resume session_id.
# Auth: real HOME OAuth credentials (VSCode extension binary does not support
# ANTHROPIC_API_KEY — OAuth is the only supported auth method).
# Project is fully sandboxed via AGENT_CWD.
#
# Called as: claude.sh <prompt> <output_file> <log_file> [session_id]
# Prints session_id to stdout on success.
#
# Required env (set by dogfood-boot.sh):
#   REAL_HOME   - real HOME for OAuth auth
#   SANDBOX     - path to sandbox directory
#   AGENT_CWD   - working directory (sandbox project)

set -eu

PROMPT="$1"
OUTPUT_FILE="$2"
LOG_FILE="$3"
SESSION_ID="${4:-}"

CLAUDE_BIN="${CLAUDE_BIN:-claude}"

if ! command -v "$CLAUDE_BIN" >/dev/null 2>&1; then
  printf "FAIL  Claude binary not found: %s\n" "$CLAUDE_BIN" >&2
  exit 1
fi

RESUME_FLAG=""
if [ -n "$SESSION_ID" ]; then
  RESUME_FLAG="--resume $SESSION_ID"
fi

result=$(
  cd "$AGENT_CWD" && \
  HOME="$REAL_HOME" \
  "$CLAUDE_BIN" -p "$PROMPT" \
    $RESUME_FLAG \
    --output-format json \
    --dangerously-skip-permissions \
    2>"$LOG_FILE"
)

echo "$result" | python3 -c "
import sys, json
d = json.load(sys.stdin)
result_text = d.get('result', '')
session_id = d.get('session_id', '')
open('$OUTPUT_FILE', 'w').write(result_text)
print(session_id)
"
