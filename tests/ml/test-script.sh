#!/usr/bin/env bash
# CLI contract tests for `ml script`.

set -u

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
SANDBOX="${TMPDIR:-/tmp}/mindlayer-ml-script-test.$$"
PASS_COUNT=0
FAIL_COUNT=0
CURRENT_SCENARIO=""

pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf "PASS  %s\n" "$1"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); printf "FAIL  %s\n" "$1"; }
scenario() { CURRENT_SCENARIO="$1"; printf "\n## %s\n" "$CURRENT_SCENARIO"; }
assert_contains() { grep -Fq -- "$2" "$1"; }
check() {
  local label="$1"; shift
  if "$@"; then pass "$CURRENT_SCENARIO: $label"; else fail "$CURRENT_SCENARIO: $label"; fi
}
check_not() {
  local label="$1"; shift
  if ! "$@"; then pass "$CURRENT_SCENARIO: $label"; else fail "$CURRENT_SCENARIO: $label"; fi
}

cleanup() { rm -rf "$SANDBOX"; }
trap cleanup EXIT

printf "MindLayer ml script contract\n"
printf "============================\n"

# ---------------------------------------------------------------------------
# Existing scenarios (unchanged)
# ---------------------------------------------------------------------------

scenario "script help lists status"
mkdir -p "$SANDBOX/help/.mindlayer/pipeline" "$SANDBOX/help/.mindlayer/knowledge/sessions"
output="$SANDBOX/help.out"
if (cd "$SANDBOX/help" && python3 "$ROOT_DIR/src/ml" script --help > "$output"); then
  pass "$CURRENT_SCENARIO: command exits 0"
else
  fail "$CURRENT_SCENARIO: command exits 0"
fi
check "status shown" assert_contains "$output" "status"
check "SCRIPT shown" assert_contains "$output" "SCRIPT"

scenario "status before pipeline exists is read-only empty state"
mkdir -p "$SANDBOX/no-pipeline/.mindlayer"
output="$SANDBOX/no-pipeline.out"
before="$SANDBOX/no-pipeline.before"
after="$SANDBOX/no-pipeline.after"
(cd "$SANDBOX/no-pipeline" && find .mindlayer -type f -print | sort > "$before")
if (cd "$SANDBOX/no-pipeline" && python3 "$ROOT_DIR/src/ml" script status > "$output"); then
  pass "$CURRENT_SCENARIO: command exits 0"
else
  fail "$CURRENT_SCENARIO: command exits 0"
fi
(cd "$SANDBOX/no-pipeline" && find .mindlayer -type f -print | sort > "$after")
check "status header" assert_contains "$output" "SCRIPT Status:"
check "not initialized message" assert_contains "$output" "not initialized"
if cmp -s "$before" "$after"; then pass "$CURRENT_SCENARIO: no files written"; else fail "$CURRENT_SCENARIO: no files written"; fi
if [ ! -d "$SANDBOX/no-pipeline/.mindlayer/pipeline" ]; then pass "$CURRENT_SCENARIO: pipeline not created"; else fail "$CURRENT_SCENARIO: pipeline not created"; fi

scenario "status with empty pipeline reports no active work"
mkdir -p "$SANDBOX/empty-pipeline/.mindlayer/pipeline"
output="$SANDBOX/empty-pipeline.out"
if (cd "$SANDBOX/empty-pipeline" && python3 "$ROOT_DIR/src/ml" script status > "$output"); then
  pass "$CURRENT_SCENARIO: command exits 0"
else
  fail "$CURRENT_SCENARIO: command exits 0"
fi
check "no active work message" assert_contains "$output" "No active SCRIPT work."
check "signal count" assert_contains "$output" "Signals: 0"
check "story counts" assert_contains "$output" "Stories: 0 ready, 0 in-progress"

scenario "unknown script command fails cleanly"
mkdir -p "$SANDBOX/unknown/.mindlayer/pipeline" "$SANDBOX/unknown/.mindlayer/knowledge/sessions"
output="$SANDBOX/unknown.out"
if ! (cd "$SANDBOX/unknown" && python3 "$ROOT_DIR/src/ml" script nope > "$output" 2>&1); then
  pass "$CURRENT_SCENARIO: exits non-zero"
else
  fail "$CURRENT_SCENARIO: exits non-zero"
fi
check "argparse error" assert_contains "$output" "invalid choice"

scenario "existing status command still works"
mkdir -p "$SANDBOX/existing/.mindlayer/pipeline" "$SANDBOX/existing/.mindlayer/knowledge/sessions"
printf "# Project Memory Index\n" > "$SANDBOX/existing/.mindlayer/index.md"
output="$SANDBOX/existing.out"
if (cd "$SANDBOX/existing" && python3 "$ROOT_DIR/src/ml" status > "$output"); then
  pass "$CURRENT_SCENARIO: command exits 0"
