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

mkdir -p \
  "$SANDBOX/project/.mindlayer" \
  "$SANDBOX/project/global-template/memory-system/per-turn" \
  "$SANDBOX/project/.mindlayer/knowledge" \
  "$SANDBOX/project/.mindlayer/knowledge/decisions" \
  "$SANDBOX/project/.mindlayer/pipeline" \
  "$SANDBOX/project/.mindlayer/pipeline/archive" \
  "$SANDBOX/project/.mindlayer/knowledge/sessions"

# index-full.md — deprecated; must NOT be loaded after story-001 is implemented.
# ml-full-only has a dedicated file so the old implementation's section lookup succeeds
# (keeps existing tests clean; after story-001, this file is never loaded at all).
cat > "$SANDBOX/project/.mindlayer/index-full.md" <<'EOF'
# Full Index

- id: ml-full-only
  title: Full Only Entry
  file: knowledge/full-only.md
  section: Full Only Entry
  scope: project
  type: context
  status: active
  last_updated: 2026-05-12
  tags: [full, only]
  importance: high
  summary: Unique entry only in index-full.md; must not appear after deprecation.
EOF

# Root index — summary format with leaf entries and a pointer to knowledge/
cat > "$SANDBOX/project/.mindlayer/index.md" <<'EOF'
# Project Memory Index

- ml-index-ptr-pipeline | Pipeline Index | pipeline/index.md | Index for pipeline/ subfolder
- ml-index-ptr-knowledge | Knowledge Index | knowledge/index.md | Index for knowledge/ subfolder
EOF

# knowledge/index.md — subfolder index with leaf entries, a duplicate-id entry, and a pointer
cat > "$SANDBOX/project/.mindlayer/knowledge/index.md" <<'EOF'
# Knowledge Index

- ml-project-entry | Project Identity | knowledge/project.md | Project identity entry.
- ml-command-runner | Command Runner | knowledge/context.md | Read-only ml command runner foundation.
- ml-post-write-module | Per-Turn Post-Write Module | global-template/memory-system/per-turn/post-write.md | Lazy per-turn contract for checking memory file size after approved writes.
- ml-knowledge-entry | Knowledge Entry | knowledge/knowledge-entry.md | Entry in knowledge subfolder.
- ml-dedup-entry | Dedup First | knowledge/knowledge-entry.md | First occurrence of this id.
- ml-index-ptr-decisions | Decisions Index | knowledge/decisions/index.md | Index for decisions/ subfolder
EOF

cat > "$SANDBOX/project/.mindlayer/pipeline/index.md" <<'EOF'
# Pipeline Index

- ml-progress-entry | Current Progress | progress.md | Current progress entry.
EOF

# knowledge/decisions/index.md — leaf entries plus a second occurrence of the dedup id
cat > "$SANDBOX/project/.mindlayer/knowledge/decisions/index.md" <<'EOF'
# Decisions Index

- ml-decisions-entry | Key Decision | knowledge/decisions/decision.md | A key architectural decision.
- ml-script-v4-entry | SCRIPT V4 Entry | knowledge/decisions/script-v4.md | SCRIPT V4 lifecycle rules.
- ml-process-entry | Approval Process | knowledge/decisions/process.md | Literal approval process.
- ml-architecture-entry | Boot Architecture | knowledge/decisions/architecture.md | Boot compression architecture.
- ml-dedup-entry | Dedup Second | knowledge/decisions/decision.md | Same id as in knowledge/index.md; must be suppressed.
EOF

# Content files referenced by index entries
cat > "$SANDBOX/project/.mindlayer/knowledge/context.md" <<'EOF'
# Context

## Command Runner

### Summary
Read-only ml command runner foundation.
EOF

cat > "$SANDBOX/project/.mindlayer/knowledge/project.md" <<'EOF'
# Project

## Project Identity

### Summary
Project identity entry.
EOF

cat > "$SANDBOX/project/.mindlayer/pipeline/progress.md" <<'EOF'
# Progress

## Current Progress

### Summary
Current progress entry.
EOF

