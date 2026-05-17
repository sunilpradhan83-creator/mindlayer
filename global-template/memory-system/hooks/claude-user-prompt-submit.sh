#!/usr/bin/env bash
set -eu

cat <<'JSON'
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "MindLayer per-turn reminder: end this response with the exact Token Burned status block from ~/.mindlayer/memory-system/per-turn.md, including Last turn, Session, and a nonblank Next Step. If the user prompt is `ml boot` or `ml init`, treat it as a MindLayer command, not as machine learning: read ~/.mindlayer/boot.md first, run the full boot sequence, and emit the boot receipt without asking for clarification. This reminder is injected every user turn because per-turn and command recognition are hard MindLayer contracts."
  }
}
JSON