else
  fail "$CURRENT_SCENARIO: command exits 0"
fi
check "existing status output" assert_contains "$output" "Per-File Health:"

# ---------------------------------------------------------------------------
# ml script signal
# ---------------------------------------------------------------------------

scenario "signal creates signals.md when missing"
mkdir -p "$SANDBOX/sig-create/.mindlayer/pipeline"
output="$SANDBOX/sig-create.out"
if (cd "$SANDBOX/sig-create" && python3 "$ROOT_DIR/src/ml" script signal \
    --title "Something is wrong" --body "Noticed a bug in the parser" > "$output"); then
  pass "$CURRENT_SCENARIO: exits 0"
else
  fail "$CURRENT_SCENARIO: exits 0"
fi
check "signals.md created" test -f "$SANDBOX/sig-create/.mindlayer/pipeline/signals.md"
check "id in output" assert_contains "$output" "ml-signal-"
check "approval line" assert_contains "$output" "Approval needed:"

scenario "signal help does not advertise auto routing"
mkdir -p "$SANDBOX/sig-help/.mindlayer/pipeline"
output="$SANDBOX/sig-help.out"
(cd "$SANDBOX/sig-help" && python3 "$ROOT_DIR/src/ml" script signal --help > "$output")
check_not "no tier option" assert_contains "$output" "--tier"
check_not "no auto routing" assert_contains "$output" "auto"

scenario "signal is pending human processing by default"
mkdir -p "$SANDBOX/sig-pending/.mindlayer/pipeline"
output="$SANDBOX/sig-pending.out"
(cd "$SANDBOX/sig-pending" && python3 "$ROOT_DIR/src/ml" script signal \
    --title "Small fix" --body "Typo in error message" > "$output")
check "pending processing in output" assert_contains "$output" "pending signal processing"
check "human review message" assert_contains "$output" "human review required before routing"
signals_file="$SANDBOX/sig-pending/.mindlayer/pipeline/signals.md"
check "status pending in file" assert_contains "$signals_file" "status: pending"
check_not "no auto tier in file" assert_contains "$signals_file" "tier: auto"

scenario "legacy tier field remains parseable"
mkdir -p "$SANDBOX/sig-legacy/.mindlayer/pipeline"
cat > "$SANDBOX/sig-legacy/.mindlayer/pipeline/signals.md" <<'EOF'
# Signals

## Legacy signal

id: ml-signal-20260516-001
created: 2026-05-16
tier: review
status: pending

Legacy body.
EOF
output="$SANDBOX/sig-legacy.out"
if (cd "$SANDBOX/sig-legacy" && python3 "$ROOT_DIR/src/ml" script cut \
    --signal ml-signal-20260516-001 --route backlog > "$output"); then
  pass "$CURRENT_SCENARIO: exits 0"
else
  fail "$CURRENT_SCENARIO: exits 0"
fi
check "legacy signal found" assert_contains "$output" "Legacy signal"

scenario "signal id increments on same day"
mkdir -p "$SANDBOX/sig-inc/.mindlayer/pipeline"
(cd "$SANDBOX/sig-inc" && python3 "$ROOT_DIR/src/ml" script signal --title "First" --body "body1" > /dev/null)
output2="$SANDBOX/sig-inc2.out"
(cd "$SANDBOX/sig-inc" && python3 "$ROOT_DIR/src/ml" script signal --title "Second" --body "body2" > "$output2")
signals_file="$SANDBOX/sig-inc/.mindlayer/pipeline/signals.md"
# Two signal id entries should exist
count=$(grep -c "^id: ml-signal-" "$signals_file" || true)
if [ "$count" -eq 2 ]; then pass "$CURRENT_SCENARIO: two signals in file"; else fail "$CURRENT_SCENARIO: two signals in file (got $count)"; fi
check "second id in output" assert_contains "$output2" "ml-signal-"

scenario "signal records title and body in file"
mkdir -p "$SANDBOX/sig-body/.mindlayer/pipeline"
(cd "$SANDBOX/sig-body" && python3 "$ROOT_DIR/src/ml" script signal \
    --title "Cache invalidation bug" --body "LRU eviction fires too early" > /dev/null)
signals_file="$SANDBOX/sig-body/.mindlayer/pipeline/signals.md"
check "title in file" assert_contains "$signals_file" "Cache invalidation bug"
check "body in file" assert_contains "$signals_file" "LRU eviction fires too early"
check "status pending in file" assert_contains "$signals_file" "status: pending"

# ---------------------------------------------------------------------------
# ml script cut
# ---------------------------------------------------------------------------

