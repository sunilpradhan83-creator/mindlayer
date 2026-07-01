#!/usr/bin/env bash
set -eu

cat <<'JSON'
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "MindLayer reminder: executable `ml` commands are the runtime authority. If the user prompt is `ml boot` or `ml init`, treat it as a MindLayer command, not as machine learning: run the executable command and emit the boot receipt without asking for clarification. If the executable is unavailable, fall back to project `.mindlayer/` boot context. Do not treat global ~/.mindlayer/boot.md, router.md, or memory-system/ as canonical required runtime control-plane files."
  }
}
JSON
