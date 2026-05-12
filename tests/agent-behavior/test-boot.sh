#!/usr/bin/env bash
# Deterministic contract tests for MindLayer boot behavior.
#
# This does not call a live model. It validates the response shape that adapters
# require agents to produce after automatic MindLayer boot.

set -u

PASS_COUNT=0
FAIL_COUNT=0
CURRENT_SCENARIO=""

pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  printf "PASS  %s\n" "$1"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  printf "FAIL  %s\n" "$1"
}

scenario() {
  CURRENT_SCENARIO="$1"
  printf "\n## %s\n" "$CURRENT_SCENARIO"
}

assert_valid_receipt() {
  file="$1"
  [ -f "$file" ] || return 1

  grep -Fq "MindLayer context loaded." "$file" || return 1
  grep -Fq "Loaded:" "$file" || return 1
  grep -Fq "Skipped:" "$file" || return 1
  grep -Fq "Missing:" "$file" || return 1
  grep -Fq "Current understanding:" "$file" || return 1
  grep -Fq "Current progress:" "$file" || return 1
  grep -Fq "Context cost:" "$file" || return 1
  grep -Fq "Context share:" "$file" || return 1
  grep -Fq "Token strategy:" "$file" || return 1
  grep -Fq "Ready." "$file" || return 1
  grep -Fq ".mindlayer/index.md" "$file" || return 1
  ! grep -Fq ".mindlayer/index-full.md" "$file" || return 1

  awk '
    /^Loaded:/ { in_loaded = 1; next }
    /^[[:alpha:]][[:alpha:] ]*:/ { in_loaded = 0 }
    in_loaded && /~\/\.mindlayer\/(boot\.md|router\.md|memory-system\/)/ { found = 1 }
    END { exit found ? 0 : 1 }
  ' "$file" || return 1

  grep -Fq 'README.md`, `docs/`, and tool adapters as memory sources' "$file" || return 1
  grep -Eq 'Approx\. [0-9][0-9,]*-[0-9][0-9,]* words loaded( \(~[0-9][0-9,]*-[0-9][0-9,]* est\. tokens\))?|Approx\. [0-9][0-9,]* words loaded( \(~[0-9][0-9,]* est\. tokens\))?' "$file" || return 1
  grep -Eq 'Global memory: ~[0-9]+%|Global memory: approx\. [0-9]+%' "$file" || return 1
  grep -Eq 'Project memory: ~[0-9]+%|Project memory: approx\. [0-9]+%' "$file" || return 1

  if awk '
    /^Loaded:/ { in_loaded = 1; next }
    /^[[:alpha:]][[:alpha:] ]*:/ { in_loaded = 0 }
    in_loaded && /(README\.md|docs\/|AGENTS\.md|CLAUDE\.md|copilot-instructions\.md)/ { bad = 1 }
    END { exit bad ? 0 : 1 }
  ' "$file"; then
    return 1
  fi
}

assert_index_full_exists() {
  [ -f ".mindlayer/index-full.md" ] &&
    grep -Fq "## Entries" ".mindlayer/index-full.md" &&
    grep -Fq "  title:" ".mindlayer/index-full.md"
}

assert_boot_index_summary_only() {
  [ -f ".mindlayer/index.md" ] || return 1
  grep -Fq "# Project Memory Index" ".mindlayer/index.md" || return 1
  grep -Fq "Full metadata: \`index-full.md\` via \`ml load\`." ".mindlayer/index.md" || return 1
  ! grep -Fq "  title:" ".mindlayer/index.md" || return 1
  ! grep -Fq "  tags:" ".mindlayer/index.md" || return 1
}