cat > "$SANDBOX/project/.mindlayer/knowledge/knowledge-entry.md" <<'EOF'
# Knowledge Entry

### Summary
Entry in knowledge subfolder.
EOF

cat > "$SANDBOX/project/.mindlayer/knowledge/decisions/decision.md" <<'EOF'
# Key Decision

### Summary
A key architectural decision.
EOF

cat > "$SANDBOX/project/.mindlayer/knowledge/decisions/script-v4.md" <<'EOF'
# SCRIPT V4 Decisions

## SCRIPT V4 Entry

### Summary
SCRIPT V4 lifecycle rules.
EOF

cat > "$SANDBOX/project/.mindlayer/knowledge/decisions/process.md" <<'EOF'
# Process Decisions

## Approval Process

### Summary
Literal approval process.
EOF

cat > "$SANDBOX/project/.mindlayer/knowledge/decisions/architecture.md" <<'EOF'
# Architecture Decisions

## Boot Architecture

### Summary
Boot compression architecture.
EOF

cat > "$SANDBOX/project/.mindlayer/knowledge/full-only.md" <<'EOF'
# Full Only Entry

### Summary
Unique entry only in index-full.md.
EOF

cat > "$SANDBOX/project/.mindlayer/pipeline/archive/archive.md" <<'EOF'
# Archive

## Old Command Runner

### Summary
Archived command runner idea.
EOF

# Heading matches summary-format title so extract_section succeeds
cat > "$SANDBOX/project/global-template/memory-system/per-turn/post-write.md" <<'EOF'
# Per-Turn Post-Write Module

Load after an approved memory write to a committed MindLayer memory file.
EOF

printf "MindLayer ml load contract\n"
printf "==========================\n"

scenario "root index is pointer-only"
if awk '
  /^- / {
    count++
    if ($0 !~ /^- ml-index-ptr-[^|]+ \| .+ \| .+\/index\.md \| .+/) bad = 1
  }
  END { exit count > 0 && !bad ? 0 : 1 }
' "$ROOT_DIR/.mindlayer/index.md"; then
  pass "$CURRENT_SCENARIO: root index contains only pointer entries"
else
  fail "$CURRENT_SCENARIO: root index contains only pointer entries"
fi

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

scenario "pointer entry resolves subfolder index"
output="$SANDBOX/load-ptr.out"
if (cd "$SANDBOX/project" && HOME="$SANDBOX/home" python3 "$ROOT_DIR/src/ml" load "Knowledge Entry" > "$output"); then
  pass "$CURRENT_SCENARIO: command exits successfully"
else
  fail "$CURRENT_SCENARIO: command exits successfully"
fi
if assert_contains "$output" "Knowledge Entry (ml-knowledge-entry)"; then pass "$CURRENT_SCENARIO: subfolder entry ranked"; else fail "$CURRENT_SCENARIO: subfolder entry ranked"; fi

scenario "root pointer resolves knowledge entry"
output="$SANDBOX/load-project.out"
if (cd "$SANDBOX/project" && HOME="$SANDBOX/home" python3 "$ROOT_DIR/src/ml" load "project" > "$output"); then
  pass "$CURRENT_SCENARIO: command exits successfully"
else
  fail "$CURRENT_SCENARIO: command exits successfully"
fi
if assert_contains "$output" "Project Identity (ml-project-entry)"; then pass "$CURRENT_SCENARIO: project entry ranked"; else fail "$CURRENT_SCENARIO: project entry ranked"; fi
if assert_contains "$output" "$SANDBOX/project/.mindlayer/knowledge/project.md"; then pass "$CURRENT_SCENARIO: project source returned"; else fail "$CURRENT_SCENARIO: project source returned"; fi

scenario "root pointer resolves pipeline entry"
output="$SANDBOX/load-progress.out"
if (cd "$SANDBOX/project" && HOME="$SANDBOX/home" python3 "$ROOT_DIR/src/ml" load "progress" > "$output"); then
  pass "$CURRENT_SCENARIO: command exits successfully"
