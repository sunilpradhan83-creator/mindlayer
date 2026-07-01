#!/usr/bin/env bash
# CLI contract tests for `ml clean`.

set -u

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
SANDBOX="${TMPDIR:-/tmp}/mindlayer-ml-clean-test.$$"
PASS_COUNT=0
FAIL_COUNT=0
CURRENT_SCENARIO=""

pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf "PASS  %s\n" "$1"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); printf "FAIL  %s\n" "$1"; }
scenario() { CURRENT_SCENARIO="$1"; printf "\n## %s\n" "$CURRENT_SCENARIO"; }
assert_contains() { grep -Fq "$2" "$1"; }
assert_file_contains() { grep -Fq "$2" "$1"; }

cleanup() { rm -rf "$SANDBOX"; }
trap cleanup EXIT

printf "MindLayer ml clean contract\n"
printf "===========================\n"

scenario "clean memory reports no stale entries"
mkdir -p "$SANDBOX/clean/.mindlayer" "$SANDBOX/clean/.mindlayer/knowledge" "$SANDBOX/clean/.mindlayer/pipeline" "$SANDBOX/clean/.mindlayer/pipeline/archive" "$SANDBOX/clean/.mindlayer/knowledge/sessions"
cat > "$SANDBOX/clean/.mindlayer/index-full.md" <<'EOF'
# Project Memory Index

## Entries

- id: ml-live-001
  title: Live Entry
  file: context.md
  section: Live Entry
  scope: project
  type: context
  tags: [live]
  summary: Current entry.
  importance: high
  status: active
  last_updated: 2026-05-14
EOF
printf "# Context\n\n## Live Entry\n\nCurrent.\n" > "$SANDBOX/clean/.mindlayer/knowledge/context.md"
output="$SANDBOX/clean.out"
if (cd "$SANDBOX/clean" && python3 "$ROOT_DIR/src/ml" clean > "$output"); then
  pass "$CURRENT_SCENARIO: command exits 0"
else
  fail "$CURRENT_SCENARIO: command exits 0"
fi
if assert_contains "$output" "No stale entries found. Memory is clean."; then pass "$CURRENT_SCENARIO: clean message printed"; else fail "$CURRENT_SCENARIO: clean message printed"; fi

scenario "clean proposes archived entry without approval"
mkdir -p "$SANDBOX/propose/.mindlayer" "$SANDBOX/propose/.mindlayer/knowledge" "$SANDBOX/propose/.mindlayer/pipeline" "$SANDBOX/propose/.mindlayer/pipeline/archive" "$SANDBOX/propose/.mindlayer/knowledge/sessions"
cat > "$SANDBOX/propose/.mindlayer/index-full.md" <<'EOF'
# Project Memory Index

## Entries

- id: ml-old-001
  title: Old Entry
  file: context.md
  section: Old Entry
  scope: project
  type: context
  tags: [old]
  summary: Stale entry.
  importance: medium
  status: archived
  last_updated: 2026-05-01
EOF
printf "# Context\n\n## Old Entry\n\nStale content.\n" > "$SANDBOX/propose/.mindlayer/knowledge/context.md"
output="$SANDBOX/propose.out"
if (cd "$SANDBOX/propose" && python3 "$ROOT_DIR/src/ml" clean > "$output"); then
  pass "$CURRENT_SCENARIO: command exits 0"
else
  fail "$CURRENT_SCENARIO: command exits 0"
fi
if assert_contains "$output" "Archive Candidate:"; then pass "$CURRENT_SCENARIO: proposal printed"; else fail "$CURRENT_SCENARIO: proposal printed"; fi
if assert_contains "$output" "approve all"; then pass "$CURRENT_SCENARIO: approval prompt printed"; else fail "$CURRENT_SCENARIO: approval prompt printed"; fi
if assert_file_contains "$SANDBOX/propose/.mindlayer/knowledge/context.md" "Old Entry"; then pass "$CURRENT_SCENARIO: source unchanged before approval"; else fail "$CURRENT_SCENARIO: source unchanged before approval"; fi