scenario "cut without --approve prints proposal only"
mkdir -p "$SANDBOX/cut-dry/.mindlayer/pipeline"
# Create a signal first
(cd "$SANDBOX/cut-dry" && python3 "$ROOT_DIR/src/ml" script signal \
    --title "A fix" --body "Some body" > /dev/null)
sig_id=$(grep "^id: ml-signal-" "$SANDBOX/cut-dry/.mindlayer/pipeline/signals.md" | head -1 | awk '{print $2}')
output="$SANDBOX/cut-dry.out"
before_backlog_size=$(wc -c < "$SANDBOX/cut-dry/.mindlayer/pipeline/backlog.md" 2>/dev/null || echo 0)
(cd "$SANDBOX/cut-dry" && python3 "$ROOT_DIR/src/ml" script cut \
    --signal "$sig_id" --route backlog > "$output")
check "approval needed message" assert_contains "$output" "Approval needed:"
check "pass --approve hint" assert_contains "$output" "--approve"
# backlog must not have changed
after_backlog_size=$(wc -c < "$SANDBOX/cut-dry/.mindlayer/pipeline/backlog.md" 2>/dev/null || echo 0)
if [ "$before_backlog_size" = "$after_backlog_size" ]; then
  pass "$CURRENT_SCENARIO: backlog unchanged"
else
  fail "$CURRENT_SCENARIO: backlog unchanged"
fi

scenario "cut --approve routes to backlog"
mkdir -p "$SANDBOX/cut-backlog/.mindlayer/pipeline"
(cd "$SANDBOX/cut-backlog" && python3 "$ROOT_DIR/src/ml" script signal \
    --title "Parser bug" --body "Edge case fails" > /dev/null)
sig_id=$(grep "^id: ml-signal-" "$SANDBOX/cut-backlog/.mindlayer/pipeline/signals.md" | head -1 | awk '{print $2}')
output="$SANDBOX/cut-backlog.out"
if (cd "$SANDBOX/cut-backlog" && python3 "$ROOT_DIR/src/ml" script cut \
    --signal "$sig_id" --route backlog --approve > "$output"); then
  pass "$CURRENT_SCENARIO: exits 0"
else
  fail "$CURRENT_SCENARIO: exits 0"
fi
check "cut approved in output" assert_contains "$output" "Cut approved"
check "backlog in output" assert_contains "$output" "backlog"
check "Approval needed None" assert_contains "$output" "Approval needed: None"
# signal status updated
check "signal marked cut-approved" assert_contains "$SANDBOX/cut-backlog/.mindlayer/pipeline/signals.md" "status: cut-approved"
# backlog has the title
check "title in backlog" assert_contains "$SANDBOX/cut-backlog/.mindlayer/pipeline/backlog.md" "Parser bug"

scenario "cut --approve routes to roadmap"
mkdir -p "$SANDBOX/cut-roadmap/.mindlayer/pipeline"
(cd "$SANDBOX/cut-roadmap" && python3 "$ROOT_DIR/src/ml" script signal \
    --title "V5 direction change" --body "Major pivot needed" > /dev/null)
sig_id=$(grep "^id: ml-signal-" "$SANDBOX/cut-roadmap/.mindlayer/pipeline/signals.md" | head -1 | awk '{print $2}')
output="$SANDBOX/cut-roadmap.out"
(cd "$SANDBOX/cut-roadmap" && python3 "$ROOT_DIR/src/ml" script cut \
    --signal "$sig_id" --route roadmap --approve > "$output")
check "roadmap in output" assert_contains "$output" "roadmap"
check "title in roadmap" assert_contains "$SANDBOX/cut-roadmap/.mindlayer/pipeline/roadmap.md" "V5 direction change"

scenario "cut with unknown signal id fails"
mkdir -p "$SANDBOX/cut-miss/.mindlayer/pipeline"
output="$SANDBOX/cut-miss.out"
if ! (cd "$SANDBOX/cut-miss" && python3 "$ROOT_DIR/src/ml" script cut \
    --signal "ml-signal-99991231-999" --route backlog --approve > "$output" 2>&1); then
  pass "$CURRENT_SCENARIO: exits non-zero"
else
  fail "$CURRENT_SCENARIO: exits non-zero"
fi
check "error message" assert_contains "$output" "not found"

# ---------------------------------------------------------------------------
# ml script refine
# ---------------------------------------------------------------------------

scenario "refine --approve creates story file and index row"
mkdir -p "$SANDBOX/refine-ok/.mindlayer/pipeline"
# Needs a backlog item id to reference as parent
output="$SANDBOX/refine-ok.out"
if (cd "$SANDBOX/refine-ok" && python3 "$ROOT_DIR/src/ml" script refine \
    --backlog-item "ml-backlog-001" \
    --story-title "Fix parser edge case" \
    --approve > "$output"); then
  pass "$CURRENT_SCENARIO: exits 0"
