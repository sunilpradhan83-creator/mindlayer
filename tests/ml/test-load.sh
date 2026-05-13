#!/usr/bin/env bash
# CLI contract tests for `ml load`.

set -u

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
SANDBOX="${TMPDIR:-/tmp}/mindlayer-ml-load-test.$$"
PASS_COUNT=0
FAIL_COUNT=0
CURRENT_SCENARIO=""

pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf "PASS  %s\n" "$1"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); printf "FAIL  %s\n" "$1"; }
scenario() { CURRENT_SCENARIO="$1"; printf "\n## %s\n" "$CURRENT_SCENARIO"; }
assert_contains() { grep -Fq "$2" "$1"; }
assert_top_score_at_least_50() {
  awk '/^  1\./ { if ($0 ~ /score [5-9][0-9]/ || $0 ~ /score [1-9][0-9][0-9]/) found = 1 } END { exit found ? 0 : 1 }' "$1"
}

cleanup() { rm -rf "$SANDBOX"; }
trap cleanup EXIT

mkdir -p "$SANDBOX/project/.mindlayer" "$SANDBOX/project/global-template/memory-system/per-turn"
cat > "$SANDBOX/project/.mindlayer/index-full.md" <<'EOF'
# Full Index

- id: ml-command-runner
  title: Command Runner
  file: context.md
  section: Command Runner
  scope: project
  type: context
  status: active
  last_updated: 2026-05-12
  tags: [command, runner]
  importance: high
  summary: Read-only ml command runner foundation.
- id: ml-old-command-runner
  title: Old Command Runner
  file: archive.md
  section: Old Command Runner
  scope: project
  type: context
  status: archived
  last_updated: 2026-01-01
  tags: [command, runner]
  importance: low
  summary: Archived command runner idea.
- id: ml-post-write-module
  title: Per-Turn Post-Write Module
  file: global-template/memory-system/per-turn/post-write.md
  section: Post-Write Size Module
  scope: project
  type: context
  status: active
  last_updated: 2026-05-12
  tags: [post-write, module]
  importance: high
  summary: Lazy per-turn contract for checking memory file size after approved writes.
EOF
cat > "$SANDBOX/project/.mindlayer/index.md" <<'EOF'
# Project Memory Index
EOF
cat > "$SANDBOX/project/.mindlayer/context.md" <<'EOF'
# Context

## Command Runner

### Summary
Read-only ml command runner foundation.
EOF
cat > "$SANDBOX/project/.mindlayer/archive.md" <<'EOF'
# Archive

## Old Command Runner

### Summary
Archived command runner idea.
EOF
cat > "$SANDBOX/project/global-template/memory-system/per-turn/post-write.md" <<'EOF'
# Post-Write Size Module

Load after an approved memory write to a committed MindLayer memory file.
EOF

printf "MindLayer ml load contract\n"
printf "==========================\n"

scenario "exact title ranking"
output="$SANDBOX/load.out"
if (cd "$SANDBOX/project" && HOME="$SANDBOX/home" python3 "$ROOT_DIR/src/ml" load "Command Runner" > "$output"); then
  pass "$CURRENT_SCENARIO: command exits successfully"
else
  fail "$CURRENT_SCENARIO: command exits successfully"
fi
if assert_contains "$output" "Query: Command Runner"; then pass "$CURRENT_SCENARIO: query printed"; else fail "$CURRENT_SCENARIO: query printed"; fi
if assert_contains "$output" "1. Command Runner (ml-command-runner)"; then pass "$CURRENT_SCENARIO: exact title is top result"; else fail "$CURRENT_SCENARIO: exact title is top result"; fi
if assert_top_score_at_least_50 "$output"; then pass "$CURRENT_SCENARIO: top score at least 50"; else fail "$CURRENT_SCENARIO: top score at least 50"; fi
if ! grep -Fq "Old Command Runner (ml-old-command-runner)" "$output"; then pass "$CURRENT_SCENARIO: archived excluded by default"; else fail "$CURRENT_SCENARIO: archived excluded by default"; fi

scenario "repo-relative source path"
output="$SANDBOX/load-template.out"
if (cd "$SANDBOX/project" && HOME="$SANDBOX/home" python3 "$ROOT_DIR/src/ml" load "post write module" > "$output"); then
  pass "$CURRENT_SCENARIO: command exits successfully"
else
  fail "$CURRENT_SCENARIO: command exits successfully"
fi
if assert_contains "$output" "Per-Turn Post-Write Module"; then pass "$CURRENT_SCENARIO: module ranked"; else fail "$CURRENT_SCENARIO: module ranked"; fi
if assert_contains "$output" "$SANDBOX/project/global-template/memory-system/per-turn/post-write.md"; then pass "$CURRENT_SCENARIO: source resolves outside .mindlayer"; else fail "$CURRENT_SCENARIO: source resolves outside .mindlayer"; fi
if ! grep -Fq "Section not found." "$output"; then pass "$CURRENT_SCENARIO: section found"; else fail "$CURRENT_SCENARIO: section found"; fi

printf "\nSummary: %s passed, %s failed\n" "$PASS_COUNT" "$FAIL_COUNT"
[ "$FAIL_COUNT" -eq 0 ]