scenario "clean approve all archives and updates index"
mkdir -p "$SANDBOX/approve/.mindlayer" "$SANDBOX/approve/.mindlayer/knowledge" "$SANDBOX/approve/.mindlayer/pipeline" "$SANDBOX/approve/.mindlayer/pipeline/archive" "$SANDBOX/approve/.mindlayer/knowledge/sessions"
cat > "$SANDBOX/approve/.mindlayer/index-full.md" <<'EOF'
# Project Memory Index

## Entries

- id: ml-old-001
  title: Old Entry
  file: context.md
  section: Old Entry
  scope: project
  type: context
  tags: [old]
  summary: Stale entry.
  importance: medium
  status: archived
  last_updated: 2026-05-01
EOF
printf "# Project Memory Index\n- ml-old-001 | Old Entry | context.md | Stale entry.\n" > "$SANDBOX/approve/.mindlayer/index.md"
printf "# Context\n\n## Old Entry\n\nStale content.\n\n## Live Entry\n\nCurrent.\n" > "$SANDBOX/approve/.mindlayer/knowledge/context.md"
output="$SANDBOX/approve.out"
if (cd "$SANDBOX/approve" && python3 "$ROOT_DIR/src/ml" clean --approve-all > "$output"); then
  pass "$CURRENT_SCENARIO: command exits 0"
else
  fail "$CURRENT_SCENARIO: command exits 0"
fi
if assert_contains "$output" "Done."; then pass "$CURRENT_SCENARIO: done printed"; else fail "$CURRENT_SCENARIO: done printed"; fi
if ! grep -Fq "Old Entry" "$SANDBOX/approve/.mindlayer/knowledge/context.md"; then pass "$CURRENT_SCENARIO: source archived"; else fail "$CURRENT_SCENARIO: source archived"; fi
if assert_file_contains "$SANDBOX/approve/.mindlayer/pipeline/archive/archive.md" "Old Entry"; then pass "$CURRENT_SCENARIO: archive contains entry"; else fail "$CURRENT_SCENARIO: archive contains entry"; fi
if assert_file_contains "$SANDBOX/approve/.mindlayer/index-full.md" "file: pipeline/archive/archive.md"; then pass "$CURRENT_SCENARIO: index-full points to archive"; else fail "$CURRENT_SCENARIO: index-full points to archive"; fi

scenario "clean deletes stale missing-file index entry"
mkdir -p "$SANDBOX/delete/.mindlayer" "$SANDBOX/delete/.mindlayer/knowledge" "$SANDBOX/delete/.mindlayer/pipeline" "$SANDBOX/delete/.mindlayer/pipeline/archive" "$SANDBOX/delete/.mindlayer/knowledge/sessions"
cat > "$SANDBOX/delete/.mindlayer/index-full.md" <<'EOF'
# Project Memory Index

## Entries

- id: ml-missing-001
  title: Missing Entry
  file: missing.md
  section: Missing Entry
  scope: project
  type: context
  tags: [missing]
  summary: Missing entry.
  importance: low
  status: archived
  last_updated: 2026-05-01
EOF
output="$SANDBOX/delete.out"
if (cd "$SANDBOX/delete" && python3 "$ROOT_DIR/src/ml" clean --approve-all > "$output"); then
  pass "$CURRENT_SCENARIO: command exits 0"
else
  fail "$CURRENT_SCENARIO: command exits 0"
fi
if assert_contains "$output" "Deleted: Missing Entry"; then pass "$CURRENT_SCENARIO: delete reported"; else fail "$CURRENT_SCENARIO: delete reported"; fi
if ! grep -Fq "ml-missing-001" "$SANDBOX/delete/.mindlayer/index-full.md"; then pass "$CURRENT_SCENARIO: stale index entry removed"; else fail "$CURRENT_SCENARIO: stale index entry removed"; fi

