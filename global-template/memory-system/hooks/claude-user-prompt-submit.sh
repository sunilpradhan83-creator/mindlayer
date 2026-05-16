#!/usr/bin/env bash
set -eu

cat <<'JSON'
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "MindLayer per-turn reminder: end this response with the exact Token Burned status block from ~/.mindlayer/memory-system/per-turn.md, including Last turn, Session, and a nonblank Next Step. This reminder is injected every user turn because per-turn behavior is a hard MindLayer contract."
  }
}
JSON
