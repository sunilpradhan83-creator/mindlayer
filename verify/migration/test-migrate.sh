#!/usr/bin/env bash
# Verifies `ml migrate` moves a legacy pipeline/ layout to the ADR-0001 work/ layout:
# size-aware consolidation, moves, index rewrites, idempotency, dry-run safety, and
# that the migrated layout is resolved by boot and load.

set -u

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
SANDBOX="${TMPDIR:-/tmp}/mindlayer-migrate.$$"
PASS_COUNT=0
FAIL_COUNT=0
CURRENT_SCENARIO=""

pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf "PASS  %s\n" "$1"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); printf "FAIL  %s\n" "$1"; }
scenario() { CURRENT_SCENARIO="$1"; printf "\n## %s\n" "$1"; }
assert_contains() { grep -Fq "$2" "$1"; }
assert_not_contains() { ! grep -Fq "$2" "$1"; }
assert_ematch() { grep -Eq "$2" "$1"; }
assert_not_ematch() { ! grep -Eq "$2" "$1"; }
check() {
  label="$1"; shift
  if "$@" 2>/dev/null; then pass "$CURRENT_SCENARIO: $label"; else fail "$CURRENT_SCENARIO: $label"; fi
}
cleanup() { rm -rf "$SANDBOX"; }
trap cleanup EXIT

mkdir -p "$SANDBOX/home/.mindlayer/memory-system" "$SANDBOX/home/.mindlayer/preferences"
: > "$SANDBOX/home/.mindlayer/boot.md"
: > "$SANDBOX/home/.mindlayer/router.md"
: > "$SANDBOX/home/.mindlayer/memory-system/per-turn.md"

# build_fixture <dir> <progress-pad-lines>
build_fixture() {
  local base="$1" pad="$2"
  local mem="$base/.mindlayer"
  mkdir -p "$mem/knowledge/sessions" "$mem/pipeline/signals" "$mem/pipeline/archive" "$mem/pipeline/stories"
  git -C "$base" init -q
  git -C "$base" config user.email test@example.com
  git -C "$base" config user.name test

  cat > "$mem/index.md" <<'EOF'
# Project Memory Index

Pointers to subfolder indexes.

- ml-index-ptr-knowledge | Knowledge Index | knowledge/index.md | Index for knowledge/ subfolder
- ml-index-ptr-pipeline | Pipeline Index | pipeline/index.md | Index for pipeline/ subfolder
EOF

  cat > "$mem/knowledge/project.md" <<'EOF'
# Project

## Project Identity

### Summary
Synthetic project for migration test.
EOF

  cat > "$mem/knowledge/index.md" <<'EOF'
# Knowledge Index

- ml-project-20260101-001 | Project Identity | project.md | Synthetic project.
EOF

  cat > "$mem/pipeline/index.md" <<'EOF'
# Pipeline Index

- ml-20260101-progress | Current Phase | progress.md | Migration test progress entry.
- ml-20260101-backlog | Future Roadmap | backlog.md | Migration test backlog entry.
- ml-20260101-roadmap | Product Roadmap | roadmap.md | Migration test roadmap entry.
- ml-20260101-router | Project Router | router.md | Conditional load triggers.
EOF

  cat > "$mem/pipeline/progress.md" <<'EOF'
# Progress

## Current Phase

id: ml-20260101-progress
created: 2026-01-01
updated: 2026-01-01
scope: project
type: progress
status: in-progress

### Summary
Migration test progress phase distinctive marker ALPHAPROGRESS.

### Details
- Current phase: migration testing.
EOF

  # pad progress past the consolidation threshold when requested
  local i=0
  while [ "$i" -lt "$pad" ]; do
    printf "padding line %s\n" "$i" >> "$mem/pipeline/progress.md"
    i=$((i + 1))
  done

  cat > "$mem/pipeline/backlog.md" <<'EOF'
# Backlog

## Future Roadmap

id: ml-20260101-backlog
created: 2026-01-01
updated: 2026-01-01
scope: project
type: backlog
status: active

### Summary
Migration test backlog distinctive marker BETABACKLOG.
EOF

  cat > "$mem/pipeline/roadmap.md" <<'EOF'
# Roadmap

## Product Roadmap

id: ml-20260101-roadmap
created: 2026-01-01
updated: 2026-01-01
type: roadmap
status: active

### Summary
Migration test roadmap entry.
EOF

  cat > "$mem/pipeline/signals.md" <<'EOF'
# Signals Migrated

The active signal queue moved to the signals/ folder. Legacy note only.
EOF

  cat > "$mem/pipeline/signals/index.md" <<'EOF'
# Signals Index
EOF
  cat > "$mem/pipeline/signals/ml-signal-001.md" <<'EOF'
# Signal 001
EOF

  cat > "$mem/pipeline/archive/archive.md" <<'EOF'
# Archive
EOF
  cat > "$mem/pipeline/archive/ml-story-001.md" <<'EOF'
# Archived story 001
EOF

  cat > "$mem/pipeline/stories/index.md" <<'EOF'
# Stories Index

| id | title | status | created | parent |
| -- | ----- | ------ | ------- | ------ |
EOF

  git -C "$base" add -A >/dev/null 2>&1
  git -C "$base" commit -qm "fixture" >/dev/null 2>&1
}