scenario "clean global scope scans global memory"
mkdir -p "$SANDBOX/global/project/.mindlayer" "$SANDBOX/global/home/.mindlayer" "$SANDBOX/global/project/.mindlayer/knowledge" "$SANDBOX/global/project/.mindlayer/pipeline" "$SANDBOX/global/project/.mindlayer/pipeline/archive" "$SANDBOX/global/project/.mindlayer/knowledge/sessions" "$SANDBOX/global/home/.mindlayer/knowledge" "$SANDBOX/global/home/.mindlayer/pipeline" "$SANDBOX/global/home/.mindlayer/pipeline/archive" "$SANDBOX/global/home/.mindlayer/knowledge/sessions"
cat > "$SANDBOX/global/home/.mindlayer/index-full.md" <<'EOF'
# Global Memory Index

## Entries

- id: ml-global-old-001
  title: Global Old Entry
  file: context.md
  section: Global Old Entry
  scope: global
  type: context
  tags: [old]
  summary: Stale global entry.
  importance: medium
  status: archived
  last_updated: 2026-05-01
EOF
printf "# Context\n\n## Global Old Entry\n\nGlobal stale content.\n" > "$SANDBOX/global/home/.mindlayer/knowledge/context.md"
output="$SANDBOX/global.out"
if (cd "$SANDBOX/global/project" && HOME="$SANDBOX/global/home" python3 "$ROOT_DIR/src/ml" clean --scope global > "$output"); then
  pass "$CURRENT_SCENARIO: command exits 0"
else
  fail "$CURRENT_SCENARIO: command exits 0"
fi
if assert_contains "$output" "Global Old Entry"; then pass "$CURRENT_SCENARIO: global candidate printed"; else fail "$CURRENT_SCENARIO: global candidate printed"; fi
if assert_file_contains "$SANDBOX/global/home/.mindlayer/knowledge/context.md" "Global Old Entry"; then pass "$CURRENT_SCENARIO: global source unchanged before approval"; else fail "$CURRENT_SCENARIO: global source unchanged before approval"; fi

scenario "clean scans hierarchical indexes"
mkdir -p "$SANDBOX/tree/.mindlayer/knowledge" "$SANDBOX/tree/.mindlayer/pipeline" "$SANDBOX/tree/.mindlayer/pipeline/archive" "$SANDBOX/tree/.mindlayer/knowledge/sessions"
cat > "$SANDBOX/tree/.mindlayer/index.md" <<'EOF'
# Project Memory Index

- ml-index-ptr-knowledge | Knowledge Index | knowledge/index.md | Index for knowledge/ subfolder
EOF
cat > "$SANDBOX/tree/.mindlayer/knowledge/index.md" <<'EOF'
# Knowledge Index

- ml-tree-risk | Tree Risk | knowledge/risks.md | Resolved risk in hierarchical index.
EOF
cat > "$SANDBOX/tree/.mindlayer/knowledge/risks.md" <<'EOF'
# Risks

## Tree Risk

id: ml-tree-risk
type: risk
status: resolved

### Summary
Resolved risk in hierarchical index.
EOF
output="$SANDBOX/tree.out"
if (cd "$SANDBOX/tree" && python3 "$ROOT_DIR/src/ml" clean > "$output"); then
  pass "$CURRENT_SCENARIO: command exits 0"
else
  fail "$CURRENT_SCENARIO: command exits 0"
fi
if assert_contains "$output" "Tree Risk"; then pass "$CURRENT_SCENARIO: hierarchical candidate printed"; else fail "$CURRENT_SCENARIO: hierarchical candidate printed"; fi
if assert_contains "$output" "Summary: 1 to archive, 0 to delete, 0 to keep"; then pass "$CURRENT_SCENARIO: hierarchical summary correct"; else fail "$CURRENT_SCENARIO: hierarchical summary correct"; fi

output="$SANDBOX/tree-approve.out"
if (cd "$SANDBOX/tree" && python3 "$ROOT_DIR/src/ml" clean --approve-all > "$output"); then
  pass "$CURRENT_SCENARIO: approved command exits 0"