else
  fail "$CURRENT_SCENARIO: exits 0"
fi
story_dir="$SANDBOX/refine-ok/.mindlayer/pipeline/stories"
check "stories dir created" test -d "$story_dir"
story_count=$(find "$story_dir" -name "ml-story-*.md" | wc -l)
if [ "$story_count" -eq 1 ]; then pass "$CURRENT_SCENARIO: one story file"; else fail "$CURRENT_SCENARIO: one story file (got $story_count)"; fi
check "index created" test -f "$story_dir/index.md"
check "story title in output" assert_contains "$output" "Fix parser edge case"
check "story file path in output" assert_contains "$output" "ml-story-"
# story file has correct frontmatter
story_file=$(find "$story_dir" -name "ml-story-*.md" | head -1)
check "id in story" assert_contains "$story_file" "id: ml-story-"
check "parent in story" assert_contains "$story_file" "parent: ml-backlog-001"
check "status ready" assert_contains "$story_file" "status: ready"
# index row present
check "title in index" assert_contains "$story_dir/index.md" "Fix parser edge case"
check "ready in index" assert_contains "$story_dir/index.md" "ready"

scenario "refine uses next id after archived stories"
mkdir -p "$SANDBOX/refine-archive-aware/.mindlayer/pipeline/archive" \
         "$SANDBOX/refine-archive-aware/.mindlayer/pipeline/stories"
cat > "$SANDBOX/refine-archive-aware/.mindlayer/pipeline/stories/index.md" <<'EOF'
# Stories Index

| id | title | status | created | parent |
| -- | ----- | ------ | ------- | ------ |
EOF
for id in 001 002 003 004; do
  cat > "$SANDBOX/refine-archive-aware/.mindlayer/pipeline/archive/ml-story-$id.md" <<EOF
---
id: ml-story-$id
title: Archived story $id
status: done
created: 2026-05-14
parent: old-parent
agent: any
---

Archived body.
EOF
done
before_archived="$SANDBOX/refine-archive-aware.before"
after_archived="$SANDBOX/refine-archive-aware.after"
(cd "$SANDBOX/refine-archive-aware" && sha256sum .mindlayer/pipeline/archive/ml-story-*.md > "$before_archived")
output="$SANDBOX/refine-archive-aware.out"
if (cd "$SANDBOX/refine-archive-aware" && python3 "$ROOT_DIR/src/ml" script refine \
    --backlog-item "ml-backlog-archive-aware" \
    --story-title "Continue after archived stories" \
    --approve > "$output"); then
  pass "$CURRENT_SCENARIO: exits 0"
else
  fail "$CURRENT_SCENARIO: exits 0"
fi
(cd "$SANDBOX/refine-archive-aware" && sha256sum .mindlayer/pipeline/archive/ml-story-*.md > "$after_archived")
check "creates ml-story-005" test -f "$SANDBOX/refine-archive-aware/.mindlayer/pipeline/stories/ml-story-005.md"
check_not "does not recreate ml-story-001" test -f "$SANDBOX/refine-archive-aware/.mindlayer/pipeline/stories/ml-story-001.md"
check "output names ml-story-005" assert_contains "$output" "ml-story-005.md"
check "index names ml-story-005" assert_contains "$SANDBOX/refine-archive-aware/.mindlayer/pipeline/stories/index.md" "ml-story-005"
if cmp -s "$before_archived" "$after_archived"; then
  pass "$CURRENT_SCENARIO: archived stories unchanged"
else
  fail "$CURRENT_SCENARIO: archived stories unchanged"
fi

scenario "refine without --approve prints draft only"
mkdir -p "$SANDBOX/refine-dry/.mindlayer/pipeline"
output="$SANDBOX/refine-dry.out"
(cd "$SANDBOX/refine-dry" && python3 "$ROOT_DIR/src/ml" script refine \
    --backlog-item "ml-backlog-002" \
    --story-title "Add session pruning" > "$output")
check "approval hint in output" assert_contains "$output" "--approve"
check_not "no story dir created" test -d "$SANDBOX/refine-dry/.mindlayer/pipeline/stories"

scenario "refine --check passes on valid story"
mkdir -p "$SANDBOX/refine-check-ok/.mindlayer/pipeline/stories"
story_file="$SANDBOX/refine-check-ok/.mindlayer/pipeline/stories/ml-story-001.md"
cat > "$story_file" <<'EOF'
---
id: ml-story-001
title: Fix parser edge case
status: ready
created: 2026-05-14
parent: ml-backlog-001
agent: any
---