printf "MindLayer ml migrate contract\n"
printf "=============================\n"

# ---------------------------------------------------------------------------
# Fixture SMALL: short progress + short backlog consolidate into current.md
# ---------------------------------------------------------------------------
SMALL="$SANDBOX/small"
build_fixture "$SMALL" 0

scenario "SMALL dry-run prints plan and changes nothing"
small_dry="$SANDBOX/small-dry.out"
(cd "$SMALL" && HOME="$SANDBOX/home" python3 "$ROOT_DIR/src/ml" migrate > "$small_dry" 2>/dev/null)
check "dry-run announces no changes" assert_contains "$small_dry" "No changes made."
check "dry-run prints a would-write for current.md" assert_contains "$small_dry" "would write work/current.md"
check "dry-run left work/ absent" test ! -d "$SMALL/.mindlayer/work"
check "dry-run left pipeline/ intact" test -d "$SMALL/.mindlayer/pipeline"
check "dry-run plans removal of progress.md" assert_contains "$small_dry" "would remove pipeline/progress.md"
check "dry-run plans removal of backlog.md" assert_contains "$small_dry" "would remove pipeline/backlog.md"
check "dry-run plans removal of signals.md" assert_contains "$small_dry" "would remove pipeline/signals.md"

scenario "SMALL migrate --approve consolidates progress + backlog"
small_run="$SANDBOX/small-run.out"
(cd "$SMALL" && HOME="$SANDBOX/home" python3 "$ROOT_DIR/src/ml" migrate --approve > "$small_run" 2>/dev/null)
check "work/current.md exists" test -f "$SMALL/.mindlayer/work/current.md"
check "current.md has progress entry" assert_contains "$SMALL/.mindlayer/work/current.md" "ALPHAPROGRESS"
check "current.md has backlog entry" assert_contains "$SMALL/.mindlayer/work/current.md" "BETABACKLOG"
check "work/backlog.md not created" test ! -f "$SMALL/.mindlayer/work/backlog.md"
check "current.md has # Current Work header" assert_contains "$SMALL/.mindlayer/work/current.md" "# Current Work"
check "no pipeline/ dir remains" test ! -d "$SMALL/.mindlayer/pipeline"
check "knowledge/roadmap.md exists" test -f "$SMALL/.mindlayer/knowledge/roadmap.md"
check "work/signals/ exists" test -d "$SMALL/.mindlayer/work/signals"
check "top-level archive/ exists" test -d "$SMALL/.mindlayer/archive"
check "archive got moved story" test -f "$SMALL/.mindlayer/archive/ml-story-001.md"
check "work/sessions/ exists" test -d "$SMALL/.mindlayer/work/sessions"
check "empty-only stories dropped" test ! -d "$SMALL/.mindlayer/work/stories"
check "signals.md skipped as non-entry" assert_contains "$small_run" "skipping non-entry file pipeline/signals.md"

scenario "SMALL consumed sources are staged git deletions (git rm, not unstaged wipe)"
small_gitstatus="$SANDBOX/small-gitstatus.out"
(cd "$SMALL" && git status --porcelain > "$small_gitstatus" 2>/dev/null)
check "progress.md is a staged deletion" assert_ematch "$small_gitstatus" '^D  .*pipeline/progress\.md'
check "backlog.md is a staged deletion" assert_ematch "$small_gitstatus" '^D  .*pipeline/backlog\.md'
check "signals.md is a staged deletion" assert_ematch "$small_gitstatus" '^D  .*pipeline/signals\.md'
check "no unstaged deletion of progress.md" assert_not_ematch "$small_gitstatus" '^ D .*pipeline/progress\.md'
check "no unstaged deletion of backlog.md" assert_not_ematch "$small_gitstatus" '^ D .*pipeline/backlog\.md'
check "no unstaged deletion of signals.md" assert_not_ematch "$small_gitstatus" '^ D .*pipeline/signals\.md'