assert_boot_index_has_active_entry_count() {
  active_count=$(awk '
    /^- id:/ { status = "" }
    /^  status:/ { status = $2 }
    /^  last_updated:/ { if (status == "active") count++ }
    END { print count + 0 }
  ' ".mindlayer/index-full.md")
  summary_count=$(grep -Ec "^- .+ \\| .+ \\| .+\\.md \\| .+" ".mindlayer/index.md" || true)
  [ "$active_count" -eq "$summary_count" ]
}

assert_boot_router_avoids_index_full() {
  grep -Fq 'Read project `.mindlayer/index.md` — summary-only boot catalog.' "global-template/boot.md" &&
    grep -Fq 'Do not load `.mindlayer/index-full.md` at boot' "global-template/boot.md"
}

assert_load_router_mentions_index_full() {
  grep -Fq 'project `.mindlayer/index-full.md`' "global-template/router.md" &&
    grep -Fq 'Memory load' "global-template/router.md"
}

assert_invalid_receipt() {
  file="$1"
  if assert_valid_receipt "$file"; then
    return 1
  fi
}

check_valid() {
  file="$1"
  if assert_valid_receipt "$file"; then
    pass "$CURRENT_SCENARIO: valid receipt accepted"
  else
    fail "$CURRENT_SCENARIO: valid receipt accepted"
  fi
}

check_invalid() {
  file="$1"
  label="$2"
  if assert_invalid_receipt "$file"; then
    pass "$CURRENT_SCENARIO: invalid receipt rejected ($label)"
  else
    fail "$CURRENT_SCENARIO: invalid receipt rejected ($label)"
  fi
}

SANDBOX="${TMPDIR:-/tmp}/mindlayer-agent-behavior-test.$$"
cleanup() {
  rm -rf "$SANDBOX"
}
trap cleanup EXIT
mkdir -p "$SANDBOX"

printf "MindLayer Agent Behavior Contract\n"
printf "=================================\n"

scenario "boot index split"
if assert_index_full_exists 2>/dev/null; then
  pass "$CURRENT_SCENARIO: index-full.md exists with full entries"
else
  fail "$CURRENT_SCENARIO: index-full.md exists with full entries"
fi

if assert_boot_index_summary_only 2>/dev/null; then
  pass "$CURRENT_SCENARIO: boot index is summary-only"
else
  fail "$CURRENT_SCENARIO: boot index is summary-only"
fi

if assert_boot_index_has_active_entry_count 2>/dev/null; then
  pass "$CURRENT_SCENARIO: boot index has one line per active entry"
else
  fail "$CURRENT_SCENARIO: boot index has one line per active entry"
fi

if assert_boot_router_avoids_index_full 2>/dev/null; then
  pass "$CURRENT_SCENARIO: boot loads index.md not index-full.md"
else
  fail "$CURRENT_SCENARIO: boot loads index.md not index-full.md"
fi

if assert_load_router_mentions_index_full 2>/dev/null; then
  pass "$CURRENT_SCENARIO: ml load trigger mentions index-full.md"
else
  fail "$CURRENT_SCENARIO: ml load trigger mentions index-full.md"
fi

scenario "substantive project receipt"
substantive="$SANDBOX/substantive-receipt.md"
cat > "$substantive" <<'EOF'
MindLayer context loaded.

Loaded:
- Global: `~/.mindlayer/boot.md`, `~/.mindlayer/router.md`, `~/.mindlayer/memory-system/per-turn.md`, `~/.mindlayer/preferences/personal.md`, `~/.mindlayer/index.md`
- Project: `.mindlayer/index.md`, `.mindlayer/project.md`, latest `.mindlayer/progress.md`

Skipped:
- `README.md`, `docs/`, and tool adapters as memory sources
- Empty scaffold files and `.mindlayer/local.md`
- Conditional memory-system/ subfiles not needed for startup

Missing:
- None

Current understanding:
MindLayer is a markdown-first memory system for AI-native software developers. Durable memory lives in global and project `.mindlayer/` files; adapters stay thin.

Current progress:
Installer-first V1 is published. Recent work clarified deploy readiness, source boundaries, literal approval for writes, and transparent initialization receipts.

Context cost:
Approx. 900-1,400 words loaded (~1,200-1,900 est. tokens).

Context share:
- Global memory: ~45%
- Project memory: ~55%
- Other sources: 0% (README.md, docs/, and adapters skipped)

Token strategy:
L0 boot only: boot.md, router.md, per-turn.md, indexes, project identity, and latest progress.

Ready.
What would you like to work on?
EOF
check_valid "$substantive"

scenario "starter project receipt"
starter="$SANDBOX/starter-receipt.md"
cat > "$starter" <<'EOF'
MindLayer context loaded.

Loaded:
- Global: `~/.mindlayer/boot.md`, `~/.mindlayer/router.md`, `~/.mindlayer/memory-system/per-turn.md`, `~/.mindlayer/index.md`
- Project: `.mindlayer/index.md`

Skipped:
- `~/.mindlayer/preferences/personal.md` because it is starter-only
- Starter-only project memory files
- `.mindlayer/local.md`
- `README.md`, `docs/`, and tool adapters as memory sources

Missing:
- Substantive project identity is not saved yet

Current understanding:
This project has MindLayer installed, but no durable project memory has been added yet.

Current progress:
No substantive project progress has been saved yet.

Context cost:
Approx. 300-600 words loaded (~400-800 est. tokens).

Context share:
- Global memory: ~70%
- Project memory: ~30%
- Other sources: 0% (README.md, docs/, and adapters skipped)

Token strategy:
L0 boot only: command rules, indexes, and starter/scaffold checks.

Ready.
What would you like to work on?
EOF
check_valid "$starter"

scenario "receipt rejection cases"
missing_boot_files="$SANDBOX/missing-boot-files.md"
cat > "$missing_boot_files" <<'EOF'
MindLayer context loaded.

Loaded:
- Global preferences and indexes
- Project memory index

Skipped:
- `README.md`, `docs/`, and tool adapters as memory sources

Missing:
- None

Current understanding:
Project memory is available.

Current progress:
No progress loaded.

Context cost:
Approx. 400-500 words loaded.

Context share:
- Global memory: ~50%
- Project memory: ~50%
- Other sources: 0% (README.md, docs/, and adapters skipped)

Token strategy:
L0 boot only.

Ready.
EOF
check_invalid "$missing_boot_files" "missing boot/router/per-turn from loaded list"

missing_cost="$SANDBOX/missing-cost.md"
cat > "$missing_cost" <<'EOF'
MindLayer context loaded.

Loaded:
- Global: `~/.mindlayer/boot.md`, `~/.mindlayer/router.md`, `~/.mindlayer/memory-system/per-turn.md`, command rules

Skipped:
- `README.md`, `docs/`, and tool adapters as memory sources

Missing:
- None

Current understanding:
Project memory is available.

Current progress:
No progress loaded.

Ready.
EOF
check_invalid "$missing_cost" "missing context cost"

missing_context_share="$SANDBOX/missing-context-share.md"
cat > "$missing_context_share" <<'EOF'
MindLayer context loaded.

Loaded:
- Global: `~/.mindlayer/boot.md`, `~/.mindlayer/router.md`, `~/.mindlayer/memory-system/per-turn.md`, command rules

Skipped:
- `README.md`, `docs/`, and tool adapters as memory sources

Missing:
- None

Current understanding:
Project memory is available.

Current progress:
No progress loaded.

Context cost:
Approx. 400-500 words loaded.

Token strategy:
L0 boot only.

Ready.
EOF
check_invalid "$missing_context_share" "missing context share"

loaded_docs="$SANDBOX/loaded-docs.md"
cat > "$loaded_docs" <<'EOF'
MindLayer context loaded.

Loaded:
- Global: `~/.mindlayer/boot.md`, `~/.mindlayer/router.md`, `~/.mindlayer/memory-system/per-turn.md`, command rules
- README.md and docs/

Skipped:
- `README.md`, `docs/`, and tool adapters as memory sources

Missing:
- None

Current understanding:
Project memory is available.

Current progress:
No progress loaded.

Context cost:
Approx. 400-500 words loaded.

Context share:
- Global memory: ~50%
- Project memory: ~50%
- Other sources: 0% (README.md, docs/, and adapters skipped)

Token strategy:
L0 boot only.

Ready.
EOF
check_invalid "$loaded_docs" "human docs loaded"

missing_skip="$SANDBOX/missing-skip.md"
cat > "$missing_skip" <<'EOF'
MindLayer context loaded.

Loaded:
- Global: `~/.mindlayer/boot.md`, `~/.mindlayer/router.md`, `~/.mindlayer/memory-system/per-turn.md`, command rules

Missing:
- None

Current understanding:
Project memory is available.

Current progress:
No progress loaded.

Context cost:
Approx. 400-500 words loaded.

Context share:
- Global memory: ~50%
- Project memory: ~50%
- Other sources: 0% (README.md, docs/, and adapters skipped)

Token strategy:
L0 boot only.

Ready.
EOF
check_invalid "$missing_skip" "missing skipped section"

printf "\nMindLayer Agent Behavior Summary\n"
printf "Passed checks: %s\n" "$PASS_COUNT"
printf "Failed checks: %s\n" "$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  printf "Verdict: BOOT CONTRACT READY\n"
  exit 0
fi

printf "Verdict: BOOT CONTRACT FAILED\n"
exit 1