You are fixing the parser edge case in MindLayer.

Start by writing a failing test that reproduces the bug.
Then fix the implementation until the test passes.

Acceptance: all tests pass.
EOF
output="$SANDBOX/refine-check-ok.out"
if (cd "$SANDBOX/refine-check-ok" && python3 "$ROOT_DIR/src/ml" script refine \
    --check "$story_file" > "$output"); then
  pass "$CURRENT_SCENARIO: exits 0"
else
  fail "$CURRENT_SCENARIO: exits 0"
fi
check "valid message" assert_contains "$output" "Story valid"

scenario "refine --check fails on story missing parent"
mkdir -p "$SANDBOX/refine-check-bad/.mindlayer/pipeline/stories"
story_file="$SANDBOX/refine-check-bad/.mindlayer/pipeline/stories/ml-story-002.md"
cat > "$story_file" <<'EOF'
---
id: ml-story-002
title: Some story
status: ready
created: 2026-05-14
agent: any
---

Some body here.
EOF
output="$SANDBOX/refine-check-bad.out"
if ! (cd "$SANDBOX/refine-check-bad" && python3 "$ROOT_DIR/src/ml" script refine \
    --check "$story_file" > "$output" 2>&1); then
  pass "$CURRENT_SCENARIO: exits non-zero"
else
  fail "$CURRENT_SCENARIO: exits non-zero"
fi
check "missing parent in output" assert_contains "$output" "parent"

scenario "refine --check fails on story with empty body"
mkdir -p "$SANDBOX/refine-check-empty/.mindlayer/pipeline/stories"
story_file="$SANDBOX/refine-check-empty/.mindlayer/pipeline/stories/ml-story-003.md"
cat > "$story_file" <<'EOF'
---
id: ml-story-003
title: Empty body story
status: ready
created: 2026-05-14
parent: ml-backlog-003
agent: any
---
EOF
output="$SANDBOX/refine-check-empty.out"
if ! (cd "$SANDBOX/refine-check-empty" && python3 "$ROOT_DIR/src/ml" script refine \
    --check "$story_file" > "$output" 2>&1); then
  pass "$CURRENT_SCENARIO: exits non-zero"
else
  fail "$CURRENT_SCENARIO: exits non-zero"
fi
check "body error in output" assert_contains "$output" "body"

scenario "refine ids increment across stories"
mkdir -p "$SANDBOX/refine-inc/.mindlayer/pipeline"
(cd "$SANDBOX/refine-inc" && python3 "$ROOT_DIR/src/ml" script refine \
    --backlog-item "ml-backlog-001" --story-title "First story" --approve > /dev/null)
(cd "$SANDBOX/refine-inc" && python3 "$ROOT_DIR/src/ml" script refine \
    --backlog-item "ml-backlog-001" --story-title "Second story" --approve > /dev/null)
story_count=$(find "$SANDBOX/refine-inc/.mindlayer/pipeline/stories" -name "ml-story-*.md" | wc -l)
if [ "$story_count" -eq 2 ]; then pass "$CURRENT_SCENARIO: two story files"; else fail "$CURRENT_SCENARIO: two story files (got $story_count)"; fi
index_rows=$(grep -c "ml-story-" "$SANDBOX/refine-inc/.mindlayer/pipeline/stories/index.md" || true)
if [ "$index_rows" -eq 2 ]; then pass "$CURRENT_SCENARIO: two index rows"; else fail "$CURRENT_SCENARIO: two index rows (got $index_rows)"; fi

# ---------------------------------------------------------------------------
# ml script story --start / --done
# ---------------------------------------------------------------------------

scenario "story --start flips status to in-progress"
mkdir -p "$SANDBOX/story-start/.mindlayer/pipeline/stories"
story_file="$SANDBOX/story-start/.mindlayer/pipeline/stories/ml-story-001.md"
index_file="$SANDBOX/story-start/.mindlayer/pipeline/stories/index.md"
cat > "$story_file" <<'EOF'
---
id: ml-story-001
title: Start me
status: ready
created: 2026-05-14
parent: ml-backlog-001
agent: any
---

Do the thing.
EOF
printf "| ml-story-001 | Start me | ready | 2026-05-14 | ml-backlog-001 |\n" > "$index_file"
output="$SANDBOX/story-start.out"
if (cd "$SANDBOX/story-start" && python3 "$ROOT_DIR/src/ml" script story \
    --start ml-story-001 > "$output"); then
  pass "$CURRENT_SCENARIO: exits 0"
else
  fail "$CURRENT_SCENARIO: exits 0"