scenario "SMALL index rewrites"
check "work/index.md exists" test -f "$SMALL/.mindlayer/work/index.md"
check "index repoints progress to work/current.md" assert_contains "$SMALL/.mindlayer/work/index.md" "work/current.md"
check "index repoints backlog to work/current.md" grep -q "ml-20260101-backlog | Future Roadmap | work/current.md" "$SMALL/.mindlayer/work/index.md"
check "roadmap row moved out of work/index.md" assert_not_contains "$SMALL/.mindlayer/work/index.md" "roadmap.md"
check "router row moved out of work/index.md" assert_not_contains "$SMALL/.mindlayer/work/index.md" "router.md"
check "root index repoints to work/index.md" assert_contains "$SMALL/.mindlayer/index.md" "work/index.md"
check "root index stays pointer-only (no router entry)" assert_not_contains "$SMALL/.mindlayer/index.md" "Project Router"
check "router row relocated to knowledge index" assert_contains "$SMALL/.mindlayer/knowledge/index.md" "Project Router"
check "knowledge index gains roadmap row" grep -q "knowledge/roadmap.md" "$SMALL/.mindlayer/knowledge/index.md"
check "archive index exists" test -f "$SMALL/.mindlayer/archive/index.md"

scenario "SMALL idempotency"
small_again="$SANDBOX/small-again.out"
before_hash=$(cd "$SMALL/.mindlayer" && find . -type f | sort | xargs cat 2>/dev/null | cksum)
(cd "$SMALL" && HOME="$SANDBOX/home" python3 "$ROOT_DIR/src/ml" migrate --approve > "$small_again" 2>/dev/null)
after_hash=$(cd "$SMALL/.mindlayer" && find . -type f | sort | xargs cat 2>/dev/null | cksum)
check "second run reports already migrated" assert_contains "$small_again" "Already migrated"
check "second run changed nothing" test "$before_hash" = "$after_hash"

scenario "SMALL boot resolves migrated layout"
small_boot="$SANDBOX/small-boot.out"
(cd "$SMALL" && HOME="$SANDBOX/home" python3 "$ROOT_DIR/src/ml" boot > "$small_boot" 2>/dev/null)
check "boot exits and cites work/current.md" assert_contains "$small_boot" ".mindlayer/work/current.md"

scenario "SMALL boot surfaces migrated session Next"
cat > "$SMALL/.mindlayer/work/sessions/2026-06-30.md" <<'EOF'
# Session: 2026-06-30

## Commit
0000000000000000000000000000000000000000

## Next
- resume the migrated work GAMMANEXT
EOF
small_boot2="$SANDBOX/small-boot2.out"
(cd "$SMALL" && HOME="$SANDBOX/home" python3 "$ROOT_DIR/src/ml" boot > "$small_boot2" 2>/dev/null)
check "boot surfaces migrated session Next" assert_contains "$small_boot2" "GAMMANEXT"

scenario "SMALL load resolves via work/current.md"
small_load="$SANDBOX/small-load.out"
(cd "$SMALL" && HOME="$SANDBOX/home" python3 "$ROOT_DIR/src/ml" load "Current Phase" > "$small_load" 2>/dev/null)
if [ $? -eq 0 ]; then pass "$CURRENT_SCENARIO: load exits 0"; else fail "$CURRENT_SCENARIO: load exits 0"; fi
check "load returns the migrated progress entry" assert_contains "$small_load" "ALPHAPROGRESS"