else
  fail "$CURRENT_SCENARIO: command exits successfully"
fi
if assert_contains "$output" "Current Progress (ml-progress-entry)"; then pass "$CURRENT_SCENARIO: progress entry ranked"; else fail "$CURRENT_SCENARIO: progress entry ranked"; fi
if assert_contains "$output" "$SANDBOX/project/.mindlayer/pipeline/progress.md"; then pass "$CURRENT_SCENARIO: progress source returned"; else fail "$CURRENT_SCENARIO: progress source returned"; fi

scenario "two-level pointer chain resolves"
output="$SANDBOX/load-chain.out"
if (cd "$SANDBOX/project" && HOME="$SANDBOX/home" python3 "$ROOT_DIR/src/ml" load "Key Decision" > "$output"); then
  pass "$CURRENT_SCENARIO: command exits successfully"
else
  fail "$CURRENT_SCENARIO: command exits successfully"
fi
if assert_contains "$output" "Key Decision (ml-decisions-entry)"; then pass "$CURRENT_SCENARIO: deep entry ranked via two-level chain"; else fail "$CURRENT_SCENARIO: deep entry ranked via two-level chain"; fi

scenario "split decisions script-v4 file loads"
output="$SANDBOX/load-script-v4.out"
if (cd "$SANDBOX/project" && HOME="$SANDBOX/home" python3 "$ROOT_DIR/src/ml" load "script" > "$output"); then
  pass "$CURRENT_SCENARIO: command exits successfully"
else
  fail "$CURRENT_SCENARIO: command exits successfully"
fi
if assert_contains "$output" "SCRIPT V4 Entry (ml-script-v4-entry)"; then pass "$CURRENT_SCENARIO: script-v4 entry ranked"; else fail "$CURRENT_SCENARIO: script-v4 entry ranked"; fi
if assert_contains "$output" "$SANDBOX/project/.mindlayer/knowledge/decisions/script-v4.md"; then pass "$CURRENT_SCENARIO: script-v4 source returned"; else fail "$CURRENT_SCENARIO: script-v4 source returned"; fi

scenario "split decisions process file loads"
output="$SANDBOX/load-process.out"
if (cd "$SANDBOX/project" && HOME="$SANDBOX/home" python3 "$ROOT_DIR/src/ml" load "approval" > "$output"); then
  pass "$CURRENT_SCENARIO: command exits successfully"
else
  fail "$CURRENT_SCENARIO: command exits successfully"
fi
if assert_contains "$output" "Approval Process (ml-process-entry)"; then pass "$CURRENT_SCENARIO: process entry ranked"; else fail "$CURRENT_SCENARIO: process entry ranked"; fi
if assert_contains "$output" "$SANDBOX/project/.mindlayer/knowledge/decisions/process.md"; then pass "$CURRENT_SCENARIO: process source returned"; else fail "$CURRENT_SCENARIO: process source returned"; fi

scenario "split decisions architecture file loads"
output="$SANDBOX/load-architecture.out"
if (cd "$SANDBOX/project" && HOME="$SANDBOX/home" python3 "$ROOT_DIR/src/ml" load "boot" > "$output"); then
  pass "$CURRENT_SCENARIO: command exits successfully"
else
  fail "$CURRENT_SCENARIO: command exits successfully"
fi
if assert_contains "$output" "Boot Architecture (ml-architecture-entry)"; then pass "$CURRENT_SCENARIO: architecture entry ranked"; else fail "$CURRENT_SCENARIO: architecture entry ranked"; fi
if assert_contains "$output" "$SANDBOX/project/.mindlayer/knowledge/decisions/architecture.md"; then pass "$CURRENT_SCENARIO: architecture source returned"; else fail "$CURRENT_SCENARIO: architecture source returned"; fi

scenario "flat decisions file removed from project memory"
if [ ! -e "$ROOT_DIR/.mindlayer/knowledge/decisions.md" ]; then
  pass "$CURRENT_SCENARIO: decisions.md absent"
else
  fail "$CURRENT_SCENARIO: decisions.md absent"
