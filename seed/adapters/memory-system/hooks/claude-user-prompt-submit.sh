#!/usr/bin/env bash
set -eu

cat <<'JSON'
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "MindLayer per-turn reminder: end this response with a Markdown horizontal rule, then Token Burned: as normal text, a blank line, exactly two bullet lines for Last turn and Session estimates using ~N words, ~N est. tokens, then a bold Next Step label and the smallest useful action. Do not use Markdown headings or code formatting in that status block. Executable `ml` commands remain the runtime authority. If the user prompt is `ml boot` or `ml init`, treat it as a MindLayer command, not as machine learning: run the executable command and emit the boot receipt without asking for clarification. If the executable is unavailable, fall back to project `.mindlayer/` boot context. Do not treat global ~/.mindlayer/boot.md, router.md, or memory-system/ as canonical required runtime control-plane files."
  }
}
JSON