scenario "SMALL post-migration write commands are target-aware"
# ml script must read work/signals (not the gone pipeline/), and ml archive must
# target the top-level archive/, not recreate pipeline/archive/ (post-2b regressions).
small_script="$SANDBOX/small-script.out"
(cd "$SMALL" && HOME="$SANDBOX/home" python3 "$ROOT_DIR/src/ml" script status > "$small_script" 2>/dev/null)
check "script status is not 'not initialized'" assert_not_contains "$small_script" "not initialized"
check "script status reads migrated signals" assert_contains "$small_script" "Signals:"
small_arch="$SANDBOX/small-archive.out"
(cd "$SMALL" && HOME="$SANDBOX/home" python3 "$ROOT_DIR/src/ml" archive --file work/current.md --section 'Future Roadmap' --action archive > "$small_arch" 2>/dev/null)
check "archive targets top-level archive/archive.md" assert_contains "$small_arch" "move to archive/archive.md"
check "archive does not target legacy pipeline/archive" assert_not_contains "$small_arch" "pipeline/archive"
small_arch_short="$SANDBOX/small-archive-short.out"
(cd "$SMALL" && HOME="$SANDBOX/home" python3 "$ROOT_DIR/src/ml" archive --file current.md --section 'Future Roadmap' --action archive > "$small_arch_short" 2>/dev/null)
check "current.md shorthand resolves to work/current.md" assert_not_contains "$small_arch_short" "not found"
small_arch_approved="$SANDBOX/small-archive-approved.out"
(cd "$SMALL" && HOME="$SANDBOX/home" python3 "$ROOT_DIR/src/ml" archive --file current.md --section 'Future Roadmap' --action archive --approve-all > "$small_arch_approved" 2>/dev/null)
check "approved archive updates work index row" grep -q "ml-20260101-backlog | Future Roadmap | archive/archive.md" "$SMALL/.mindlayer/work/index.md"
check "approved archive appends section to top-level archive" assert_contains "$SMALL/.mindlayer/archive/archive.md" "BETABACKLOG"
check "approved archive does not recreate pipeline" test ! -d "$SMALL/.mindlayer/pipeline"

scenario "PARTIAL target work dir does not shadow legacy script state"
PARTIAL="$SANDBOX/partial"
build_fixture "$PARTIAL" 0
mkdir -p "$PARTIAL/.mindlayer/work"
cat > "$PARTIAL/.mindlayer/pipeline/signals/ml-signal-partial.md" <<'EOF'
---
id: ml-signal-partial
title: Partial legacy signal
created: 2026-01-01
status: pending
---

# Partial legacy signal
EOF
partial_script="$SANDBOX/partial-script.out"
(cd "$PARTIAL" && HOME="$SANDBOX/home" python3 "$ROOT_DIR/src/ml" script status > "$partial_script" 2>/dev/null)
check "empty work dir does not hide legacy signals" assert_contains "$partial_script" "Signals: 1 pending"

# ---------------------------------------------------------------------------
# Fixture LARGE: padded progress forces backlog to split into work/backlog.md
# ---------------------------------------------------------------------------
LARGE="$SANDBOX/large"
build_fixture "$LARGE" 260

scenario "LARGE dry-run changes nothing"
large_dry="$SANDBOX/large-dry.out"
(cd "$LARGE" && HOME="$SANDBOX/home" python3 "$ROOT_DIR/src/ml" migrate > "$large_dry" 2>/dev/null)
check "dry-run announces no changes" assert_contains "$large_dry" "No changes made."
check "dry-run left work/ absent" test ! -d "$LARGE/.mindlayer/work"

scenario "LARGE migrate --approve splits backlog"
large_run="$SANDBOX/large-run.out"
(cd "$LARGE" && HOME="$SANDBOX/home" python3 "$ROOT_DIR/src/ml" migrate --approve > "$large_run" 2>/dev/null)
check "work/current.md exists" test -f "$LARGE/.mindlayer/work/current.md"
check "work/backlog.md exists separately" test -f "$LARGE/.mindlayer/work/backlog.md"
check "current.md has progress entry" assert_contains "$LARGE/.mindlayer/work/current.md" "ALPHAPROGRESS"
check "backlog.md has backlog entry" assert_contains "$LARGE/.mindlayer/work/backlog.md" "BETABACKLOG"
check "current.md does NOT have backlog entry" assert_not_contains "$LARGE/.mindlayer/work/current.md" "BETABACKLOG"
check "no pipeline/ dir remains" test ! -d "$LARGE/.mindlayer/pipeline"
check "index repoints backlog to work/backlog.md" grep -q "work/backlog.md" "$LARGE/.mindlayer/work/index.md"

scenario "LARGE idempotency + boot"
large_again="$SANDBOX/large-again.out"
(cd "$LARGE" && HOME="$SANDBOX/home" python3 "$ROOT_DIR/src/ml" migrate --approve > "$large_again" 2>/dev/null)
check "second run reports already migrated" assert_contains "$large_again" "Already migrated"
large_boot="$SANDBOX/large-boot.out"
(cd "$LARGE" && HOME="$SANDBOX/home" python3 "$ROOT_DIR/src/ml" boot > "$large_boot" 2>/dev/null)
check "boot exits 0" test $? -eq 0
check "boot cites work/current.md" assert_contains "$large_boot" ".mindlayer/work/current.md"

printf "\nSummary: %s passed, %s failed\n" "$PASS_COUNT" "$FAIL_COUNT"
[ "$FAIL_COUNT" -eq 0 ]