fi
check "transition in output" assert_contains "$output" "in-progress"
check "story id in output" assert_contains "$output" "ml-story-001"
check "Approval needed None" assert_contains "$output" "Approval needed: None"
check "status in-progress in file" assert_contains "$story_file" "status: in-progress"
check "started_from in file" assert_contains "$story_file" "started_from:"
check "in-progress in index" assert_contains "$index_file" "in-progress"

scenario "story --done flips status to done"
mkdir -p "$SANDBOX/story-done/.mindlayer/pipeline/stories"
story_file="$SANDBOX/story-done/.mindlayer/pipeline/stories/ml-story-001.md"
index_file="$SANDBOX/story-done/.mindlayer/pipeline/stories/index.md"
cat > "$story_file" <<'EOF'
---
id: ml-story-001
title: Finish me
status: in-progress
created: 2026-05-14
parent: ml-backlog-001
agent: any
started_from: abc1234
---

Do the thing.
EOF
printf "| ml-story-001 | Finish me | in-progress | 2026-05-14 | ml-backlog-001 |\n" > "$index_file"
output="$SANDBOX/story-done.out"
if (cd "$SANDBOX/story-done" && python3 "$ROOT_DIR/src/ml" script story \
    --done ml-story-001 > "$output"); then
  pass "$CURRENT_SCENARIO: exits 0"
else
  fail "$CURRENT_SCENARIO: exits 0"
fi
check "done in output" assert_contains "$output" "done"
check "status done in file" assert_contains "$story_file" "status: done"
check "done in index" assert_contains "$index_file" "done"

scenario "story --done with passing test-cmd records proved_by"
mkdir -p "$SANDBOX/story-prove-ok/.mindlayer/pipeline/stories"
story_file="$SANDBOX/story-prove-ok/.mindlayer/pipeline/stories/ml-story-001.md"
index_file="$SANDBOX/story-prove-ok/.mindlayer/pipeline/stories/index.md"
cat > "$story_file" <<'EOF'
---
id: ml-story-001
title: Prove me
status: in-progress
created: 2026-05-14
parent: ml-backlog-001
agent: any
started_from: abc1234
---

Do the thing.
EOF
printf "| ml-story-001 | Prove me | in-progress | 2026-05-14 | ml-backlog-001 |\n" > "$index_file"
output="$SANDBOX/story-prove-ok.out"
if (cd "$SANDBOX/story-prove-ok" && python3 "$ROOT_DIR/src/ml" script story \
    --done ml-story-001 --test-cmd "true" > "$output"); then
  pass "$CURRENT_SCENARIO: exits 0"
else
  fail "$CURRENT_SCENARIO: exits 0"
fi
check "proved_by in file" assert_contains "$story_file" "proved_by:"
check "proved_at in file" assert_contains "$story_file" "proved_at:"
check "status done in file" assert_contains "$story_file" "status: done"

scenario "story --done with failing test-cmd blocks transition"
mkdir -p "$SANDBOX/story-prove-fail/.mindlayer/pipeline/stories"
story_file="$SANDBOX/story-prove-fail/.mindlayer/pipeline/stories/ml-story-001.md"
cat > "$story_file" <<'EOF'
---
id: ml-story-001
title: Block me
status: in-progress
created: 2026-05-14
parent: ml-backlog-001
agent: any
started_from: abc1234
---

Do the thing.
EOF
output="$SANDBOX/story-prove-fail.out"
if ! (cd "$SANDBOX/story-prove-fail" && python3 "$ROOT_DIR/src/ml" script story \
    --done ml-story-001 --test-cmd "false" > "$output" 2>&1); then
  pass "$CURRENT_SCENARIO: exits non-zero"
else
  fail "$CURRENT_SCENARIO: exits non-zero"
fi
check "test failed error" assert_contains "$output" "Tests failed"
check "status still in-progress" assert_contains "$story_file" "status: in-progress"

scenario "story --done without test-cmd warns but succeeds"
mkdir -p "$SANDBOX/story-prove-warn/.mindlayer/pipeline/stories"
story_file="$SANDBOX/story-prove-warn/.mindlayer/pipeline/stories/ml-story-001.md"
index_file="$SANDBOX/story-prove-warn/.mindlayer/pipeline/stories/index.md"
cat > "$story_file" <<'EOF'
---
id: ml-story-001
title: Warn me
status: in-progress
created: 2026-05-14
parent: ml-backlog-001
agent: any
started_from: abc1234
---

Do the thing.
EOF
printf "| ml-story-001 | Warn me | in-progress | 2026-05-14 | ml-backlog-001 |\n" > "$index_file"
output="$SANDBOX/story-prove-warn.out"
if (cd "$SANDBOX/story-prove-warn" && python3 "$ROOT_DIR/src/ml" script story \
    --done ml-story-001 > "$output"); then
  pass "$CURRENT_SCENARIO: exits 0"