else
  fail "$CURRENT_SCENARIO: approved command exits 0"
fi
if ! grep -Fq "Tree Risk" "$SANDBOX/tree/.mindlayer/knowledge/risks.md"; then pass "$CURRENT_SCENARIO: hierarchical source archived"; else fail "$CURRENT_SCENARIO: hierarchical source archived"; fi
if assert_file_contains "$SANDBOX/tree/.mindlayer/pipeline/archive/archive.md" "Tree Risk"; then pass "$CURRENT_SCENARIO: hierarchical archive contains entry"; else fail "$CURRENT_SCENARIO: hierarchical archive contains entry"; fi
if assert_file_contains "$SANDBOX/tree/.mindlayer/knowledge/index.md" "pipeline/archive/archive.md"; then pass "$CURRENT_SCENARIO: nearest index points to archive"; else fail "$CURRENT_SCENARIO: nearest index points to archive"; fi

scenario "clean flags completed and resolved entries"
mkdir -p "$SANDBOX/statuses/.mindlayer" "$SANDBOX/statuses/.mindlayer/knowledge" "$SANDBOX/statuses/.mindlayer/pipeline" "$SANDBOX/statuses/.mindlayer/pipeline/archive" "$SANDBOX/statuses/.mindlayer/knowledge/sessions"
cat > "$SANDBOX/statuses/.mindlayer/index-full.md" <<'EOF'
# Project Memory Index

## Entries

- id: ml-done-001
  title: Completed Progress
  file: progress.md
  section: Completed Progress
  scope: project
  type: progress
  tags: [done]
  summary: Completed progress.
  importance: high
  status: completed
  last_updated: 2026-05-01

- id: ml-risk-001
  title: Resolved Risk
  file: risks.md
  section: Resolved Risk
  scope: project
  type: risk
  tags: [risk]
  summary: Resolved risk.
  importance: high
  status: resolved
  last_updated: 2026-05-01
EOF
printf "# Progress\n\n## Completed Progress\n\nDone.\n" > "$SANDBOX/statuses/.mindlayer/pipeline/progress.md"
printf "# Risks\n\n## Resolved Risk\n\nFixed.\n" > "$SANDBOX/statuses/.mindlayer/knowledge/risks.md"
output="$SANDBOX/statuses.out"
if (cd "$SANDBOX/statuses" && python3 "$ROOT_DIR/src/ml" clean > "$output"); then
  pass "$CURRENT_SCENARIO: command exits 0"
else
  fail "$CURRENT_SCENARIO: command exits 0"
fi
if assert_contains "$output" "Completed Progress"; then pass "$CURRENT_SCENARIO: completed progress flagged"; else fail "$CURRENT_SCENARIO: completed progress flagged"; fi
if assert_contains "$output" "Resolved Risk"; then pass "$CURRENT_SCENARIO: resolved risk flagged"; else fail "$CURRENT_SCENARIO: resolved risk flagged"; fi
if assert_contains "$output" "Summary: 2 to archive, 0 to delete, 0 to keep"; then pass "$CURRENT_SCENARIO: archive summary correct"; else fail "$CURRENT_SCENARIO: archive summary correct"; fi

scenario "clean reports keep action for non-archivable resolved entry"
mkdir -p "$SANDBOX/keep/.mindlayer" "$SANDBOX/keep/.mindlayer/knowledge" "$SANDBOX/keep/.mindlayer/pipeline" "$SANDBOX/keep/.mindlayer/pipeline/archive" "$SANDBOX/keep/.mindlayer/knowledge/sessions"
cat > "$SANDBOX/keep/.mindlayer/index-full.md" <<'EOF'
# Project Memory Index

## Entries

- id: ml-note-001
  title: Resolved Note
  file: context.md
  section: Resolved Note
  scope: project
  type: context
  tags: [note]
  summary: Resolved context note.
  importance: low
  status: resolved
  last_updated: 2026-05-01