fi

scenario "index-full.md not loaded"
output="$SANDBOX/load-full.out"
if (cd "$SANDBOX/project" && HOME="$SANDBOX/home" python3 "$ROOT_DIR/src/ml" load "Full Only Entry" > "$output"); then
  pass "$CURRENT_SCENARIO: command exits successfully"
else
  fail "$CURRENT_SCENARIO: command exits successfully"
fi
if ! assert_contains "$output" "ml-full-only"; then pass "$CURRENT_SCENARIO: index-full.md entry absent from results"; else fail "$CURRENT_SCENARIO: index-full.md entry absent from results"; fi

scenario "duplicate id deduplication"
output="$SANDBOX/load-dedup.out"
if (cd "$SANDBOX/project" && HOME="$SANDBOX/home" python3 "$ROOT_DIR/src/ml" load "Dedup" > "$output"); then
  pass "$CURRENT_SCENARIO: command exits successfully"
else
  fail "$CURRENT_SCENARIO: command exits successfully"
fi
if [ "$(grep -c "ml-dedup-entry" "$output")" -eq 1 ]; then pass "$CURRENT_SCENARIO: exactly one result for duplicate id"; else fail "$CURRENT_SCENARIO: exactly one result for duplicate id"; fi
if assert_contains "$output" "Dedup First (ml-dedup-entry)"; then pass "$CURRENT_SCENARIO: first occurrence wins"; else fail "$CURRENT_SCENARIO: first occurrence wins"; fi
if ! assert_contains "$output" "Dedup Second"; then pass "$CURRENT_SCENARIO: second occurrence suppressed"; else fail "$CURRENT_SCENARIO: second occurrence suppressed"; fi

scenario "cyclic pointer does not crash"
# knowledge/index.md points back to itself via a pointer entry
CYCLE_PROJ="$SANDBOX/cycle"
mkdir -p "$CYCLE_PROJ/.mindlayer/knowledge"
cat > "$CYCLE_PROJ/.mindlayer/index.md" <<'EOF'
# Root Index

- ml-real-entry | Real Entry | knowledge/context.md | A normal leaf entry.
- ml-index-ptr-knowledge | Knowledge Index | knowledge/index.md | Index for knowledge/ subfolder
EOF
cat > "$CYCLE_PROJ/.mindlayer/knowledge/index.md" <<'EOF'
# Knowledge Index

- ml-cycle-back | Root Index | index.md | Pointer back to root — creates a cycle.
- ml-knowledge-leaf | Knowledge Leaf | knowledge/context.md | A leaf in knowledge.
EOF
cat > "$CYCLE_PROJ/.mindlayer/knowledge/context.md" <<'EOF'
# Knowledge Leaf

### Summary
A leaf in knowledge.
EOF
output="$SANDBOX/load-cycle.out"
if (cd "$CYCLE_PROJ" && HOME="$SANDBOX/home" python3 "$ROOT_DIR/src/ml" load "Leaf Entry" > "$output" 2>&1); then
  pass "$CURRENT_SCENARIO: command exits successfully despite cycle"
else
  fail "$CURRENT_SCENARIO: command exits successfully despite cycle"
fi
if ! assert_contains "$output" "RecursionError"; then pass "$CURRENT_SCENARIO: no RecursionError"; else fail "$CURRENT_SCENARIO: no RecursionError"; fi
if assert_contains "$output" "Real Entry (ml-real-entry)"; then pass "$CURRENT_SCENARIO: leaf entry before cycle still returned"; else fail "$CURRENT_SCENARIO: leaf entry before cycle still returned"; fi
if assert_contains "$output" "Knowledge Leaf (ml-knowledge-leaf)"; then pass "$CURRENT_SCENARIO: leaf entry after cycle still returned"; else fail "$CURRENT_SCENARIO: leaf entry after cycle still returned"; fi

printf "\nSummary: %s passed, %s failed\n" "$PASS_COUNT" "$FAIL_COUNT"
[ "$FAIL_COUNT" -eq 0 ]