else
  fail "$CURRENT_SCENARIO: exits 0"
fi
check "no test-cmd warning" assert_contains "$output" "no --test-cmd"
check "status done in file" assert_contains "$story_file" "status: done"

scenario "story --start on non-existent id fails"
mkdir -p "$SANDBOX/story-miss/.mindlayer/pipeline/stories"
output="$SANDBOX/story-miss.out"
if ! (cd "$SANDBOX/story-miss" && python3 "$ROOT_DIR/src/ml" script story \
    --start ml-story-999 > "$output" 2>&1); then
  pass "$CURRENT_SCENARIO: exits non-zero"
else
  fail "$CURRENT_SCENARIO: exits non-zero"
fi
check "not found error" assert_contains "$output" "not found"

# ---------------------------------------------------------------------------
# ml script transfer
# ---------------------------------------------------------------------------

_make_story() {
  local dir="$1" id="$2" parent="$3" status="$4"
  mkdir -p "$dir"
  cat > "$dir/${id}.md" <<EOF
---
id: $id
title: Story for $id
status: $status
created: 2026-05-14
parent: $parent
agent: any
---

Do the thing.
EOF
}

_make_index() {
  local index="$1"; shift
  printf "# Stories Index\n\n| id | title | status | created | parent |\n| -- | ----- | ------ | ------- | ------ |\n" > "$index"
  for row in "$@"; do
    printf "%s\n" "$row" >> "$index"
  done
}

scenario "transfer archives all done stories for a backlog item"
mkdir -p "$SANDBOX/transfer-ok/.mindlayer/pipeline/stories"
mkdir -p "$SANDBOX/transfer-ok/.mindlayer/pipeline/archive"
_make_story "$SANDBOX/transfer-ok/.mindlayer/pipeline/stories" ml-story-001 ml-backlog-001 done
_make_story "$SANDBOX/transfer-ok/.mindlayer/pipeline/stories" ml-story-002 ml-backlog-001 done
_make_index "$SANDBOX/transfer-ok/.mindlayer/pipeline/stories/index.md" \
  "| ml-story-001 | Story for ml-story-001 | done | 2026-05-14 | ml-backlog-001 |" \
  "| ml-story-002 | Story for ml-story-002 | done | 2026-05-14 | ml-backlog-001 |"
output="$SANDBOX/transfer-ok.out"
if (cd "$SANDBOX/transfer-ok" && python3 "$ROOT_DIR/src/ml" script transfer \
    --backlog-item ml-backlog-001 --approve > "$output"); then
  pass "$CURRENT_SCENARIO: exits 0"
else
  fail "$CURRENT_SCENARIO: exits 0"
fi
check "archived in output" assert_contains "$output" "archived"
check "backlog item in output" assert_contains "$output" "ml-backlog-001"
check "Approval needed None" assert_contains "$output" "Approval needed: None"
# story files moved to archive
check "story-001 archived" test -f "$SANDBOX/transfer-ok/.mindlayer/pipeline/archive/ml-story-001.md"
check "story-002 archived" test -f "$SANDBOX/transfer-ok/.mindlayer/pipeline/archive/ml-story-002.md"
# story files removed from stories/
check_not "story-001 removed from stories" test -f "$SANDBOX/transfer-ok/.mindlayer/pipeline/stories/ml-story-001.md"
check_not "story-002 removed from stories" test -f "$SANDBOX/transfer-ok/.mindlayer/pipeline/stories/ml-story-002.md"
# index rows removed
check_not "index row removed" assert_contains "$SANDBOX/transfer-ok/.mindlayer/pipeline/stories/index.md" "ml-story-001"

scenario "transfer without --approve prints proposal only"
mkdir -p "$SANDBOX/transfer-dry/.mindlayer/pipeline/stories"
_make_story "$SANDBOX/transfer-dry/.mindlayer/pipeline/stories" ml-story-001 ml-backlog-001 done
_make_index "$SANDBOX/transfer-dry/.mindlayer/pipeline/stories/index.md" \
  "| ml-story-001 | Story for ml-story-001 | done | 2026-05-14 | ml-backlog-001 |"
output="$SANDBOX/transfer-dry.out"
(cd "$SANDBOX/transfer-dry" && python3 "$ROOT_DIR/src/ml" script transfer \
    --backlog-item ml-backlog-001 > "$output")
check "approval hint in output" assert_contains "$output" "--approve"
check_not "story not yet archived" test -f "$SANDBOX/transfer-dry/.mindlayer/pipeline/archive/ml-story-001.md"