EOF
printf "# Context\n\n## Resolved Note\n\nMaybe keep.\n" > "$SANDBOX/keep/.mindlayer/knowledge/context.md"
output="$SANDBOX/keep.out"
if (cd "$SANDBOX/keep" && python3 "$ROOT_DIR/src/ml" clean > "$output"); then
  pass "$CURRENT_SCENARIO: command exits 0"
else
  fail "$CURRENT_SCENARIO: command exits 0"
fi
if assert_contains "$output" "Keep Candidate:"; then pass "$CURRENT_SCENARIO: keep label printed"; else fail "$CURRENT_SCENARIO: keep label printed"; fi
if assert_contains "$output" "Proposed action: keep"; then pass "$CURRENT_SCENARIO: keep action printed"; else fail "$CURRENT_SCENARIO: keep action printed"; fi
if assert_contains "$output" "Summary: 0 to archive, 0 to delete, 1 to keep"; then pass "$CURRENT_SCENARIO: keep summary correct"; else fail "$CURRENT_SCENARIO: keep summary correct"; fi

scenario "clean handles mixed archive delete keep candidates"
mkdir -p "$SANDBOX/mixed/.mindlayer" "$SANDBOX/mixed/.mindlayer/knowledge" "$SANDBOX/mixed/.mindlayer/pipeline" "$SANDBOX/mixed/.mindlayer/pipeline/archive" "$SANDBOX/mixed/.mindlayer/knowledge/sessions"
cat > "$SANDBOX/mixed/.mindlayer/index-full.md" <<'EOF'
# Project Memory Index

## Entries

- id: ml-old-001
  title: Old Entry
  file: context.md
  section: Old Entry
  scope: project
  type: context
  tags: [old]
  summary: Stale entry.
  importance: medium
  status: archived
  last_updated: 2026-05-01

- id: ml-missing-001
  title: Missing Entry
  file: missing.md
  section: Missing Entry
  scope: project
  type: context
  tags: [missing]
  summary: Missing entry.
  importance: low
  status: archived
  last_updated: 2026-05-01

- id: ml-note-001
  title: Resolved Note
  file: context.md
  section: Resolved Note
  scope: project
  type: context
  tags: [note]
  summary: Resolved context note.
  importance: low
  status: resolved
  last_updated: 2026-05-01
EOF
printf "# Context\n\n## Old Entry\n\nStale.\n\n## Resolved Note\n\nKeep.\n" > "$SANDBOX/mixed/.mindlayer/knowledge/context.md"
output="$SANDBOX/mixed.out"
if (cd "$SANDBOX/mixed" && python3 "$ROOT_DIR/src/ml" clean > "$output"); then
  pass "$CURRENT_SCENARIO: command exits 0"
else
  fail "$CURRENT_SCENARIO: command exits 0"
fi
if assert_contains "$output" "Archive Candidate:"; then pass "$CURRENT_SCENARIO: archive candidate printed"; else fail "$CURRENT_SCENARIO: archive candidate printed"; fi
if assert_contains "$output" "Delete Candidate:"; then pass "$CURRENT_SCENARIO: delete candidate printed"; else fail "$CURRENT_SCENARIO: delete candidate printed"; fi
if assert_contains "$output" "Keep Candidate:"; then pass "$CURRENT_SCENARIO: keep label printed"; else fail "$CURRENT_SCENARIO: keep label printed"; fi
if assert_contains "$output" "Proposed action: keep"; then pass "$CURRENT_SCENARIO: keep candidate printed"; else fail "$CURRENT_SCENARIO: keep candidate printed"; fi
if assert_contains "$output" "Summary: 1 to archive, 1 to delete, 1 to keep"; then pass "$CURRENT_SCENARIO: mixed summary correct"; else fail "$CURRENT_SCENARIO: mixed summary correct"; fi

printf "\nSummary: %s passed, %s failed\n" "$PASS_COUNT" "$FAIL_COUNT"
[ "$FAIL_COUNT" -eq 0 ]