scenario "transfer fails if any story is not done"
mkdir -p "$SANDBOX/transfer-notdone/.mindlayer/pipeline/stories"
_make_story "$SANDBOX/transfer-notdone/.mindlayer/pipeline/stories" ml-story-001 ml-backlog-001 done
_make_story "$SANDBOX/transfer-notdone/.mindlayer/pipeline/stories" ml-story-002 ml-backlog-001 in-progress
_make_index "$SANDBOX/transfer-notdone/.mindlayer/pipeline/stories/index.md" \
  "| ml-story-001 | Story for ml-story-001 | done | 2026-05-14 | ml-backlog-001 |" \
  "| ml-story-002 | Story for ml-story-002 | in-progress | 2026-05-14 | ml-backlog-001 |"
output="$SANDBOX/transfer-notdone.out"
if ! (cd "$SANDBOX/transfer-notdone" && python3 "$ROOT_DIR/src/ml" script transfer \
    --backlog-item ml-backlog-001 --approve > "$output" 2>&1); then
  pass "$CURRENT_SCENARIO: exits non-zero"
else
  fail "$CURRENT_SCENARIO: exits non-zero"
fi
check "not done error" assert_contains "$output" "not done"

scenario "transfer --learn proposes knowledge write without --approve-learn"
mkdir -p "$SANDBOX/transfer-learn/.mindlayer/pipeline/stories"
_make_story "$SANDBOX/transfer-learn/.mindlayer/pipeline/stories" ml-story-001 ml-backlog-001 done
_make_index "$SANDBOX/transfer-learn/.mindlayer/pipeline/stories/index.md" \
  "| ml-story-001 | Story for ml-story-001 | done | 2026-05-14 | ml-backlog-001 |"
output="$SANDBOX/transfer-learn.out"
(cd "$SANDBOX/transfer-learn" && python3 "$ROOT_DIR/src/ml" script transfer \
    --backlog-item ml-backlog-001 \
    --learn "Parser must handle empty input" \
    --learn-target decisions \
    > "$output")
check "learning proposal in output" assert_contains "$output" "Parser must handle empty input"
check "approve-learn hint in output" assert_contains "$output" "--approve-learn"
check_not "knowledge not written yet" test -f "$SANDBOX/transfer-learn/.mindlayer/knowledge/decisions.md"

scenario "transfer --learn --approve-learn writes to knowledge and then archives"
mkdir -p "$SANDBOX/transfer-learn-ok/.mindlayer/pipeline/stories"
_make_story "$SANDBOX/transfer-learn-ok/.mindlayer/pipeline/stories" ml-story-001 ml-backlog-001 done
_make_index "$SANDBOX/transfer-learn-ok/.mindlayer/pipeline/stories/index.md" \
  "| ml-story-001 | Story for ml-story-001 | done | 2026-05-14 | ml-backlog-001 |"
output="$SANDBOX/transfer-learn-ok.out"
if (cd "$SANDBOX/transfer-learn-ok" && python3 "$ROOT_DIR/src/ml" script transfer \
    --backlog-item ml-backlog-001 \
    --learn "Use Path.read_text not open for utf-8" \
    --learn-target decisions \
    --approve --approve-learn > "$output"); then
  pass "$CURRENT_SCENARIO: exits 0"
else
  fail "$CURRENT_SCENARIO: exits 0"
fi
check "learning written" assert_contains "$SANDBOX/transfer-learn-ok/.mindlayer/knowledge/decisions.md" "Use Path.read_text not open for utf-8"
check "stories archived" test -f "$SANDBOX/transfer-learn-ok/.mindlayer/pipeline/archive/ml-story-001.md"
check "Approval needed None" assert_contains "$output" "Approval needed: None"

scenario "transfer --learn-target project writes to project.md"
mkdir -p "$SANDBOX/transfer-proj/.mindlayer/pipeline/stories"
_make_story "$SANDBOX/transfer-proj/.mindlayer/pipeline/stories" ml-story-001 ml-backlog-001 done
_make_index "$SANDBOX/transfer-proj/.mindlayer/pipeline/stories/index.md" \
  "| ml-story-001 | Story for ml-story-001 | done | 2026-05-14 | ml-backlog-001 |"
(cd "$SANDBOX/transfer-proj" && python3 "$ROOT_DIR/src/ml" script transfer \
    --backlog-item ml-backlog-001 \
    --learn "Project now uses pipeline/ not learnings/" \
    --learn-target project \
    --approve --approve-learn > /dev/null)
check "learning in project.md" assert_contains "$SANDBOX/transfer-proj/.mindlayer/knowledge/project.md" "Project now uses pipeline/"

printf "\nSummary: %s passed, %s failed\n" "$PASS_COUNT" "$FAIL_COUNT"
[ "$FAIL_COUNT" -eq 0 ]
